### kubernetes更新证书


### kubeadm编译好的版本md5sum
```javascript
09f0666263f0855f887ce722d81b9102  kubeadm-v1.20.6-amd64
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
