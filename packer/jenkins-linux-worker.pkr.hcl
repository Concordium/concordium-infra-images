
variable "aws_access_key" {
  type    = string
  default = "${env("AWS_ACCESS_KEY_ID")}"
}

variable "aws_secret_key" {
  type    = string
  default = "${env("AWS_SECRET_ACCESS_KEY")}"
}

variable "version" {
  type    = string
  default = "4.0"
}

source "amazon-ebs" "amazon_linux_2" {
  access_key    = "${var.aws_access_key}"
  ami_name      = "jenkins-linux-worker-${var.version}"
  instance_type = "t2.micro"
  region        = "eu-west-1"
  secret_key    = "${var.aws_secret_key}"
  source_ami    = "ami-014ce76919b528bff"
  ssh_username  = "ec2-user"
  subnet_id     = "subnet-04b7c51a3d6f1ca6b"
  vpc_id        = "vpc-05eefc91014cdd7c0"
}

build {
  sources = ["source.amazon-ebs.amazon_linux_2"]

  provisioner "file" {
    destination = "/tmp/amazon-cloudwatch-agent.json"
    source      = "resources/amazon-cloudwatch-agent.json"
  }

  provisioner "shell" {
    inline = [
      "sleep 30", 
      "sudo yum update -y",
      "sudo yum list available",
      "sudo amazon-linux-extras install java-openjdk11", 
      "sudo yum install docker -y", 
      "sudo systemctl enable docker", 
      "sudo usermod -aG docker ec2-user", 
      "sudo yum install git -y", 
      "sudo yum install amazon-cloudwatch-agent -y", 
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/amazon-cloudwatch-agent.json", 
      "sudo yum install jq -y"
    ]
  }

}
