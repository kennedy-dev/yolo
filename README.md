# Stage 1: Ansible Configuration Management

## Overview
Automated deployment of a containerized e-commerce application using Ansible and Vagrant. This stage demonstrates configuration management and container orchestration using existing Docker configurations.

## What This Implements

| Component | Technology | Purpose |
|-----------|------------|---------|
| Infrastructure | Vagrant + VirtualBox | VM provisioning |
| Configuration | Ansible | System setup and deployment |
| Containers | Docker + Docker Compose | Application runtime |
| Database | MongoDB | Data persistence |

## Quick Start

### Prerequisites
- VirtualBox
- Vagrant
- Ansible (>= 2.9)

### One-Command Deployment
```bash
vagrant up
```

This command will:
1. Create Ubuntu 20.04 VM
2. Install Docker and dependencies
3. Clone application repository
4. Build and start all containers
5. Initialize database with sample data

### Access the Application
- Frontend: http://localhost:8080
- Backend API: http://localhost:8081/api
- Health Check: http://localhost:8081/api/health

## Key Features

- **Modular Roles**: Clean separation of concerns (common, docker, application, mongodb)
- **Uses Existing Configs**: Leverages repository's Docker configurations rather than recreating them
- **Data Persistence**: MongoDB data survives container restarts
- **Health Monitoring**: Application health checks and verification
- **Error Handling**: Graceful failure management and troubleshooting

## Testing Add Product Functionality

1. Navigate to http://localhost:8080
2. Find the "Add Product" form/page
3. Fill in product details (name, price, category, description)
4. Submit the form
5. Verify the product appears in the product list
6. Test persistence: `vagrant reload` and confirm data survives

## Manual Commands

```bash
# Check VM status
vagrant status

# SSH into VM
vagrant ssh

# Check containers
vagrant ssh -c "docker ps"

# View logs
vagrant ssh -c "docker logs kennedy-yolo-backend"

# Restart application
vagrant ssh -c "cd /opt/yolo-app && docker-compose restart"

# Clean rebuild
vagrant destroy -f && vagrant up
```

## Troubleshooting

**Port conflicts**: Modify host ports in Vagrantfile
```ruby
config.vm.network "forwarded_port", guest: 3000, host: 9090
```

**VM won't start**: Check VirtualBox installation and available resources

**Containers not building**: 
```bash
vagrant ssh
cd /opt/yolo-app
docker-compose logs
```

**Database connection issues**: Wait for MongoDB container to fully initialize (may take 30-60 seconds)

## What This Demonstrates

- **Infrastructure as Code**: VM and application defined in code
- **Configuration Management**: Automated system setup with Ansible
- **Container Orchestration**: Multi-service application deployment
- **Best Practices**: Modular roles, variable management, error handling
- **Production Patterns**: Health checks, logging, persistence

## Technical Implementation

- **Vagrant**: Uses Jeff Geerling's Ubuntu 20.04 box for reliability
- **Ansible**: 4 modular roles with proper dependency management
- **Docker**: Uses community.docker.docker_compose_v2 module for modern Docker Compose support
- **Variables**: Centralized configuration in group_vars/all.yml
- **Tags**: Selective task execution for debugging and development

Perfect foundation for demonstrating DevOps automation skills.
