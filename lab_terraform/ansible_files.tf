# Ansible's inputs are generated from Terraform, not copied by hand. Every
# terraform apply used to invalidate two files that then had to be edited by
# hand, and both drifted: inventory.ini held three stale public IPs and
# group_vars held a stale vpc_id. Both generated files are gitignored.
#
# The amazon.aws.aws_ec2 dynamic inventory plugin is the more standard answer,
# but it needs boto3, a plugin config file, and tag-based grouping rules to
# replace these two resources. Worth it when the instance set stops being three
# fixed hosts.

locals {
  ansible_dir = "${path.module}/../ansible/k8s_lab_ansible_amazon_linux"
}

resource "local_file" "inventory" {
  filename = "${local.ansible_dir}/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl", {
    cp       = aws_instance.cp.public_ip
    workers  = [aws_instance.w_1.public_ip, aws_instance.w_2.public_ip]
    key_name = var.key_name
  })
}

# Lands next to group_vars/all/main.yml, which holds the static settings. Ansible
# loads every file in a group_vars/all/ directory, so the generated values and the
# hand-written ones merge with no vars_files entry in site.yml.
resource "local_file" "ansible_group_vars" {
  filename = "${local.ansible_dir}/group_vars/all/terraform.yml"
  content = yamlencode({
    vpc_id     = data.aws_vpc.default_vpc.id
    aws_region = var.region
  })
}
