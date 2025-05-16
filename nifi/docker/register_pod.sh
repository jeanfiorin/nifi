#!/bin/bash


output=/opt/nifi/nifi-current/logs/register_pod.log

# O script que atualiza os hosts fica em background
python3 ${scripts_dir}/update_hosts.py > "$output" 2>&1 &

# o script que registra o pod fica aguardando, se o zookeeeper morrer, ele vai encerrar o processo java do nifi
python3 ${scripts_dir}/register_pod.py > "$output" 2>&1

# Encerra todos os processos Java de forma graciosa e depois forçada, se necessário

echo "[INFO] Procurando processos Java..."
PIDS=$(pgrep -f java)

if [ -z "$PIDS" ]; then
    echo "[INFO] Nenhum processo Java encontrado."
    exit 0
fi

echo "[INFO] Encontrados os seguintes processos Java:"
echo "$PIDS"

# Enviar SIGTERM para encerramento gracioso
echo "[INFO] Enviando SIGTERM para encerramento gracioso..."
kill -TERM $PIDS

# Aguardar até 60 segundos para que todos os processos terminem
MAX_WAIT=60
WAITED=0
SLEEP_INTERVAL=5

while [ $WAITED -lt $MAX_WAIT ]; do
    STILL_RUNNING=$(pgrep -f java)
    if [ -z "$STILL_RUNNING" ]; then
        echo "[INFO] Todos os processos Java foram encerrados graciosamente."
        exit 0
    fi
    echo "[INFO] Ainda aguardando encerramento... ($WAITED/$MAX_WAIT segundos)"
    sleep $SLEEP_INTERVAL
    WAITED=$((WAITED + SLEEP_INTERVAL))
done

# Se ainda existirem processos Java após o tempo limite, força encerramento
echo "[WARN] Tempo esgotado. Forçando encerramento com SIGKILL..."
kill -KILL $PIDS

echo "[INFO] Processos Java finalizados com SIGKILL."
exit 0

