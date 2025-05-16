import os
import time
import subprocess
from kazoo.client import KazooClient

HOSTS_FILE = "/etc/hosts"
START_MARKER = "# Pod Entries Start"
END_MARKER = "# Pod Entries End"

NIFI_ZK_CONNECT_STRING = os.getenv("NIFI_ZK_CONNECT_STRING")
if not NIFI_ZK_CONNECT_STRING:
    raise EnvironmentError("Variável NIFI_ZK_CONNECT_STRING não definida")

zk = KazooClient(hosts=NIFI_ZK_CONNECT_STRING)
zk.start()

def get_pods_list():
    if not zk.exists("/pods"):
        return []

    pods = zk.get_children("/pods")
    pods_data = []
    for pod in pods:
        pod_path = f"/pods/{pod}"
        try:
            d, _ = zk.get(pod_path)
            pods_data.append(d.decode("utf-8"))
        except Exception:
            pass
    return pods_data

def update_hosts_file(pod_lines):
    # Lê o /etc/hosts atual
    with open(HOSTS_FILE, "r") as f:
        lines = f.readlines()

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
        del lines[start_idx:end_idx+1]

    # Monta o novo bloco
    new_block = [START_MARKER + "\n"]
    for pod_line in pod_lines:
        parts = pod_line.split()
        if len(parts) < 3:
            continue
        pod_ip, pod_name, pod_fqdn = parts[0], parts[1], parts[2]
        new_block.append(f"{pod_ip}\t{pod_name}\t{pod_fqdn}\n")
    new_block.append(END_MARKER + "\n")

    lines.extend(["\n"])
    lines.extend(new_block)

    new_content = "".join(lines)

    # Sobrescreve /etc/hosts usando sudo tee
    subprocess.run(["sudo", "tee", HOSTS_FILE], input=new_content.encode(), check=True)

def main_loop():
    while True:
        pods_data = get_pods_list()
        if pods_data:
            update_hosts_file(pods_data)
            print(f"/etc/hosts atualizado com {len(pods_data)} pods")
        else:
            print("Nenhum pod encontrado em /pods no Zookeeper")
        time.sleep(30)

if __name__ == "__main__":
    try:
        main_loop()
    except KeyboardInterrupt:
        print("Finalizando")
    finally:
        zk.stop()
