kubectl autoscale deployment <deployment_name> --min=2 --max=10 --cpu-percent=70


kubectl get hpa


kubectl delete hpa <hpa_name>
