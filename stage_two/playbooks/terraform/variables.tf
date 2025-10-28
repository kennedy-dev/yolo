variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "ecommerce-476502"
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "server_name" {
  description = "Name of the server to provision"
  type        = string
  default     = "yolo-stage2"
}

variable "machine_type" {
  description = "GCP Machine Type"
  type        = string
  default     = "e2-medium"
}

variable "ssh_user" {
  description = "SSH username for the instance"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/yolo_gcp_key.pub"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage2"
}

variable "frontend_port" {
  description = "Frontend application port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend API port"
  type        = number
  default     = 5000
}