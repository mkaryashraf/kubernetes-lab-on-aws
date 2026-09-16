# kubernetes-lab-on-aws

A three-node kubeadm cluster on EC2: one control plane (`cp`) and two workers
(`w-1`, `w-2`), built by Terraform and configured by Ansible.

Kubernetes version: **1.36.0** (set as `kubernetes_version` in
`ansible/k8s_lab_ansible_amazon_linux/group_vars/all/main.yml`).
Default region: **us-east-1** (the `region` variable in `lab_terraform/variables.tf`).

## Prerequisites

1. Install the Ansible, AWS and Terraform CLIs. Ansible does not run as a
   control node on Windows — use WSL or Linux.
2. Create a key pair in your AWS account and put its name in
   `lab_terraform/terraform.auto.tfvars`:

   ```hcl
   key_name   = "test_key"
   admin_cidr = "203.0.113.4/32"   # your own public IP, in CIDR form
   ```

   `admin_cidr` is the only address allowed to reach SSH and the Kubernetes API,
   so an empty or wrong value shows up as SSH timing out. `terraform.auto.tfvars`
   is gitignored.
3. Save the matching private key at `~/.ssh/<key_name>.pem` with mode `0400`.
   That is the path the generated inventory points at.

## Build

1. From `lab_terraform`, run `terraform init`, then `terraform apply`.

   Terraform also writes Ansible's two input files, so there is nothing to copy
   by hand:
   - `ansible/k8s_lab_ansible_amazon_linux/inventory.ini` — the three public IPs
   - `ansible/k8s_lab_ansible_amazon_linux/group_vars/all/terraform.yml` — `vpc_id`
     and `aws_region`

   Both are gitignored, because both go stale as soon as the lab is rebuilt.

2. From `ansible/k8s_lab_ansible_amazon_linux`, run:

   ```bash
   ansible-playbook -i inventory.ini site.yml
   ```

3. Nodes come up `NotReady` and stay that way until the AWS cloud controller
   manager removes the `node.cloudprovider.kubernetes.io/uninitialized` taint.
   The `networking` role installs it in the same run, so this resolves on its own.
   Check with `kubectl get nodes`.

4. Grafana is published on an internet-facing ALB at `grafana.makary.test` over
   plain HTTP. There is no DNS record for that name, so add a hosts entry
   pointing it at the ALB:

   ```bash
   kubectl get ingress -n monitoring   # take the ADDRESS, resolve it to an IP
   ```

   Then add `<alb-ip> grafana.makary.test` to `/etc/hosts` (or
   `C:\Windows\System32\drivers\etc\hosts`).

## Teardown

Order matters. The ALB, its target groups, and the security-group rules the load
balancer controller created are not in Terraform's state, so `terraform destroy`
does not remove them. Delete the Kubernetes objects that own them first, while
the cluster is still up.

```bash
# 1. On cp: remove the Ingress, so the controller deletes the ALB it created.
kubectl delete ingress --all -A

# 2. On cp: remove the PVCs, so the EBS CSI driver deletes their volumes.
#    The ebs-sc storage class uses reclaimPolicy: Delete, so this is enough.
kubectl delete pvc --all -A

# 3. Confirm both are gone before continuing.
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].VolumeId'

# 4. From lab_terraform:
terraform destroy
```

Skipping steps 1 and 2 leaves an ALB and a set of EBS volumes billing with
nothing attached to them.

## Which files belong to which lab

This repo carries leftovers from an earlier VirtualBox version of the same lab.
These describe **VirtualBox on Ubuntu 22.04, not AWS**:
`kubernetes_cluster_setup.txt`, `Kubernetes_Golden_Image_Documentation.txt`,
`lab_yaml/metallb_pool.yml`, and `lab_yaml/ingress.yml` (which targets
`ingressClassName: nginx`, and no nginx controller is installed on AWS).

## Review notes

`REVIEW.md` lists known issues with a suggested fix order, and
`IAM-PERMISSIONS.md` covers the IAM policies action by action.
