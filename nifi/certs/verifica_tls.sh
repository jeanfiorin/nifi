#!/bin/bash

# Configurações
KEYSTORE_PATH="/etc/tls/keystore.jks"
TRUSTSTORE_PATH="/etc/tls/truststore.jks"
KEYSTORE_PASS="${KEYSTORE_PASSWORD:-changeit}"
TRUSTSTORE_PASS="${TRUSTSTORE_PASSWORD:-changeit}"
EXPECTED_CN="$(hostname -f)"  # Ex: nifi-0.nifi-headless.default.svc.cluster.local
ALIAS="nifi"  # Altere se necessário
TMP_DIR="/tmp/tls-check"
mkdir -p "$TMP_DIR"

echo "🔍 Verificando arquivos keystore e truststore..."

[[ ! -f "$KEYSTORE_PATH" ]] && echo "❌ Keystore não encontrado em $KEYSTORE_PATH" && exit 1
[[ ! -f "$TRUSTSTORE_PATH" ]] && echo "❌ Truststore não encontrado em $TRUSTSTORE_PATH" && exit 1

echo "✅ Keystore e truststore encontrados."

echo
echo "🔍 Listando conteúdo do truststore:"
keytool -list -keystore "$TRUSTSTORE_PATH" -storepass "$TRUSTSTORE_PASS" || exit 1

echo
echo "🔍 Extraindo certificado do keystore..."
keytool -exportcert -alias "$ALIAS" -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASS" -rfc -file "$TMP_DIR/nifi-cert.pem" || exit 1

echo
echo "🔍 Examinando certificado..."
openssl x509 -in "$TMP_DIR/nifi-cert.pem" -noout -text > "$TMP_DIR/cert-info.txt"

CN_FOUND=$(grep "Subject:" "$TMP_DIR/cert-info.txt" | sed -n 's/.*CN=\([^ ,]*\).*/\1/p')
SAN_FOUND=$(grep -A1 "Subject Alternative Name" "$TMP_DIR/cert-info.txt" | tail -n 1 | sed 's/ *DNS://g')

echo "CN encontrado:  $CN_FOUND"
echo "SAN encontrado: $SAN_FOUND"
echo "Esperado:       $EXPECTED_CN"

if [[ "$CN_FOUND" == "$EXPECTED_CN" ]] || [[ "$SAN_FOUND" == *"$EXPECTED_CN"* ]]; then
    echo "✅ CN ou SAN contém o hostname esperado."
else
    echo "❌ CN ou SAN NÃO contêm o hostname esperado."
fi

echo
echo "🔍 Validando cadeia do certificado com truststore..."
openssl verify -CAfile <(keytool -exportcert -alias myca -keystore "$TRUSTSTORE_PATH" -storepass "$TRUSTSTORE_PASS" -rfc) "$TMP_DIR/nifi-cert.pem" 2>&1

echo
echo "🧹 Limpando temporários..."
rm -rf "$TMP_DIR"

echo
echo "✅ Verificação concluída."

