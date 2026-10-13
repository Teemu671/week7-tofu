output "public_ip" {
  description = "The public IP address assigned to the Apache web server."
  value       = openstack_networking_floatingip_v2.web.address
}

output "web_server_url" {
  description = "HTTP URL of the custom webpage."
  value       = "http://${openstack_networking_floatingip_v2.web.address}/"
}

output "ssh_connection_command" {
  description = "SSH terminal command."
  value       = "ssh -i ${replace(var.ssh_public_key_path, ".pub", "")} ubuntu@${openstack_networking_floatingip_v2.web.address}"
}
