#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kube_describe.sh
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
  print_red "Usage: $0 <pod_name>"
fi
pod_name="$1"
namespace=$("$(dirname "$0")/kg.sh" "$pod_name" | awk '{print $1}' | tr -d '\n')
if [ -z "$namespace" ]; then
  print_red "Error: Could not find namespace for pod $pod_name"
fi
kubectl describe pod "$pod_name" -n "$namespace" 