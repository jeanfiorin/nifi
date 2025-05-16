#!/bin/bash

YAML_FILE="nifi-registry-deployment.yaml"

# Verifica se o arquivo existe
if [ ! -f "$YAML_FILE" ]; then
  echo "Arquivo $YAML_FILE não encontrado!"
  exit 1
fi

echo "Aplicando manifest $YAML_FILE..."
kubectl apply -f "$YAML_FILE" -n nifi

echo "Aguardando rollout do deployment nifi-registry no namespace nifi..."
kubectl rollout status deployment/nifi-registry -n nifi

echo "Listando pods no namespace nifi com label app=nifi-registry..."
kubectl get pods -n nifi -l app=nifi-registry

echo "Deploy concluído. Você pode acessar o serviço no NodePort http://localhost:31880"

