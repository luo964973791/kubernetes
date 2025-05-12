#!/bin/bash

echo_green() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

echo_red() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
}

echo_yellow() {
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [Warning] $*\e[01;00m"
}

info() {
    echo_yellow "Please refer to the following examples for implementation!"
    echo_yellow "e                   Examples: source k e 192.168.100.135"
    echo_yellow "box                 Examples: k box"
    echo_yellow "exec                Examples: k exec kube-system  nodelocaldns sh/orbash"
    echo_yellow "cm                  Examples: k cm  metallb-system config"
    echo_yellow "edit_cm             Examples: k edit_cm kube-system coredns"
    echo_yellow "sc                  Examples: k sc  metallb-system   memberlist"
    echo_yellow "scale               Examples: k scale  kube-system coredns 3"
    echo_yellow "etcdbak             Examples: k etcdbak https://{etcd-server}:2379"
    echo_yellow "in                  Examples: k in pid"
    echo_yellow "ssl                 Examples: k ssl"
    echo_yellow "dns                 Examples: k dns"
    echo_yellow "del                 Examples: k del"
}

check_binary() {
    if ! command -v "$1" &> /dev/null; then
        echo_red "ERROR" "$1 binary file not be found. Installing..."

        # 使用 yum 安装
        sudo yum install -y "$1"

        # 再次检查是否安装成功
        if ! command -v "$1" &> /dev/null; then
            echo_red "ERROR" "Failed to install $1. Please install it manually."
            exit 1
        else
            echo_green "SUCCESS" "$1 installed successfully."
        fi
    fi
}

pod_api()
{
    [[ $? -eq 0 ]] || {
        echo_red "Failure to login in to pod!"
        exit 1
    }
    echo_green "Logouts to pod successful!"
}

exec_pod() {
    check_binary kubectl
    if [[ -n $1 && -n $2 && -n $3 ]];then
        num=no
        all_pod=$(kubectl get pod -n "$1" | grep "$2"|nl|awk '$1=$1')
        total_pod=$(kubectl get pod -n "$1" | grep "$2"|nl|awk '$1=$1'|wc -l)
        echo_green "$all_pod"
        read -rp "Please enter the number?(1 to $total_pod):" num
        sleep 1
        if [[ "$num" == 1 ]]; then
            pod_name=$(kubectl get pod -n "$1" | grep "$2" | nl | awk '($1==1){print $2}')
            kubectl exec -it -n "$1" "$pod_name" -- "$3"
            pod_api
        elif [[ "$num" == 2 ]];then
            pod_name=$(kubectl get pod -n "$1" | grep "$2" | nl | awk '($1==2){print $2}')
            kubectl exec -it -n "$1" "$pod_name" -- "$3"
            pod_api
        elif [[ "$num" == 3 ]];then
            pod_name=$(kubectl get pod -n "$1" | grep "$2" | nl | awk '($1==3){print $2}')
            kubectl exec -it -n "$1" "$pod_name" -- "$3"
            pod_api
        else
            echo_red "Wrong number entered, please enter (1 to $total_pod)!"
        fi
    else
        echo_red "Check pod first second third parameter not present!"
        info
        exit 1
    fi
}

use_http_proxy() {
    if [[ -n $2 ]];then
        export https_proxy=http://$2:7890/
        local cmd_proxy=$?
        if [[ $cmd_proxy -eq 0 ]];then
            echo_green "Using a proxy successfully!"
            return 0
        fi
        echo_red "Failed to use proxy!"
        return 1
    else
        echo_red "Check https_proxy The first parameter is not present!"
        info
        exit 1
    fi
}

busybox() {
    check_binary kubectl
    kubectl run dns-test -it --rm --image=busybox:1.28.3 -- sh
    local busybox_res=$?
    if [[ $busybox_res -eq 0 ]];then
        echo_green "The busybox container was delete successfully"
        return 0
    fi
    echo_red "busybox container creation failed"
    return 1
}

k8s_cm() {
    check_binary kubectl
    if [[ -n $1 && -n $2 ]];then
        kubectl get cm -n "$1" "$2" --output="go-template={{ range \$k,\$v := .data}}{{ printf \"%s: \" \$k }}{{ if not \$v }}{{ \$v }}{{ else }}{{ \$v }}{{ end }}{{ "'"\n"'" }}{{ end }}"
        local cm_shell=$?
        if [[ $cm_shell -eq 0 ]];then
            echo_green "View Configmap success"
            return 0
        fi
        echo_red "Failed to view profile"
        return 1
    else
        echo_red "Check configmap The first and second parameter is not present!"
        info
        exit 1
    fi
}

k8s_secret() {
    check_binary kubectl
    if [[ -n $1 && -n $2 ]];then
        kubectl get secret -n "$1" "$2" --output="go-template={{ range \$k,\$v := .data}}{{ printf \"%s: \" \$k }}{{ if not \$v }}{{ \$v }}{{ else }}{{ \$v | base64decode }}{{ end }}{{ "'"\n"'" }}{{ end }}"
        local secret_shell=$?
        if [[ $secret_shell -eq 0 ]];then
            echo_green "base64 decryption successful!"
            return 0
        fi
        echo_red "base64 decryption failure!"
        return 1
    else
        echo_red "Check secret The first and second parameter is not present!"
        info
        exit 1
    fi
}

k8s_scale() {
    check_binary kubectl
    if [[ -n $1 && -n $2 && -n $3 ]];then
        kubectl scale deployments -n "$1" "$2" --replicas="$3"
        local scale_shell=$?
        if [[ $scale_shell -eq 0 ]];then
            echo_green "Successful expansion and reduction of capacity!"
            return 0
        fi
        echo_red "Failure to expand and reduce capacity!"
        return 1
    else
        echo_red "Check scale The first and second parameter is not present!"
        info
        exit 1
    fi
}

etcd_bak() {
    local leader
    local res
    leader=$(ETCDCTL_API=3 etcdctl --endpoints="$1" --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/member-node1.pem --key=/etc/ssl/etcd/ssl/member-node1-key.pem endpoint status --write-out table | grep true | awk '{print $2}')
    ETCDCTL_API=3 etcdctl --endpoints="$leader"  --cert="/etc/ssl/etcd/ssl/member-node1.pem"  --key="/etc/ssl/etcd/ssl/member-node1-key.pem"  --cacert="/etc/ssl/etcd/ssl/ca.pem"   snapshot save /tmp/snap-"$(date +%Y%m%d%H%M)".db >/dev/null 2>&1
    res=$?
    [[ $res -eq 0 ]] || {
        echo_red "Backup of etcd data failed!"
        #mail_api "$(date "+%Y-%m-%d %H:%M:%S")" [ERROR] crontab定时任务备份etcd数据失败"  #邮箱api接口
        exit 1
    }
    echo_green "Backup of etcd data successful!"
}

nsenter_cmd() {
    if  [[ $(systemctl status kubelet | grep -q "dockerd.sock") -eq 0 ]]; then
        res=$(docker inspect -f "{{.State.Pid}}" "$1")
        nsenter -n --target "$res"
        pod_api
    else
        res=$(crictl inspect --output go-template --template "{{.info.pid}}" "$1")
        nsenter -n --target "$res"
        pod_api
    fi
}


kubeadm_ssl() {
    [[ $(kubeadm certs check-expiration >/dev/null 2>&1) -eq 0 ]] || {
        echo_red "Query certificate validity failure!"
    }
    echo_green "$(kubeadm certs check-expiration)"
    echo_green "Check the certificate validity successfully!"
}


dns_demo() {
    (command -v dig && echo_green "dig command is installed!") || sudo yum install -y bind-utils || echo_red "Unable to install dig, please install it manually."
    for dns_server in $(kubectl describe svc -n kube-system coredns | awk '/Endpoints:/ {print $2}' | head -n 1 | sed 's/:53,*/ /g'); do
        if dig @"$dns_server" "$1" |grep -q "status: NOERROR"  &> /dev/null; then
            echo_green "The $1 is successfully resolved on the $dns_server!"
        else
            echo_red "$1 resolved failed on $dns_server!"
        fi
    done
}


delete_pod() {
    kubectl get pod -A | grep -Ev 'NAME|1/1|2/2|3/3|Completed' | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n
}

k8s_cm_edit()
{
    check_binary kubectl
    if [[ -n $1 && -n $2 ]];then
        local temp_file="/tmp/${2}.yaml"

        # Export current ConfigMap to a temporary file
        kubectl get configmap -n "$1" "$2" -o yaml | \
        grep -v "kubectl.kubernetes.io/last-applied-configuration" | \
        grep -v "creationTimestamp" | \
        grep -v "resourceVersion" | \
        grep -v "uid" | \
        grep -v "selfLink" | \
        grep -v "generation" | \
        grep -v "managedFields" | \
        grep -v "annotations" > "$temp_file"

        if [ $? -ne 0 ]; then
            echo_red "Failed to get ConfigMap $2"
            return 1
        fi

        # Open the file in the default editor
        ${EDITOR:-vi} "$temp_file"

        # Replace the ConfigMap
        echo_yellow "Updating ConfigMap..."
        kubectl replace -f "$temp_file"
        local replace_status=$?

        # Clean up
        rm -f "$temp_file"

        if [ $replace_status -eq 0 ]; then
            echo_green "Edit Configmap success"
            return 0
        else
            echo_red "Failed to update ConfigMap"
            return 1
        fi
    else
        echo_red "Check configmap edit The first and second parameter is not present!"
        info
        exit 1
    fi
}

IN=$1
case $IN in
    box)
        busybox
        ;;
    e)
        use_http_proxy "$@"
        ;;
    cm)
        k8s_cm "$2" "$3"
        ;;
    edit_cm)
        k8s_cm_edit "$2" "$3"
        ;;
    exec)
        exec_pod "$2" "$3" "$4"
        ;;
    sc)
        k8s_secret "$2" "$3"
        ;;
    scale)
        k8s_scale "$2" "$3" "$4"
        ;;
    in)
        nsenter_cmd "$2"
        ;;
    etcdbak)
        etcd_bak "$2"
        ;;
    ssl)
        kubeadm_ssl
        ;;
    dns)
        dns_demo "$2"
        ;;
    del)
        delete_pod
        ;;
    *)
        info
        ;;
esac
