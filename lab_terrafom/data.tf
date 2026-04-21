data "aws_region" "current" {}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "aws_vpc" "default_vpc" {
  default = true
}

# 2. Retrieve all subnets within the default VPC using a data source
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# 3. Add tags to each of the found subnets using the aws_ec2_tag resource
#    The for_each loop iterates over the set of subnet IDs found by the data source.
resource "aws_ec2_tag" "subnet_cluster_tags" {
  for_each = toset(data.aws_subnets.default_subnets.ids)

  resource_id = each.value
  key         = "kubernetes.io/cluster/k8s-lab-cluster"
  value       = "shared"
}

# Optional: Add another tag to each subnet
resource "aws_ec2_tag" "subnet_elb_tags" {
  for_each = toset(data.aws_subnets.default_subnets.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}