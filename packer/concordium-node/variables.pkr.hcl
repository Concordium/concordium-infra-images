variable "aws_region" {
  type   = string
  default = "eu-west-1"
}

variable "gcp_zone" {
  type   = string
  default = "europe-west1-b"
}

variable "ami_name" {
  type   = string
}

variable "concordium_node_path" {
  type    = string
}

variable "environment" {
  type    = string
  default = "stagenet"
}

variable "node_name_prefix" {
  type    = string
  default = "default-name"
}

variable "project_name" {
  type   = string
  default = "ConcordiumNode"
}

variable "source_ami_id" {
  type    = string
}

variable "cloud_provider" {
  type   = string
  validation {
    condition     = contains(["gcp", "aws"], var.cloud_provider)
    error_message = "The instance_type must be 'gcp' or 'aws'."
  }
}

variable "subnet_id" {
  type    = string
}

variable "ami_users" {
  type    = list(string)
  default  = []
}
