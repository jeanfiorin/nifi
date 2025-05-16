import os
import time
import sys
import logging
from kazoo.client import KazooClient
from kazoo.protocol.states import KazooState

# Configuração de logging estilo log4j
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)-8s %(name)-12s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger("zk_client")

# Ler variáveis de ambiente
ZK_HOST = os.getenv('NIFI_ZK_CONNECT_STRING')
POD_NAME = os.getenv('POD_NAME')
POD_IP = os.getenv('POD_IP')
POD_FQDN = os.getenv('POD_FQDN')

NODE_PATH = f"/pods/{POD_NAME}"
NODE_DATA = f"{POD_IP} {POD_NAME} {POD_FQDN}".encode('utf-8')

# Verifica se as variáveis foram definidas
if not all([ZK_HOST, POD_NAME, POD_IP, POD_FQDN]):
    logger.error("Uma ou mais variáveis de ambiente não definidas: NIFI_ZK_CONNECT_STRING, POD_NAME, POD_IP, POD_FQDN")
    sys.exit(1)

def zk_listener(state):
    if state == KazooState.SUSPENDED:
        logger.warning("Conexão com Zookeeper suspensa.")
    elif state == KazooState.LOST:
        logger.error("Conexão com Zookeeper perdida. Encerrando o script.")
        zk.stop()
        sys.exit(1)
    elif state == KazooState.CONNECTED:
        pass


zk = KazooClient(hosts=ZK_HOST)
zk.add_listener(zk_listener)
zk.start()
logger.info("Cliente Zookeeper iniciado.")

# Criação do znode
if not zk.exists("/pods"):
    zk.create("/pods")
    logger.info("Znode raiz /pods criado.")

if zk.exists(NODE_PATH):
    zk.delete(NODE_PATH)
    logger.info(f"Znode antigo {NODE_PATH} removido.")

zk.create(NODE_PATH, NODE_DATA, ephemeral=True)
logger.info(f"Znode ephemeral {NODE_PATH} criado com dados: {NODE_DATA.decode()}")

try:
    logger.info("Sessão ativa. Aguardando...")
    while True:
        time.sleep(10)
except KeyboardInterrupt:
    logger.info("Encerrando manualmente...")
    zk.stop()
