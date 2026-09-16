provider "aws" {
  region = var.region
}

resource "aws_instance" "cp" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.medium"
  key_name             = var.key_name
  security_groups      = [aws_security_group.allow_all.name]
  iam_instance_profile = aws_iam_instance_profile.nodes_profile.name

  # The AMI default is 8 GiB, which two full dnf upgrades, the Calico and
  # controller images, and a 10Gi Prometheus PVC will fill. A full root disk
  # shows up as pods being evicted for no stated reason.
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name                                    = "control-plane"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}


# No iam_instance_profile on either worker, on purpose. Every controller that
# calls the EC2 API (CCM, Load Balancer Controller, EBS CSI *controller*) is
# pinned to the control plane in roles/networking/tasks/main.yml. What runs here
# is the EBS CSI node DaemonSet, which reads IMDS only and needs no credentials.
# With no profile attached the IMDS credentials endpoint returns 404, so there is
# nothing for a pod on these nodes to steal.
#
# Add a profile back if you start pulling images from a private ECR repository:
# kubelet then needs ecr:GetAuthorizationToken plus the layer-read actions on
# every node. For SSM Session Manager, make a separate role holding only
# AmazonSSMManagedInstanceCore rather than reusing the control-plane one.
resource "aws_instance" "w_1" {
  ami             = data.aws_ami.amazon_linux_2023.id
  instance_type   = "t3.medium"
  key_name        = var.key_name
  security_groups = [aws_security_group.allow_all.name]

  # See the comment on aws_instance.cp for why 30 GiB and not the AMI default.
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name                                    = "worker-1"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}


# No iam_instance_profile here either - see the comment on aws_instance.w_1.
resource "aws_instance" "w_2" {
  ami             = data.aws_ami.amazon_linux_2023.id
  instance_type   = "t3.medium"
  key_name        = var.key_name
  security_groups = [aws_security_group.allow_all.name]

  # See the comment on aws_instance.cp for why 30 GiB and not the AMI default.
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name                                    = "worker-2"
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}

