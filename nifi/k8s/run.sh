
kubectl delete secret nifi-ca-secret

kubectl create secret generic nifi-ca-secret \
  --from-file=ca.crt=/home/jean/nifi/certs/ca.crt \
  --from-file=ca.key=/home/jean/nifi/certs/ca.key

kubectl delete statefulset nifi
kubectl delete service nifi
kubectl apply -f nifi-statefulset.yaml
kubectl apply -f nifi-service.yaml


kubectl delete pod nifi-0
kubectl delete pod nifi-1

kubectl get svc
kubectl get pods
