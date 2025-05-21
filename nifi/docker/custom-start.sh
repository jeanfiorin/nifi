#!/bin/sh -e

if [ "${POD_DEBUG}" = "true" ]; then
  echo "⚠️  POD_DEBUG ativado."
  tail -f /dev/null
fi


export scripts_dir='/opt/nifi/scripts'

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

export POD_NAME=$(hostname)
export POD_IP=$(hostname -i)
export POD_FQDN=$(hostname -f)
export KEYSTORE_PASSWORD=changeit
export TRUSTSTORE_PASSWORD=changeit



if ${scripts_dir}/check_zookeeper.sh; then
    echo "✅ Zookeeper OK"
else
    echo "❌ Falha ao verificar Zookeeper. Abortando."
    exit 1
fi

${scripts_dir}/generate_tls.sh

export KEYSTORE_PATH=/opt/nifi/certs/keystore.jks
export TRUSTSTORE_PATH=/opt/nifi/certs/truststore.jks
export KEYSTORE_TYPE=JKS
export TRUSTSTORE_TYPE=JKS


#${scripts_dir}/register_pod.sh &

ORIGEM="/opt/nifi/nifi-current/conf-custom"
DESTINO="/opt/nifi/nifi-current/conf"

ls -1 "$ORIGEM"/* | while read -r arquivo_origem; do
    nome_arquivo="$(basename "$arquivo_origem")"
    arquivo_destino="$DESTINO/$nome_arquivo"

    if [ -f "$arquivo_destino" ]; then
        echo "🔁 Sobrescrevendo $arquivo_destino"
        cat "$arquivo_origem" > "$arquivo_destino"
    else
        echo "📄 Copiando novo arquivo $arquivo_destino"
        cp "$arquivo_origem" "$arquivo_destino"
    fi

    chown nifi:nifi "$arquivo_destino"
done

# Definindo variáveis de ambiente diretamente no script
export NIFI_WEB_HTTPS_PORT=8443
export NIFI_REMOTE_INPUT_SOCKET_PORT=10000
export NIFI_REMOTE_INPUT_SECURE=true
export NIFI_CLUSTER_ADDRESS=${POD_IP}
export NIFI_CLUSTER_IS_NODE=true
export NIFI_CLUSTER_NODE_PROTOCOL_PORT=8082
export NIFI_REMOTE_INPUT_SOCKET_PORT=10000
export NIFI_REMOTE_INPUT_SECURE=true
export NIFI_ELECTION_MAX_WAIT="5 mins"
export NIFI_ELECTION_MAX_CANDIDATES=1
export NIFI_WEB_HTTPS_HOST=${POD_IP}
export NIFI_REMOTE_INPUT_HOST=${POD_IP}

echo 'Configurando entradas customizadas no nifi.properties'
prop_replace 'nifi.sensitive.props.key' "CHAVE-CLUSTER"
prop_replace 'nifi.zookeeper.connect.timeout' "30 secs"
prop_replace 'nifi.zookeeper.session.timeout' "30 secs"
prop_replace 'nifi.cluster.protocol.heartbeat.interval' "30 secs"
prop_replace 'nifi.cluster.node.read.timeout' "30 secs"
prop_replace 'nifi.cluster.node.connection.timeout' "30 secs"
prop_replace 'nifi.cluster.node.read.timeout' "30 secs"
prop_replace 'nifi.cluster.load.balance.comms.timeout' "30 secs"


# Reduza threads para economizar CPU
prop_replace 'nifi.flowengine.threads' "8"
prop_replace 'nifi.cluster.node.max.concurrent.requests' "50"


${scripts_dir}/start.sh


