#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : kube_get_all_pods_wide.sh
# @Software: cursor

kubectl get pods --all-namespaces -o wide 