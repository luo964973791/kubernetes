### kubernetes更新证书


### kubeadm编译好的版本md5sum
```javascript
361430aaf1ab567355842f354a5cda4f  kubeadm-1.19.7
184c0d5ed36a2bdf04a8929c81602022  kubeadm-1.19.5
e0a6d009f471d4f0d1eb598517a7d473  kubeadm-1.19.4
00a7f4be3c1fc5cfcd3136a5772c1932  kubeadm-1.19.3
16c8e1e3826cc2990e57b71ad5273aa8  kubeadm-1.19.2
56e56853900be7e2db91a82944635f55  kubeadm-1.19.1
13ffd6c149400835da0da4b8fc38a808  kubeadm-1.19.0 
19a55eec4e948916186f748d484c827c  kubeadm-1.18.8
c1a1c52836eb947b91457722c56e0e31  kubeadm-1.17.9
cd465e2d32f03910a5f2c65c33e0f4e7  kubeadm-1.16.7
```


```javascript
cd /root && wget https://github.com/kubernetes/kubernetes/archive/v1.18.8.tar.gz && tar zxvf v1.18.8.tar.gz
cd kubernetes-1.18.8
```

### 修改CA文件为100年

```javascript
cd kubernetes-1.18.8 && vi ./staging/src/k8s.io/client-go/util/cert/cert.go
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

### 对比文件

```javascript
git diff
```

![./image/3.png](./image/3.png)

### 检查kube-cross版本

```javascript
#pull 镜像
docker pull us.gcr.io/k8s-artifacts-prod/build-image/kube-cross:v1.13.15-1

#启动容器
docker run --rm -v /root/kubernetes-1.18.8:/go/src/k8s.io/kubernetes -it us.gcr.io/k8s-artifacts-prod/build-image/kube-cross:v1.13.15-1 bash

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
cd /root/kubernetes-1.18.8
cp _output/local/bin/linux/amd64/kubeadm /usr/local/bin/kubeadm
```

### 检查证书

![./image/8.png](./image/8.png)
