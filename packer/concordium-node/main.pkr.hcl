packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source  = "github.com/hashicorp/amazon"
    }
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = ">= 1.1.0"
    }
  }
}

locals {
  project_name_gcp = "${trim(lower(regex_replace(var.project_name, "([A-Z])", "_$1")), "_")}"
  labels_gcp = {
    project = "${local.project_name_gcp}"
  }
  labels_aws = {
    "packer:project" = "${var.project_name}"
    "concordium:environment" = "${upper(substr(var.environment, 0, 1))}${substr(var.environment, 1, -1)}"
    "packer:source-ami" = "{{ .SourceAMIName }}"
  }
}

source "amazon-ebs" "concordium-node" {
  ami_name      = "${var.ami_name}"
  ami_users     = "${var.ami_users}"
  instance_type = "t2.medium"
  region        = "${var.aws_region}"
  snapshot_users = "${var.ami_users}"
  source_ami    = "${var.source_ami_id}"
  ssh_username  = "ubuntu"
  ssh_clear_authorized_keys = true
  subnet_id = "${var.subnet_id}"
  tags = local.labels_aws
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp3"
    delete_on_termination = true
  }
}

source "googlecompute" "concordium-node" {
  image_name = "${var.ami_name}"
  project_id = "concordium-mgmt-0"
  source_image = "${var.source_ami_id}"
  zone = "${var.gcp_zone}"
  machine_type = "e2-micro"
  ssh_username = "ubuntu"
  image_project_id = "concordium-${var.environment}-0"
  image_labels = local.labels_gcp
  ssh_clear_authorized_keys = true
}

build {
  sources = var.cloud_provider == "aws" ? ["source.amazon-ebs.concordium-node"] : ["source.googlecompute.concordium-node"]

  provisioner "file" {
    source      = "${var.concordium_node_path}"
    destination = "/tmp/concordium_node.deb"
  }
  provisioner "shell" {
    inline = [
      "echo 'concordium-${var.environment}-node-collector concordium-${var.environment}-node-collector/node-name string ${var.node_name_prefix}-${var.cloud_provider}' | sudo debconf-set-selections",
      "sudo dpkg -i /tmp/concordium_node.deb",
      "sudo rm /tmp/concordium_node.deb",
      "config_files=$(sudo bash -c 'find /var/lib/private/concordium-*/config/main.config.json -type f')",
      "if [ $(echo \"$config_files\" | wc -l) -ne 1 ]; then echo \"Expected to find exactly one main.config.json file, but found $(config_files | wc -l)\"; exit 1; fi",
      "sudo rm $config_files"
    ]
  }
}
