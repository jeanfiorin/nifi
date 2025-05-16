import os
import time
from kazoo.client import KazooClient

# Ler variáveis de ambiente
ZK_HOST = os.getenv('NIFI_ZK_CONNECT_STRING')
POD_NAME = os.getenv('POD_NAME')
POD_IP = os.getenv('POD_IP')
POD_FQDN = os.getenv('POD_FQDN')

NODE_PATH = f"/pods/{POD_NAME}"
NODE_DATA = f"{POD_IP} {POD_NAME} {POD_FQDN}".encode('utf-8')

# Verifica se as variáveis foram definidas
if not all([ZK_HOST, POD_NAME, POD_IP, POD_FQDN]):
    raise EnvironmentError("Uma ou mais variáveis de ambiente não definidas: NIFI_ZK_CONNECT_STRING, POD_NAME, POD_IP, POD_FQDN")

zk = KazooClient(hosts=ZK_HOST)
zk.start()

if not zk.exists("/pods"):
    zk.create("/pods")

if zk.exists(NODE_PATH):
    zk.delete(NODE_PATH)

zk.create(NODE_PATH, NODE_DATA, ephemeral=True)

print("Znode ephemeral criado e sessão aberta. Ctrl+C para sair.")

try:
    while True:
        time.sleep(10)
        pass  # Mantém a sessão aberta
except KeyboardInterrupt:
    zk.stop()

