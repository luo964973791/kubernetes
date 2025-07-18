# kdescribe
kdescribe <pod_name>
# describe 指定 Pod（自动查找命名空间）

# kexec
kexec <pod_name>
# 进入指定 Pod 的 shell（自动查找命名空间）

# kdelpod
kdelpod <pod_name>
# 删除指定 Pod（自动查找命名空间）

# kgrepsvc
kgrepsvc <pod_name>
# 查找与指定 Pod 相关的 Service

# kgrepsecret
kgrepsecret <secret_name>
# 查看指定 Secret 的内容（自动查找命名空间，自动 base64 解码）

# kbox
kbox
# 运行一个临时 busybox 容器进行测试

# klog
klog <pod_name>
# 查看指定 Pod 的日志（自动查找命名空间）

# kmanager
kmanager <pattern>
# 查找所有命名空间下包含指定名称的 Pod

# kcatcm
kcatcm <configmap_name>
# 查看指定 ConfigMap 的内容（自动查找命名空间）

# keditcm
keditcm <configmap_name>
# 编辑指定 ConfigMap（自动查找命名空间，编辑后自动 apply）

# kgrepcm
kgrepcm <configmap_name>
# 查找所有命名空间下包含指定名称的 ConfigMap

# kdelall
kdelall <pattern>
# 批量删除所有命名空间下名称匹配 pattern 的 Pod