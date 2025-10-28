# Stage 2: Terraform + Ansible Integration on GCP

## Overview
Advanced DevOps implementation demonstrating Infrastructure as Code with Terraform provisioning real Google Cloud Platform infrastructure, followed by Ansible configuration management and application deployment.

## Table of Contents
- [What's Different from Stage 1](#whats-different-from-stage-1)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Cleanup](#cleanup)

## What's Different from Stage 1?

| Aspect | Stage 1 | Stage 2 |
|--------|---------|---------|
| **Infrastructure** | Vagrant (VirtualBox) | Terraform (GCP Compute Engine) |
| **Provisioning** | `vagrant up` | `terraform` via Ansible |
| **Inventory** | Static (Vagrantfile) | Dynamic (from Terraform outputs) |
| **SSH Keys** | Vagrant-managed | Explicitly generated and managed |
| **Network** | Private (192.168.x.x) | Public IP (cloud accessible) |
| **Environment** | Local development | Production cloud deployment |
| **Cost** | Free (local resources) | ~$0.03/hour (GCP e2-medium) |
| **Scalability** | Single local VM | Cloud-native, scalable infrastructure |
| **Teardown** | `vagrant destroy` | `terraform destroy` |

## Architecture

### Infrastructure Components
```
┌─────────────────────────────────────────────────┐
│           Google Cloud Platform                 │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │    GCP Compute Engine Instance           │  │
│  │    - Ubuntu 22.04 LTS                    │  │
│  │    - e2-medium (2 vCPU, 4GB RAM)        │  │
│  │    - External IP: Public                 │  │
│  │                                          │  │
│  │    ┌──────────────────────────────┐     │  │
│  │    │   Docker Containers          │     │  │
│  │    │   - Frontend (React) :3000   │     │  │
│  │    │   - Backend (Node.js) :5000  │     │  │
│  │    │   - MongoDB :27017           │     │  │
│  │    └──────────────────────────────┘     │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │    Firewall Rules                        │  │
│  │    - Allow TCP: 22, 3000, 5000, 27017   │  │
│  │    - Source: 0.0.0.0/0                   │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

Local Machine
├── Terraform (Infrastructure provisioning)
├── Ansible (Configuration management)
└── SSH (Secure access)
```

### Deployment Workflow
```
1. Terraform Provisioning
   ├── Creates GCP Compute Engine VM
   ├── Configures firewall rules
   ├── Adds SSH public key
   └── Outputs instance details

2. Dynamic Inventory Creation
   ├── Ansible reads Terraform outputs
   └── Creates dynamic host entry

3. SSH Key Management
   ├── Checks for existing keys
   └── Generates if needed

4. System Configuration (Ansible)
   ├── Updates packages
   ├── Installs Docker & Docker Compose
   ├── Configures system settings
   └── Sets up application user

5. Application Deployment
   ├── Clones git repository
   ├── Builds Docker images
   ├── Starts containers with Docker Compose
   └── Configures environment variables

6. Health Verification
   ├── Checks backend API health
   ├── Verifies frontend accessibility
   └── Reports deployment status
```

## Prerequisites

### Required Accounts & Tools
- **GCP Account** with billing enabled
- **gcloud CLI** installed and configured
- **Ansible** 2.9+ with `community.docker` collection
- **Git** for version control
- **SSH** client

### System Requirements
- Linux/MacOS (WSL2 for Windows)
- 2GB free disk space
- Internet connection

### Required Ansible Collections
```bash
ansible-galaxy collection install community.docker
```

## Setup Instructions

### 1. GCP Authentication

```bash
# Install gcloud CLI (if not installed)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate with GCP
gcloud auth application-default login

# Set your project ID
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com

# Verify authentication
gcloud auth application-default print-access-token
```

### 2. Project Configuration

```bash
# Clone the repository
cd ~/Documents
git clone https://github.com/your-repo/yolo.git
cd yolo/stage_two

# Review and update group_vars/all.yml
cat group_vars/all.yml
```

### 3. SSH Key Setup

The playbook automatically generates SSH keys if they don't exist at `~/.ssh/yolo_gcp_key`. To use existing keys, update `group_vars/all.yml`:

```yaml
ssh_private_key_path: "~/.ssh/yolo_gcp_key"
ssh_public_key_path: "~/.ssh/yolo_gcp_key.pub"
```

### 4. Inventory Configuration

Use the minimal inventory (dynamic inventory is created by playbook):

```yaml
# inventory.yml
all:
  children:
    provisioned_servers:
      hosts: {}
```

## Deployment

### Single Command Deployment

```bash
cd ~/Documents/yolo/stage_two

# Ensure GCP_PROJECT_ID is set
export GCP_PROJECT_ID="your-project-id"

# Run the complete deployment
ansible-playbook -i inventory.yml playbooks/site.yml
```

### Deployment Phases

The playbook executes two main phases:

#### Phase 1: Infrastructure Provisioning (localhost)
- Validates GCP project ID
- Generates SSH keys if needed
- Runs Terraform to provision GCP infrastructure
- Creates dynamic inventory from Terraform outputs
- Waits for instance to be SSH-ready

#### Phase 2: Configuration & Deployment (provisioned_servers)
- Updates system packages
- Installs Docker and Docker Compose
- Clones application repository
- Builds and starts Docker containers
- Verifies application health

### Expected Output

```
PLAY RECAP *************************************************************
localhost          : ok=17   changed=6    failed=0
gcp-server         : ok=26   changed=12   failed=0

==========================================
🎉 Stage 2 Deployment Complete!
==========================================
Infrastructure: Provisioned on Google Cloud Platform
Configuration: Applied with Ansible
Application: Deployed and Running

Access your cloud application:
Frontend: http://YOUR_IP:3000
Backend:  http://YOUR_IP:5000/api
Health:   http://YOUR_IP:5000/api/health
Status:   UP ✅
```

## Troubleshooting

### Common Issues

#### 1. GCP Authentication Error
**Error:** `No credentials loaded. To use your gcloud credentials, run 'gcloud auth application-default login'`

**Solution:**
```bash
gcloud auth application-default login
export GCP_PROJECT_ID="your-project-id"
```

#### 2. APT Lock Error
**Error:** `Failed to lock apt for exclusive operation`

**Cause:** Fresh GCP instances run automatic updates in background

**Solution:** The playbook now includes retry logic. If you still encounter this:
```bash
# SSH into instance and wait
ssh -i ~/.ssh/yolo_gcp_key ubuntu@YOUR_IP
sudo fuser -v /var/lib/apt/lists/lock
# Wait for process to finish, then re-run playbook
```

#### 3. Docker Module Error
**Error:** `Not supported URL scheme http+docker`

**Solution:** This is handled in the updated mongo role with proper docker_host configuration.

#### 4. SSH Connection Timeout
**Error:** `Connection timed out`

**Causes & Solutions:**
- **Firewall not created:** Check `gcloud compute firewall-rules list`
- **Wrong SSH key:** Verify key path in `group_vars/all.yml`
- **Instance not ready:** Wait 30-60 seconds after Terraform completes

#### 5. Image Not Found Error
**Error:** `Could not find image or family ubuntu-os-cloud/ubuntu-2004-lts`

**Solution:** Update the Terraform template with correct image path:
```hcl
image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
```

### Verification Commands

```bash
# Check GCP resources
gcloud compute instances list
gcloud compute firewall-rules list

# SSH into instance
ssh -i ~/.ssh/yolo_gcp_key ubuntu@YOUR_IP

# Check Docker containers
docker ps
docker compose -f /opt/yolo-app/docker-compose.yml ps

# View logs
docker compose -f /opt/yolo-app/docker-compose.yml logs

# Test endpoints
curl http://YOUR_IP:5000/api/health
curl http://YOUR_IP:3000
```

## Project Structure

```
stage_two/
├── playbooks/
│   ├── site.yml                    # Main orchestration playbook
│   └── terraform/                  # Terraform working directory
│       ├── main.tf                 # GCP infrastructure definition
│       ├── variables.tf            # Terraform variables
│       ├── outputs.tf              # Infrastructure outputs
│       └── terraform.tfstate       # State file (auto-generated)
│
├── roles/
│   ├── terraform/                  # Terraform automation role
│   │   ├── tasks/
│   │   │   └── main.yml           # Terraform execution tasks
│   │   └── templates/
│   │       └── main.tf.j2         # Terraform template
│   │
│   ├── common/                     # System configuration
│   │   └── tasks/
│   │       └── main.yml           # Base system setup
│   │
│   ├── docker/                     # Docker installation
│   │   └── tasks/
│   │       └── main.yml           # Docker & Compose setup
│   │
│   ├── application/                # App deployment
│   │   └── tasks/
│   │       └── main.yml           # Git clone, Docker build
│   │
│   └── mongo/                      # Database configuration
│       └── tasks/
│           └── main.yml           # MongoDB container management
│
├── group_vars/
│   └── all.yml                     # Global variables & configuration
│
├── inventory.yml                   # Minimal inventory (dynamic)
│
└── README.md                       # This file
```

## Configuration Variables

Key variables in `group_vars/all.yml`:

```yaml
# GCP Configuration
gcp_project_id: "{{ lookup('env', 'GCP_PROJECT_ID') }}"
gcp_region: "us-central1"
gcp_zone: "us-central1-a"
gcp_image: "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"

# Server Configuration
server_name: "yolo-stage2"
server_user: "ubuntu"

# Application Configuration
app_name: yolo-ecommerce
app_directory: /opt/yolo-app
git_repo: https://github.com/kennedy-dev/yolo.git
git_branch: master

# Ports
frontend_port: 3000
backend_port: 5000
mongodb_port: 27017

# SSH Configuration
ssh_private_key_path: "~/.ssh/yolo_gcp_key"
ssh_public_key_path: "~/.ssh/yolo_gcp_key.pub"
```

## Testing

### 1. Access the Application

```bash
# Get your instance IP
gcloud compute instances list --filter="name~yolo-stage2"

# Or from Terraform output
cd playbooks/terraform
terraform output instance_ip
```

### 2. Test Frontend
Open browser: `http://YOUR_IP:3000`

### 3. Test Backend API

```bash
# Health check
curl http://YOUR_IP:5000/api/health

# Get products
curl http://YOUR_IP:5000/api/products

# Add product (test functionality)
curl -X POST http://YOUR_IP:5000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "Stage 2 Cloud Deployment",
    "price": 99.99,
    "category": "testing"
  }'
```

### 4. Verify Data Persistence

```bash
# Add products via frontend
# Restart containers
ssh -i ~/.ssh/yolo_gcp_key ubuntu@YOUR_IP
cd /opt/yolo-app
docker compose restart

# Verify products still exist
curl http://YOUR_IP:5000/api/products
```

## Cleanup

### Remove GCP Resources

```bash
# Option 1: Using Terraform
cd ~/Documents/yolo/stage_two/playbooks/terraform
terraform destroy -auto-approve

# Option 2: Using gcloud CLI
gcloud compute instances delete yolo-stage2-XXXXX --zone=us-central1-a
gcloud compute firewall-rules delete yolo-firewall-XXXXX

# Option 3: Via Ansible (if you create a destroy playbook)
ansible-playbook -i inventory.yml playbooks/destroy.yml
```

### Verify Cleanup

```bash
# Check for remaining instances
gcloud compute instances list

# Check for firewall rules
gcloud compute firewall-rules list | grep yolo

# Check for SSH keys
ls ~/.ssh/yolo_gcp_key*
```

## Cost Considerations

### GCP Pricing (Approximate)
- **e2-medium instance:** ~$0.03/hour (~$21.60/month if running 24/7)
- **External IP:** ~$0.004/hour
- **Network egress:** First 1GB free, then ~$0.12/GB

### Cost Optimization Tips
1. **Destroy resources when not in use**
2. **Use preemptible instances for testing** (much cheaper)
3. **Monitor with GCP billing alerts**
4. **Use GCP free tier credits** (first $300 free for new accounts)

### Example Costs
- **Testing (4 hours):** ~$0.15
- **Daily use (8 hours):** ~$0.30
- **Full month (24/7):** ~$22

## Key Features Demonstrated

✅ **Infrastructure as Code:** Terraform manages all cloud resources declaratively  
✅ **Cloud Provisioning:** Real GCP Compute Engine with public IP  
✅ **Tool Integration:** Seamless Terraform → Ansible workflow  
✅ **Dynamic Inventory:** Ansible discovers infrastructure automatically  
✅ **Configuration Management:** Ansible roles for modular setup  
✅ **Container Orchestration:** Docker Compose for multi-container apps  
✅ **Security:** SSH key management, firewall rules, least privilege  
✅ **Automation:** Single-command deployment from code to production  
✅ **Idempotency:** Can run playbook multiple times safely  
✅ **Health Checks:** Automated verification of deployment success  

## Additional Resources

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Ansible GCP Guide](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html)
- [GCP Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GCP Free Tier](https://cloud.google.com/free)

## Support & Debugging

For issues or questions:

1. **Check logs:** SSH into instance and check Docker logs
2. **Verify configuration:** Review `group_vars/all.yml`
3. **Test connectivity:** Use `curl` to test endpoints
4. **GCP Console:** Check resources in GCP web console
5. **Ansible verbose mode:** Run with `-vvv` for detailed output

```bash
# Verbose deployment for debugging
ansible-playbook -i inventory.yml playbooks/site.yml -vvv
```

**Note:** Remember to destroy GCP resources after testing to avoid unnecessary charges!

```bash
cd playbooks/terraform && terraform destroy
```