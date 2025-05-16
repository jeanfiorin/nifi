import os
import time
import subprocess
import logging
from kazoo.client import KazooClient

# Configuração de logging estilo log4j
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)-8s %(name)-12s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger("hosts_updater")

HOSTS_FILE = "/etc/hosts"
START_MARKER = "# Pod Entries Start"
END_MARKER = "# Pod Entries End"

NIFI_ZK_CONNECT_STRING = os.getenv("NIFI_ZK_CONNECT_STRING")
if not NIFI_ZK_CONNECT_STRING:
    logger.error("Variável NIFI_ZK_CONNECT_STRING não definida")
    raise EnvironmentError("Variável NIFI_ZK_CONNECT_STRING não definida")

zk = KazooClient(hosts=NIFI_ZK_CONNECT_STRING)
zk.start()
logger.info("Cliente Zookeeper iniciado.")

def get_pods_list():
    if not zk.exists("/pods"):
        logger.warning("Znode /pods não existe no Zookeeper.")
        return []

    pods = zk.get_children("/pods")
    pods_data = []
    for pod in pods:
        pod_path = f"/pods/{pod}"
        try:
            d, _ = zk.get(pod_path)
            pods_data.append(d.decode("utf-8"))
        except Exception as e:
            logger.error(f"Erro ao obter dados de {pod_path}: {e}")
    return pods_data

def update_hosts_file(pod_lines):
    logger.debug("Atualizando arquivo /etc/hosts com informações dos pods...")

    POD_NAME = os.getenv("POD_NAME")
    POD_IP = os.getenv("POD_IP")
    POD_FQDN = os.getenv("POD_FQDN")

    if not all([POD_NAME, POD_IP, POD_FQDN]):
        logger.warning("Variáveis de ambiente POD_NAME, POD_IP ou POD_FQDN não estão definidas. Não será possível filtrar host local.")


    # Lê o /etc/hosts atual
    try:
        with open(HOSTS_FILE, "r") as f:
            lines = f.readlines()
    except Exception as e:
        logger.error(f"Erro ao ler {HOSTS_FILE}: {e}")
        return

    # Remove o bloco antigo
    start_idx = None
    end_idx = None
    for i, line in enumerate(lines):
        if line.strip() == START_MARKER:
            start_idx = i
        if line.strip() == END_MARKER:
            end_idx = i
            break

    if start_idx is not None and end_idx is not None:
        logger.debug("Removendo bloco antigo de pods do /etc/hosts")
        del lines[start_idx:end_idx+1]

    # Monta o novo bloco
    new_block = [START_MARKER + "\n"]
    for pod_line in pod_lines:
        parts = pod_line.split()
        if len(parts) < 3:
            logger.warning(f"Linha inválida recebida: {pod_line}")
            continue
        pod_ip, pod_name, pod_fqdn = parts[0], parts[1], parts[2]

        # Ignorar o host atual
        if (
            (POD_IP and pod_ip == POD_IP) or
            (POD_NAME and pod_name == POD_NAME) or
            (POD_FQDN and pod_fqdn == POD_FQDN)
        ):
            continue
                    
        new_block.append(f"{pod_ip}\t{pod_name}\t{pod_fqdn}\n")
    new_block.append(END_MARKER + "\n")

    lines.extend(["\n"])
    lines.extend(new_block)

    new_content = "".join(lines)

    try:
        subprocess.run(["sudo", "tee", HOSTS_FILE], input=new_content.encode(), check=True)
        logger.debug(f"/etc/hosts atualizado com {len(pod_lines)} pods.")
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao atualizar {HOSTS_FILE}: {e}")

def main_loop():
    logger.info("Iniciando loop principal de atualização do /etc/hosts")
    while True:
        pods_data = get_pods_list()
        if pods_data:
            update_hosts_file(pods_data)
        else:
            logger.info("Nenhum pod encontrado em /pods no Zookeeper.")
        time.sleep(30)

if __name__ == "__main__":
    try:
        main_loop()
    except KeyboardInterrupt:
        logger.info("Finalizando por interrupção manual.")
    finally:
        zk.stop()
        logger.info("Cliente Zookeeper encerrado.")
