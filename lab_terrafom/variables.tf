variable "key_name" {
  type        = string
  description = "key pair for ec2"
}


variable "region" {
  type        = string
  description = "region"
  default     = "us-east-1"
}