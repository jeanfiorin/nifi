#!/bin/sh -e

#https://medium.com/@chnzhoujun/how-to-resolve-sni-issue-when-upgrading-to-nifi-2-0-907e07d465c5
#https://stackoverflow.com/questions/79472881/http-error-400-invalid-sni-when-deploying-nifi-on-docker/

scripts_dir='/opt/nifi/scripts'

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

export POD_NAME=$(hostname)
export POD_IP=$(hostname -i)
export POD_FQDN=$(hostname -f)
export KEYSTORE_PASSWORD=changeit
export TRUSTSTORE_PASSWORD=changeit

if [ "${POD_DEBUG}" = "true" ]; then
  echo "⚠️  POD_DEBUG ativado."
  tail -f /dev/null
fi




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


python3 ${scripts_dir}/register_pod.py > /dev/null 2>> /opt/nifi/nifi-current/logs/register_pod_error.log &
python3 ${scripts_dir}/update_hosts.py > /dev/null 2>> /opt/nifi/nifi-current/logs/register_pod_error.log &

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



echo 'Configurando entradas customizadas no nifi.properties'
prop_replace 'nifi.sensitive.props.key' "CHAVE-CLUSTER"

export NIFI_CLUSTER_ADDRESS=${POD_FQDN}

${scripts_dir}/start.sh


