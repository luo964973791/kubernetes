### kubernetes更新证书
```javascript
sed -e "s/\./-/g" -e "s/^/k8s-/g"  test
sed -e "s/k8s-//g" -e "s/-/./g" test
sha256sum /root/kubeadm
/root/kubespray/roles/download/defaults/main.yml  #更改main.yml里面kubeadm的sha256sum值.
vi kubespray/roles/download/defaults/main.yml
download_run_once: true    #只下载一次镜像，其它的机器同步.
download_force_cache: true #只下载一次镜像，其它的机器同步.
/usr/local/bin/nerdctl -n k8s.io image save -o /tmp/releases/images/registry.k8s.io_kube-proxy_v1.24.2.tar registry.k8s.io/kube-proxy:v1.24.2
/usr/local/bin/nerdctl -n k8s.io image load < /tmp/releases/images/registry.k8s.io_kube-proxy_v1.24.2.tar
/usr/local/bin/nerdctl -n k8s.io pull --quiet  registry.k8s.io/kube-proxy:v1.24.2
#etcd查看容量
export ETCDCTL_API=3
etcdctl --endpoints=https://192.168.100.111:2379,https://192.168.100.112:2379,https://192.168.100.113:2379 --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/member-node1.pem --key=/etc/ssl/etcd/ssl/member-node1-key.pem endpoint status --write-out table

cat /root/kubespray/inventory/mycluster/group_vars/all/all.yml | grep http_proxy
http_proxy: "http://172.27.0.5:8118/"    #使用代理.
https_proxy: "https://172.27.0.5:8118/"  #使用代理.

ceph osd pool create kube 1024
ceph osd pool init kube
ceph auth get-or-create client.kube mon 'allow r, allow command "osd blacklist"' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kube' -o ceph.client.kube.keyring
ceph auth get-key client.admin
ceph auth get-key client.kube

rbd_provisioner_enabled: true
rbd_provisioner_namespace: rbd-provisioner
rbd_provisioner_replicas: 2
rbd_provisioner_monitors: "172.27.0.3:6789,172.27.0.4:6789,172.27.0.5:6789"
rbd_provisioner_pool: kube
rbd_provisioner_admin_id: admin
rbd_provisioner_secret_name: ceph-secret-admin
rbd_provisioner_secret: AQA5K0RiMQS/HhAAXeamoqPYM04jLGmot3bCUg==
rbd_provisioner_user_id: kube
rbd_provisioner_user_secret_name: ceph-secret-user
rbd_provisioner_user_secret: AQDMBkViv7cdBRAA6tH23yfjl1/bWJbP2+e1TQ==
rbd_provisioner_user_secret_namespace: rbd-provisioner
rbd_provisioner_fs_type: ext4
rbd_provisioner_image_format: "2"
rbd_provisioner_image_features: layering
rbd_provisioner_storage_class: rbd
rbd_provisioner_reclaim_policy: Delete



kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: claim1
spec:
  storageClassName: rbd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
	  
	  
kind: Pod
apiVersion: v1
metadata:
  name: task-pv-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
       claimName: claim1
  containers:
    - name: task-pv-container
      image: portus.teligen.com:5000/kubesprayns/nginx:1.13
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible.md
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml -b -v   --tags=rbd-provisioner  #按照tags进行按照部分插件.
```

### kubeadm编译好的版本sha256sum
```javascript
a85c3d93c3d4820e38e631310d3a34b0b30b596b77b54857a5d96de048795707 kubeadm-v1.23.1-amd64
d48216dfd42fa5db91b0662dc76d1051236a8bc77dc5c6565db00a1006714041 kubeadm-1.25.0-amd
```


```javascript
cd /root && wget https://github.com/kubernetes/kubernetes/archive/v1.19.7.tar.gz && tar zxvf v1.19.7.tar.gz
kubectl get pod -A | grep Terminated | awk '{print "kubectl delete pod " $2 " -n" $1}'|bash #批量删除
cat docker-images.txt | xargs -I{} -n 1 -P 10 docker pull {}
kubectl get pod -A | grep -P 'kube-system|rook-ceph' #过滤.
cd kubernetes-1.19.7
```

### 修改CA文件为100年

```javascript
cd kubernetes-1.19.7 && vi ./staging/src/k8s.io/client-go/util/cert/cert.go
```

![./image/1.png](./image/1.png)

### 修改证书为100年

```javascript
vi ./cmd/kubeadm/app/constants/constants.go
```

![./image/2.png](./image/2.png)

### 修改GitTreeState版本信息

```javascript
vi hack/lib/version.sh
```

![./image/7](./image/7.png)

### 检查kube-cross版本

```javascript
#pull 镜像
cat /root/kubernetes-1.19.7/build/build-image/cross/VERSION
docker pull us.gcr.io/k8s-artifacts-prod/build-image/kube-cross:v1.15.5-1

#启动容器
docker run --rm -v /root/kubernetes-1.19.7:/go/src/k8s.io/kubernetes -it us.gcr.io/k8s-artifacts-prod/build-image/kube-cross:v1.15.5-1 bash

#进入目录
cd /go/src/k8s.io/kubernetes
#编译
make all WHAT=cmd/kubeadm GOFLAGS=-v
#退出容器
exit
```

![./image/4.png](./image/4.png)

### 备份本地kubeadm.

```javascript
whereis kubeadm
mv /usr/local/bin/kubeadm /usr/local/bin/kubeadm_bak
cd /root/kubernetes-1.19.7
cp _output/local/bin/linux/amd64/kubeadm /usr/local/bin/kubeadm
```

### 检查证书

```javascript
kubeadm certs check-expiration
```
