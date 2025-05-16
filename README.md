# Arquitetura Kubernetes: NiFi + NiFi Registry + ZooKeeper + Armazenamento (Ceph e Disco Local)

## 🔹 ZooKeeper

- **Pods**: 1 (não recomendado para produção, mas válido para testes)
- **Volume montado**:
  - `/data` → PVC com **disco local**
- **Uso**: Coordenação e eleição de cluster do NiFi

---

## 🔹 NiFi Registry

- **Pods**: 1
- **Volume montado**:
  - `/opt/nifi-registry/data` → PVC com **disco local**
- **Uso**: Armazenamento de versões de fluxos (flow versions)

---

## 🔹 NiFi Cluster

- **Pods**: múltiplos (ex: `nifi-0`, `nifi-1`, `nifi-2`, ...)
- **Volumes montados por pod**:

| Caminho no Pod                               | Tipo de Volume          | Uso                                                             |
|---------------------------------------------|--------------------------|------------------------------------------------------------------|
| `/opt/nifi/nifi-current/state`              | PVC com **Ceph**         | Sincronização de estado entre nós do cluster                     |
| `/opt/nifi/nifi-current/conf`               | **ConfigMap** ou Ceph    | Arquivos de configuração compartilhada                          |
| `/opt/nifi/nifi-current/content_repository` | PVC com **disco local**  | Armazena conteúdo dos flowfiles temporariamente                 |
| `/opt/nifi/nifi-current/flowfile_repository`| PVC com **disco local**  | Metadados sobre os flowfiles                                    |
| `/opt/nifi/nifi-current/provenance_repository` | PVC com **disco local** | Dados de rastreamento de eventos no fluxo                       |
| `/opt/nifi/nifi-current/database_repository`  | PVC com **disco local** | Dados do repositório de estado do processador                   |

---

## 🔹 Armazenamento Externo

- **Ceph**:
  - Utilizado para compartilhamento entre pods (RWX), especialmente:
    - `/state`
    - (opcionalmente) `/conf`
- **Disco local**:
  - Utilizado por cada pod individualmente (RWX não é necessário):
    - `content_repository`
    - `flowfile_repository`
    - `provenance_repository`
    - `database_repository`
