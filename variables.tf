variable "project_network" {
  type        = string
  description = "Project name on cPouta."
}
variable "ssh_allowed_cidr" {
  type        = string
  description = "Permitted IPs to SSH."
  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be in CIDR format."
  }
}
variable "page_message" {
  type        = string
  description = "Message to webpage."
  default     = "Hello from OpenTofu!"
}

variable "student_name" {
  type        = string
  description = "Student name."
}
variable "name_prefix" {
  type        = string
  description = "Prefix of used resources."
  default     = "week7-tofu"
}
variable "ssh_public_key_path" {
  type        = string
  description = "Path to public key."
  default     = "~/.ssh/week7_ed25519.pub"
}
variable "image_name" {
  type        = string
  description = "Image name on cPouta."
  default     = "Ubuntu-24.04"
}
variable "flavor_name" {
  type        = string
  description = "Deployment flavor on cPouta."
  default     = "standard.tiny"
}

