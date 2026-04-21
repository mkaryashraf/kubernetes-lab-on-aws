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



