#!/bin/bash

# Nome do arquivo do manifest
YAML_FILE="zookeeper-deployment.yaml"

# Verifica se o arquivo existe
if [ ! -f "$YAML_FILE" ]; then
  echo "Arquivo $YAML_FILE não encontrado!"
  exit 1
fi

# Aplica o manifest no cluster
echo "Aplicando manifest $YAML_FILE..."
kubectl apply -f "$YAML_FILE"

# Verifica se o deployment foi criado com sucesso
echo "Verificando status do Deployment zookeeper..."
kubectl rollout status deployment/zookeeper

# Verifica os pods
echo "Listando pods com label app=zookeeper..."
kubectl get pods -l app=zookeeper

echo "Deploy concluído."

