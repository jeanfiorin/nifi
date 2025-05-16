# =============================
# Configurações
# =============================
CERT_NAME=pod
KEYSTORE_PASSWORD=changeit
TRUSTSTORE_PASSWORD=changeit
KEY_ALIAS=nifi
CN=nifi-headless.default.svc.cluster.local


# =============================
# Alvos principais
# =============================

all: clean ca cert keystore truststore

# =============================
# Criar CA (autoridade certificadora)
# =============================
ca:
	@echo "==> Gerando CA"
	openssl genrsa -out ca.key 4096
	openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
		-out ca.crt -subj "/CN=MyInternalCA/O=MyOrg/C=BR"

# =============================
# Gerar certificado e assinar com a CA
# =============================
cert:
	@echo "==> Gerando chave e certificado assinado"
	openssl genrsa -out $(CERT_NAME).key 2048
	openssl req -new -key $(CERT_NAME).key -out $(CERT_NAME).csr \
		-subj "/CN=$(CN)/O=MyApp"
	openssl x509 -req -in $(CERT_NAME).csr -CA ca.crt -CAkey ca.key \
		-CAcreateserial -out $(CERT_NAME).crt -days 365 -sha256

# =============================
# Criar keystore.jks com chave + certificado assinado
# =============================
keystore:
	@echo "==> Criando keystore.jks"
	openssl pkcs12 -export \
		-in $(CERT_NAME).crt -inkey $(CERT_NAME).key \
		-out $(CERT_NAME).p12 \
		-name $(KEY_ALIAS) \
		-CAfile ca.crt -caname root \
		-passout pass:$(KEYSTORE_PASSWORD)
	keytool -importkeystore \
		-deststorepass $(KEYSTORE_PASSWORD) -destkeypass $(KEYSTORE_PASSWORD) \
		-destkeystore keystore.jks \
		-srckeystore $(CERT_NAME).p12 -srcstoretype PKCS12 \
		-srcstorepass $(KEYSTORE_PASSWORD) -alias $(KEY_ALIAS)

# =============================
# Criar truststore.jks com a CA
# =============================
truststore:
	@echo "==> Criando truststore.jks"
	keytool -import -trustcacerts -alias my-ca \
		-file ca.crt -keystore truststore.jks \
		-storepass $(TRUSTSTORE_PASSWORD) -noprompt

# =============================
# Limpeza
# =============================
clean:
	@echo "==> Limpando arquivos antigos"
	rm -f *.csr *.srl *.p12 *.jks *.crt *.key


