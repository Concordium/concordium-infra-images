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
    "concordium:environment" = "BaseImage"
    "packer:source-ami" = "{{ .SourceAMIName }}"
  }
}

source "googlecompute" "observability" {
  image_name = "${var.ami_name}"
  project_id = "concordium-mgmt-0"
  source_image_family = "ubuntu-2204-lts"
  zone = "${var.gcp_zone}"
  machine_type = "e2-micro"
  ssh_username = "ubuntu"
  image_labels = local.labels_gcp
  ssh_clear_authorized_keys = true
}

source "amazon-ebs" "observability" {
  ami_name      = "${var.ami_name}"
  ami_users     = "${var.ami_users}"
  instance_type = "t2.medium"
  region        = "${var.aws_region}"
  ami_regions   = "${var.target_aws_regions}"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" // Ubuntu 22.04 LTS
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] // Canonical
    most_recent = true
  }
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp3"
    delete_on_termination = true
  }
  ssh_clear_authorized_keys = true
  ssh_username = "ubuntu"
  subnet_id    = "${var.subnet_id}"
  tags = local.labels_aws
}

locals {
  url_versions = {
    process-exporter = "0.7.10",
    promtail         = "3.0.0",
  }

  apt_versions = {
    jq = "1.6*"
    libpam-google-authenticator = "20191231-2"
    net-tools = "1.60*"
    nvme-cli = "1.16-3ubuntu*"
    pkgconf = "1.8.0-1"
    prometheus-node-exporter = "1.3.1-1ubuntu*"
    python3-pip = "22.0.2*"
    software-properties-common = "0.99.*"
    tree = "2.0.2-1*"
  }

  python_versions = {
    awscli = "1.29.58"
    boto3 = "1.28.58"
    cryptography = "41.0.3"
    jmespath = "1.0.1"
    openshift = "0.13.2"
    PyMySQL = "1.1.0"
    pyopenssl = "23.2.0"
    paramiko = "3.3.1"
    stormssh = "0.7.0"
  }

  urls = {
    process-exporter = "https://github.com/ncabatoff/process-exporter/releases/download/v${local.url_versions["process-exporter"]}/process-exporter_${local.url_versions["process-exporter"]}_linux_amd64.deb",
    promtail = "https://github.com/grafana/loki/releases/download/v${local.url_versions["promtail"]}/promtail_${local.url_versions["promtail"]}_amd64.deb",
  }
}

build {
  sources = var.cloud_provider == "aws" ? ["source.amazon-ebs.observability"] : ["source.googlecompute.observability"]
  provisioner "shell" {
    inline = concat(flatten([
      for key, value in local.urls : [
          "curl -sL -o /tmp/${key}-amd64.deb ${value}",
          "sudo dpkg -i /tmp/${key}-amd64.deb",
          "sudo systemctl disable ${key}",
          "rm /tmp/${key}-amd64.deb",
        ]
      ]
      ),
      ["sudo apt-get update -y"],
      [format("sudo apt-get install -y %s", join(" ", [for key, value in local.apt_versions : "${key}=${value}"]))],
      [for key, _ in local.apt_versions : <<-EOF
        if systemctl is-active --quiet ${key}; then
          sudo systemctl disable ${key}
        fi
      EOF
      ],
      [format("sudo --set-home pip install %s", join(" ", [for key, value in local.python_versions : "${key}==${value}"]))],
      ["sudo systemctl disable unattended-upgrades"],
      ["sudo sed  --in-place '/{/a \\        maxsize 10G' /etc/logrotate.d/rsyslog"],
    )
  }
}
