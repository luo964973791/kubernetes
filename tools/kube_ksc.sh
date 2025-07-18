#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kube_ksc.sh
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
  print_red "Usage: $0 <secret_name>"
fi
secret_name=$1
namespace=$(kubectl get secret -A | grep "$secret_name" | awk '{print $1}')
if [ -z "$namespace" ]; then
  print_red "Error: Could not find namespace for secret $secret_name"
fi
kubectl get secret -n "$namespace" "$secret_name" --output="go-template={{ range \$k,\$v := .data}}{{ printf \"%s: \" \$k }}{{ if not \$v }}{{ \$v }}{{ else }}{{ \$v | base64decode }}{{ end }}{{ '\n' }}{{ end }}" 
