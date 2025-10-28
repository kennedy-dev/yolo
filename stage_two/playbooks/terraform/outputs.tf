output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.yolo_server.name
}

output "instance_ip" {
  description = "External IP address of the instance"
  value       = google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.yolo_server.network_interface[0].network_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip}"
}

output "application_urls" {
  description = "Application access URLs"
  value = {
    frontend    = "http://${google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip}:3000"
    backend_api = "http://${google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip}:5000/api"
    health      = "http://${google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip}:5000/api/health"
  }
}

output "instance_details" {
  description = "Complete instance information"
  value = {
    name         = google_compute_instance.yolo_server.name
    machine_type = google_compute_instance.yolo_server.machine_type
    zone         = google_compute_instance.yolo_server.zone
    external_ip  = google_compute_instance.yolo_server.network_interface[0].access_config[0].nat_ip
    internal_ip  = google_compute_instance.yolo_server.network_interface[0].network_ip
    ssh_user     = "ubuntu"
  }
}