#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kube_edit_configmap.sh
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
if [ -z "$configmap_name" ]; then
  print_red "Configmap $configmap_name not found"
fi

if command -v mktemp >/dev/null 2>&1; then
  temp_file=$(mktemp "/tmp/${configmap_name}.yaml.XXXXXX")
else
  temp_file="/tmp/${configmap_name}.yaml.$$"
fi

if ! kubectl get configmap -n "$namespace" "$configmap_name" -o yaml | \
  grep -v "^  creationTimestamp:" | \
  grep -v "^  resourceVersion:" | \
  grep -v "^  uid:" | \
  grep -v "^  selfLink:" | \
  grep -v "^  generation:" > "$temp_file"
then
  rm -f "$temp_file"
  print_red "Failed to get ConfigMap $configmap_name"
fi

${EDITOR:-vi} "$temp_file"

print_yellow "Updating ConfigMap..."
kubectl replace -f "$temp_file"
replace_status=$?
rm -f "$temp_file"

if [ $replace_status -eq 0 ]; then
  print_green "Edit ConfigMap success"
else
  print_red "Failed to update ConfigMap"
fi
