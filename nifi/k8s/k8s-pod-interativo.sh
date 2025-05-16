#!/bin/bash

function listar_pods() {
    echo "Pods em execução no namespace atual:"
    echo "-------------------------------------"
    mapfile -t pods < <(kubectl get pods --field-selector=status.phase=Running -o custom-columns=NAME:.metadata.name --no-headers)

    if [ ${#pods[@]} -eq 0 ]; then
        echo "Nenhum pod em execução encontrado."
        return
    fi

    for i in "${!pods[@]}"; do
        echo "[$i] ${pods[$i]} "
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
        echo "[3] Describe Pod"
        echo "[Q] Voltar"
        read -p "Escolha a ação: " action

        case "$action" in
            1)
                kubectl exec -it "$pod_name" -- bash || kubectl exec -it "$pod_name" -- sh
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                kubectl logs "$pod_name"
                read -p "Pressione Enter para continuar..."
                ;;
            3)
                kubectl describe pod "$pod_name"
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
    mapfile -t services < <(kubectl get svc --no-headers | awk '{print $1}')
    
    echo "URLs via minikube:"
    echo "----------------------"
    for svc in "${services[@]}"; do
        url=$(minikube service "$svc" --url 2>/dev/null)
        echo "$svc → $url"
    done
    echo
}

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

