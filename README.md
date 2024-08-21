### kubernetes更新证书
```javascript
cat /proc/cmdline | grep -q nokmem || (sed -i '/^GRUB_CMDLINE_LINUX=/ s/"$/ cgroup.memory=nokmem"/' /etc/default/grub && grub2-mkconfig --output=$(find /boot/ -name grub.cfg))
sed -i '/ swap /s/^/#/' /etc/fstab
kubectl describe svc -n kube-system                        mysql   #查看svc关注Endpoints:是后端的pod地址   Selector:匹配
kubectl get pods -A --selector=kubernetes.io/name=node1   #查看pod标签是否匹配svc
ssmctl check -c mysql -i mysql mysql-pod  #检查pod所有状态
kubectl edit ss -n kube-system        mysql-pod -o yaml    #edit 扩容pv
cat demo.txt |awk '{print $1":2181"}' |tr '\n' ',' | sed 's/,$//'  #列转换行命令.
kubectl  get podcidr -A  #查看网络地址
kubectl get ipr -A  #查看网络地址
dd if=/dev/zero of=/dev/sdb bs=512 count=1  #快速清空磁盘数据至裸盘.
./arcconf GETCONFIG 1 LD  #硬raid查看信息.
./storcli /c0/vall show all | grep -E "RAID|Onln" #硬raid查看信息.
jmap -heap $pid    #查看应用占用的cpu mem信息
awk -v a="node-" '{print a$1}' demo.txt  |sed 's/\./-/g'    #批量更改主机名
https://github.com/kubernetes-sigs/kubespray/blob/master/docs/mirror.md #KubeSpray 也支持 国内镜像加速了。
tcpdump -i any port 80 -s0 -A    #抓包命令
if [[ $(kubectl get pod -A | grep 0/1 | awk '{print $1,$2}' | wc -l) -gt 0 ]]; then kubectl get pod -A | grep 0/1 | awk '{print $1,$2}' | while read -r pod namespace; do kubectl delete pod "$namespace" -n "$pod"; done; fi  #删除异常的pod.
kubectl create job --from=cronjob/etcd etcd-$(date '+%Y%m%d%H%M') -n etcd   #定时执行job任务
tcpdump -i eth0 dst port 6443 -c 10000 | awk '{print $3}' | awk -F. -v OFS="." '{print $1,$2,$3,$4}' | sort | uniq -c | sort -nr #抓包
git clone  -c http.proxy="http://172.27.0.3:7890/" https://github.com/kubernetes-sigs/kubespray.git  #git使用代理
pip3 install --upgrade setuptools --proxy=http://172.27.0.3:7890/    #pip使用代理
export https_proxy=http://172.27.0.3:7890/ && helm repo update       #helm 使用代理
proxy=http://172.27.0.3:7890/                                        #vi /etc/yum.conf   yum使用代理
kubectl rollout restart deploy -n xxx  xxxx  #批量重启pod
kubectl get secret  -n metallb-system   memberlist  -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'      #快速查到sercet密码
sha256sum /root/kubeadm
kubectl api-resources  #api版本
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

docker build --build-arg http_proxy=http://192.168.197.21:7890/ --build-arg https_proxy=http://192.168.197.21:7890/ -t node:v2 .  #build构建镜像使用代理.

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

#这几步必做,使用local_volume_provisioner
mkdir -p /data/disks
DISK_UUID=$(blkid -s UUID -o value /dev/sdb)
sudo mkdir /data/disks/$DISK_UUID
sudo mount -t xfs /dev/sdb /data/disks/$DISK_UUID
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` /data/disks/$DISK_UUID xfs defaults 0 2 | sudo tee -a /etc/fstab   
#####

local_volume_provisioner_enabled: true
local_volume_provisioner_namespace: kube-system
local_volume_provisioner_nodelabels:
  - kubernetes.io/hostname
#   - topology.kubernetes.io/region
#   - topology.kubernetes.io/zone
local_volume_provisioner_storage_classes:
  local-storage:
    host_dir: /data/disks
    mount_dir: /data/disks
    volume_mode: Filesystem
    fs_type: xfs





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


metallb_enabled: true
metallb_speaker_enabled: "{{ metallb_enabled }}"
metallb_namespace: metallb-system
metallb_protocol: "layer2"
metallb_config:
  address_pools:
    primary:
      ip_range:
        - 172.27.0.7-172.27.0.9
      auto_assign: true
  layer2:
    - primary

kubectl patch ipaddresspools primary -n metallb-system --type='json' -p='[{"op": "replace", "path": "/spec/addresses/0", "value": "172.27.0.7-172.27.0.69"}]'
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
docker pull registry.k8s.io/build-image/kube-cross:v1.28.10-go1.21.9-bullseye.0   #新版本镜像名称改掉

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
