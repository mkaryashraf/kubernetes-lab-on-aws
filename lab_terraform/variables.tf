variable "key_name" {
  type        = string
  description = "key pair for ec2"
}


variable "region" {
  type        = string
  description = "region"
  default     = "us-east-1"
}

# No default on purpose. A default here would be either wrong or too wide, and a
# wrong value only shows up as SSH timing out, which is easy to diagnose. Set it
# in terraform.auto.tfvars; that file is gitignored.
variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR form, e.g. 203.0.113.4/32. Only this address may reach SSH and the Kubernetes API."

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be valid CIDR notation, for example 203.0.113.4/32."
  }
}