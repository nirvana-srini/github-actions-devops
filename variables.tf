variable "ssh_public_key" {
  description = "SSH public key from GitHub Actions"
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "SSH public key cannot be empty."
  }
}

variable "ssh_private_key" {
  description = "SSH private key from GitHub Actions"
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.ssh_private_key)) > 0
    error_message = "SSH private key cannot be empty."
  }
}