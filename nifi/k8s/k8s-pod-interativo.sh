#!/bin/bash

NAMESPACE=""

function escolher_namespace() {
    echo "Nenhum namespace informado. Selecione um namespace:"
    echo "-------------------------------------"
    mapfile -t namespaces < <(kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers)

    for i in "${!namespaces[@]}"; do
        echo "[$i] ${namespaces[$i]}"
    done

    read -p "Digite o número do namespace: " ns_index
    if [[ "$ns_index" =~ ^[0-9]+$ ]] && [ "$ns_index" -ge 0 ] && [ "$ns_index" -lt "${#namespaces[@]}" ]; then
        NAMESPACE="${namespaces[$ns_index]}"
        echo "✅ Namespace selecionado: $NAMESPACE"
    else
        echo "❌ Entrada inválida. Encerrando."
        exit 1
    fi
}


function listar_pods() {
    echo
    echo "Pods no namespace [$NAMESPACE]:"
    echo "-------------------------------------------"
    mapfile -t pod_lines < <(kubectl get pods -n "$NAMESPACE" --no-headers)

    if [ ${#pod_lines[@]} -eq 0 ]; then
        echo "❌ Nenhum pod encontrado."
        return
    fi

    pods=()  # Reinicia a lista de nomes de pod

    printf "%-5s %-40s %-15s\n" "ID" "NOME" "STATUS"
    echo "---------------------------------------------------------------------"
    for i in "${!pod_lines[@]}"; do
        pod_name=$(echo "${pod_lines[$i]}" | awk '{print $1}')
        pod_status=$(echo "${pod_lines[$i]}" | awk '{print $3}')
        pods+=("$pod_name")
        printf "[%2d] %-40s %-15s\n" "$i" "$pod_name" "$pod_status"
    done
}

function interagir_com_pod() {
    read -p "Escolha o número do pod ou Q para voltar: " choice

    if [[ "$choice" =~ ^[Qq]$ ]]; then
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "${#pods[@]}" ]; then
        pod_name="${pods[$choice]}"
        echo "Selecionado: $pod_name"
        echo "-----------------------------"
        echo "[1] Exec Bash"
        echo "[2] Ver Logs"
        echo "[3] Ver Logs em modo contínuo"        
        echo "[4] Describe Pod"
        echo "[Q] Voltar"
        read -p "Escolha a ação: " action

        case "$action" in
            1)
                kubectl exec -n "$NAMESPACE" -it "$pod_name" -- bash || kubectl exec -n "$NAMESPACE" -it "$pod_name" -- sh
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                kubectl logs -n "$NAMESPACE" "$pod_name"
                read -p "Pressione Enter para continuar..."
                ;;
            3)
                kubectl logs -f -n "$NAMESPACE" "$pod_name"
                read -p "Pressione Enter para continuar..."
                ;;                
            4)
                kubectl describe pod -n "$NAMESPACE" "$pod_name"
                read -p "Pressione Enter para continuar..."
                ;;
            [Qq])
                return
                ;;
            *)
                echo "Ação inválida."
                sleep 1
                ;;
        esac
    else
        echo "Entrada inválida."
        sleep 1
    fi
}

function listar_services() {
    echo
    mapfile -t services < <(kubectl get svc -n "$NAMESPACE" --no-headers | awk '{print $1}')

    echo "URLs via minikube (namespace: $NAMESPACE):"
    echo "-------------------------------------------"
    for svc in "${services[@]}"; do
        url=$(minikube service "$svc" -n "$NAMESPACE" --url 2>/dev/null)
        echo "$svc → $url"
    done
    echo
}

# Inicialização
clear
escolher_namespace

# Loop principal
while true; do
    clear
    listar_pods
    listar_services
    echo "[Q] Sair"
    echo

    interagir_com_pod

    read -p "Pressione Enter para atualizar a lista ou Q para sair: " again
    if [[ "$again" =~ ^[Qq]$ ]]; then
        break
    fi
done

