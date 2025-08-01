#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kdelall.sh
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
  print_red "Usage: $0 <pattern>"
fi
search_str="$1"
kubectl get pods --all-namespaces | grep "$search_str" | awk '{print $2,$1}' | while read pod namespace; do
  kubectl delete pod "$pod" -n "$namespace"
done 