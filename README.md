# kubernetes-lab-on-aws
# #Prerequisites:
1- install ansible and AWS cli and terraform cli
2- create a key pair on your AWS account and add the name to the terraform.auto.tfvars file under **lab_terraform** folder

# #Steps:
1- go to lab_terraform directory and exceute command **terraform apply** then press yes when prompted to.
2- take the output values from terraform and put it inside **common.yaml** and inventory.ini accordingly under directory **ansible\k8s_lab_ansible_amazon_linux**
3- run command `ansible-playbook -i inventory.ini site.yaml` to start the setup of the different servers
 
