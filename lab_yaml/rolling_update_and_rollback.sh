#Rolling update
kubectl set image deployment/<deployment-name> <container-name>=<new-image>:<tag>


#check_rollout_status
kubectl rollout status deployment/<deployment-name>


#restart deployment
kubectl rollout restart deployment/<deployment-name>


######Rollback

#get rollout histroy
kubectl rollout history deployment/<deployment-name>

#rollback o previous version
kubectl rollout undo deployment/<deployment-name>


#to specific version
kubectl rollout undo deployment/<deployment-name> --to-revision=2

#scale deployemnt
kubectl scale deployment <deployment-name> --replicas=6


#to set a specifc namespace as default (switch from default to another name space context)
kubectl config set-context --current --namespace=<the new namesapce>

# Create a service for a replicated nginx, which serves on port 80 and connects to the containers on port 8000
kubectl expose rc nginx --port=80 --target-port=8000
k expose deploy test --port=9090 --target-port=80 --name=test-svc --type=NodePort


#to set editor before editing a resource using kubectl edit
KUBE_EDITOR="nano" kubectl edit <resource> <resource-name>

