provider "aws" {
  region = var.region
}

resource "aws_instance" "cp" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.medium"
  key_name             = var.key_name
  security_groups      = [aws_security_group.allow_all.name]
  iam_instance_profile = aws_iam_instance_profile.nodes_profile.name

  tags = {
    Name                                    = "control-plane"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}


resource "aws_instance" "w_1" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.medium"
  key_name             = var.key_name
  security_groups      = [aws_security_group.allow_all.name]
  iam_instance_profile = aws_iam_instance_profile.nodes_profile.name

  tags = {
    Name                                    = "worker-1"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}


resource "aws_instance" "w_2" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.medium"
  key_name             = var.key_name
  security_groups      = [aws_security_group.allow_all.name]
  iam_instance_profile = aws_iam_instance_profile.nodes_profile.name

  tags = {
    Name                                    = "worker-2"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}

