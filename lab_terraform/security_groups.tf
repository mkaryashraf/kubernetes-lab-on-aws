# The resource name and the group name are still "allow_all" for historical
# reasons, but inbound is no longer open: see the three ingress rules below.
# Renaming the group would force a replacement of the group and of all three
# instances, which reference it by name, so the name is left as it is.
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "SSH and Kubernetes API from the admin CIDR, plus unrestricted traffic between cluster nodes"
  vpc_id      = data.aws_vpc.default_vpc.id

  tags = {
    Name = "allow_all"
    # The Load Balancer Controller finds the node security group by this tag, so
    # it can open the NodePort range for its ALB target groups. Without the tag
    # it has nowhere to add the rule and ALB health checks fail with no obvious
    # cause.
    "kubernetes.io/cluster/k8s-lab-cluster" = "owned"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# These three rules replace the two that allowed every port from 0.0.0.0/0 and
# ::/0. What was reachable from the internet: 6443 (API server), 10250 (kubelet),
# and 30000-32767 (NodePorts, carrying whatever is deployed).
resource "aws_vpc_security_group_ingress_rule" "ssh_from_admin" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "api_from_admin" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
}

# Nodes talk to each other freely - kubelet, etcd, CNI, NodePorts. Do not delete
# this rule: without it the cluster breaks in ways that look like CNI bugs. It
# allows traffic between members of this group only, and opens nothing to the
# outside.
resource "aws_vpc_security_group_ingress_rule" "intra_cluster" {
  security_group_id            = aws_security_group.allow_all.id
  referenced_security_group_id = aws_security_group.allow_all.id
  ip_protocol                  = "-1"
}