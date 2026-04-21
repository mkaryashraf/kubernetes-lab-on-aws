# On control plane

# 1. Generate a private key for dev-user
openssl genrsa -out dev-user.key 2048

#2. Create a Certificate Signing Request (CSR)
#    CN=dev-user  → this becomes the username in Kubernetes
#    O=dev-team   → this becomes the group
openssl req -new \
  -key dev-user.key \
  -out dev-user.csr \
  -subj "/CN=dev-user/O=dev-team"


#3. Sign the certificate with the cluster CA
openssl x509 -req \
  -in dev-user.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial \
  -out dev-user.crt \
  -days 365



# Add the user credentials to kubeconfig
kubectl config set-credentials dev-user \
  --client-certificate=dev-user.crt \
  --client-key=dev-user.key

# Create a context for dev-user
# context = cluster + user + namespace combined
kubectl config set-context dev-context \
  --cluster=k8s-lab-cluster \
  --namespace=dev \
  --user=dev-user




# Deploy something to dev namespace as admin first
kubectl create deployment nginx --image=nginx -n dev

# Now test as dev-user using dev-context

# ✅ Should work — list pods
kubectl --context=dev-context get pods -n dev

# ✅ Should work — get a specific pod
kubectl --context=dev-context get pod <pod-name> -n dev

# ❌ Should fail — delete pod
kubectl --context=dev-context delete pod <pod-name> -n dev

# ❌ Should fail — access different namespace
kubectl --context=dev-context get pods -n default

# ❌ Should fail — create deployment
kubectl --context=dev-context create deployment test --image=nginx -n dev



# Check what dev-user can do in dev namespace
kubectl auth can-i --list --as=dev-user -n dev

# Check specific permissions
kubectl auth can-i get pods --as=dev-user -n dev        # yes
kubectl auth can-i delete pods --as=dev-user -n dev     # no
kubectl auth can-i get pods --as=dev-user -n default    # no
kubectl auth can-i get nodes --as=dev-user 


# Switch to dev-user context
kubectl config use-context dev-context

# Now all kubectl commands use dev-user automatically
kubectl get pods -n dev    # no --context needed

# Switch back to admin
kubectl config use-context kubernetes-admin@k8s-lab-cluster