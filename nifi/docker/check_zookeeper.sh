#!/bin/bash

# Separar pelo caractere ':'
HOST="${NIFI_ZK_CONNECT_STRING%%:*}"
PORT="${NIFI_ZK_CONNECT_STRING##*:}"

MAX_ATTEMPTS=30
SLEEP_SECONDS=10

attempt=1

while (( attempt <= MAX_ATTEMPTS )); do
    echo "Tentativa $attempt: verificando $HOST:$PORT..."
    
    if nc -z "$HOST" "$PORT"; then
        echo "✅ Porta $PORT aberta no host $HOST."
        exit 0
    else
        echo "❌ Host $HOST, Porta $PORT não está aberta."
        ((attempt++))
        sleep "$SLEEP_SECONDS"
    fi
done

echo "❌ Erro: Porta $PORT não está acessível após $MAX_ATTEMPTS tentativas."
exit 1
