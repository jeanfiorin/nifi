#!/bin/bash
set -e

NAMESPACE="nifi"

echo "Aplicando namespace..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

echo "Criando secret nifi-ca-secret..."
kubectl delete secret nifi-ca-secret -n $NAMESPACE --ignore-not-found
kubectl create secret generic nifi-ca-secret \
  --from-file=ca.crt=../certs/ca.crt \
  --from-file=ca.key=../certs/ca.key \
  -n $NAMESPACE


kubectl delete configmap nifi-conf-custom -n $NAMESPACE --ignore-not-found
kubectl create configmap nifi-conf-custom -n $NAMESPACE --from-file=../conf-custom

echo "Aplicando PVC..."

kubectl apply -f nifi-pvc.yaml

echo "Aplicando ConfigMap de estado..."
kubectl apply -f state-configmap.yaml -n "$NAMESPACE"

echo "Aplicando StatefulSet e serviço..."
kubectl apply -f nifi-statefulset.yaml -n "$NAMESPACE"

echo "Aguardando rollout do StatefulSet..."
kubectl rollout status statefulset/nifi -n "$NAMESPACE"

echo "Pods no namespace $NAMESPACE:"
kubectl get pods -n "$NAMESPACE" -l app=nifi

echo "Deploy concluído."

