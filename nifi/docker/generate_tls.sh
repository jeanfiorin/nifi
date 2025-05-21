#!/bin/bash

set -e

KEYSTORE_PASS="${KEYSTORE_PASSWORD:-changeit}"
TRUSTSTORE_PASS="${TRUSTSTORE_PASSWORD:-changeit}"
ALIAS="nifi"
CERT_DIR="/opt/nifi/certs"
FQDN="${POD_FQDN}"

echo "📛 Hostname FQDN detectado: $FQDN"

mkdir -p "$CERT_DIR"

# Salva o diretório atual
OLD_DIR=$(pwd)

# Muda para o diretório alvo
cd "$CERT_DIR" || { echo "Falha ao mudar para $CERT_DIR"; exit 1; }

cp /etc/tls/ca.* $CERT_DIR || { echo "Falha ao copiar arquivos '/etc/tls/ca.*' para $CERT_DIR "; exit 1; }

# 1. Gera chave privada
openssl genpkey -algorithm RSA -out "${FQDN}.key" -pkeyopt rsa_keygen_bits:2048

# 2. Cria config com CN e SAN
cat > "cert.cnf" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext


[ dn ]
CN = $FQDN

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = $FQDN
DNS.2 = $POD_NAME
DNS.3 = localhost
DNS.4 = nifi
DNS.5 = nifi.default.svc
DNS.6 = nifi.default.svc.cluster.local
DNS.7 = nifi-headless
DNS.8 = nifi-headless.default.svc.cluster.local
IP.1  = $POD_IP
EOF

# 3. Gera CSR
openssl req -new -key "${FQDN}.key" -out "${FQDN}.csr" -config "cert.cnf"

# 4. Assina com a CA (montada no pod como ca.crt e ca.key)
openssl x509 -req -in "${FQDN}.csr" -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out "${FQDN}.crt" -days 365 -sha256 -extfile "cert.cnf" -extensions req_ext

# 5. Gera PKCS#12
openssl pkcs12 -export -in "${FQDN}.crt" -inkey "${FQDN}.key" \
  -out "${FQDN}.p12" -name "$ALIAS" -CAfile ca.crt -caname root \
  -passout pass:$KEYSTORE_PASS

# 6. Cria keystore.jks
keytool -importkeystore -deststorepass $KEYSTORE_PASS -destkeystore "keystore.jks" \
  -srckeystore "${FQDN}.p12" -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASS -alias $ALIAS

# 7. Cria truststore.jks
keytool -import -alias root -file ca.crt -keystore "truststore.jks" \
  -storepass $TRUSTSTORE_PASS -noprompt

echo "✅ keystore.jks e truststore.jks prontos."

# Volta para o diretório original
cd "$OLD_DIR" || { echo "Falha ao voltar para $OLD_DIR"; exit 1; }
