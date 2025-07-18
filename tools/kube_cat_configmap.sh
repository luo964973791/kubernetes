#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kube_cat_configmap.sh
# @Software: cursor

print_green() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

print_red() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
    exit 1
}

print_yellow() {
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [Warning] $*\e[01;00m"
}


if [ $# -lt 1 ]; then
  print_red "Usage: $0 <configmap_name>"
fi
configmap_name="$1"
namespace=$(kubectl get cm -A | grep "$configmap_name" | head -1 | awk '{print $1}')
if [ -z "$configmap_name" ] || [ -z "$namespace" ]; then
  print_red "Usage: $0 <configmap_name> <namespace>"
fi
kubectl get cm "$configmap_name" --output="go-template={{ range \$k,\$v := .data}}{{ \$v }}{{ end }}" -n "$namespace"
