variable "ami_name" {
  type   = string
  description = "Name of the output image"
}

variable "aws_region" {
  type   = string
  default = "eu-west-1"
}

variable "cloud_provider" {
  type   = string
  validation {
    condition     = contains(["gcp", "aws"], var.cloud_provider)
    error_message = "The instance_type must be 'gcp' or 'aws'."
  }
}

variable "gcp_zone" {
  type   = string
  default = "europe-west1-b"
}

variable "project_name" {
  type   = string
  default = "ConcordiumNode"
}

variable "subnet_id" {
  type    = string
}

variable "target_aws_regions" {
  type    = list(string)
  description = "List of regions to copy the AMI to"
}

variable "ami_users" {
  type    = list(string)
  default  = []
}
