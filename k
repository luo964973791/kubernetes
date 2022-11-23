#!/bin/bash
echo_green()
{
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}
echo_red()
{
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
}
echo_yellow()
{
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [Warning] $*\e[01;00m"
}
info()
{
    echo_yellow "Please refer to the following examples for implementation!"
    echo_yellow "e                   Examples: source k e 192.168.100.135"
    echo_yellow "box                 Examples: k box"
    echo_yellow "exec                Examples: k exec kube-system  nodelocaldns sh/orbash"
    echo_yellow "cm                  Examples: k cm  metallb-system config"
    echo_yellow "sc                  Examples: k sc  metallb-system   memberlist"
    echo_yellow "scale               Examples: k scale  kube-system coredns 3"
    echo_yellow "in                  Examples: k in pid"
}

check_binary()
{
    if ! [ -x "$(command -v "$1")" ]; then
       echo_red "ERROR" "$1 binary file not be found."
       exit 1
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

exec_pod()
{
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

use_http_proxy()
{
    if [[ -n $2 ]];then
        echo "export https_proxy=http://$2:7890/"
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

busybox()
{
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
k8s_cm()
{
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
k8s_secret()
{
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

k8s_scale()
{
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

nsenter_cmd()
{
    [[ $(kubectl get node -o wide | grep -q "docker") -eq 0 ]] || {
        res=$(docker inspect -f "{{.State.Pid}}" "$1")
        nsenter -n --target "$res"
        pod_api
    }
    res=$(crictl inspect --output go-template --template "{{.info.pid}}" "$1")
    nsenter -n --target "$res"
    pod_api
    
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
    *)
        info
        ;;
esac
