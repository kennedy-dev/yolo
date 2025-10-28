terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Create firewall rules for the application
resource "google_compute_firewall" "yolo_firewall" {
  name    = "yolo-firewall-${random_id.suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "5000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["yolo-server"]
}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Create GCP Compute Engine instance
resource "google_compute_instance" "yolo_server" {
  name         = "yolo-stage2-${random_id.suffix.hex}"
  machine_type = var.machine_type
  zone         = var.gcp_zone

  # Ubuntu 20.04 LTS boot disk
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts""
      size  = 20
      type  = "pd-standard"
    }
  }

  # Network configuration
  network_interface {
    network = "default"
    
    # External IP for public access
    access_config {
      network_tier = "STANDARD"
    }
  }

  # SSH key and startup script
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y python3 python3-pip
      pip3 install docker
    EOF
  }

  # Tags for firewall rules
  tags = ["yolo-server"]

  # Labels for organization
  labels = {
    environment = var.environment
    project     = "yolo-ecommerce"
    stage       = "stage2"
  }
}
