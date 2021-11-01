# 一、什么是控制器

kubernetes中内建了很多controller（控制器），这些相当于一个状态机，用来控制pod的具体状态和行为。

部分控制器类型如下：
ReplicationController 和 ReplicaSet
Deployment
DaemonSet
StatefulSet
Job/CronJob
HorizontalPodAutoscaler

## 二、DaemonSet控制器

```
DaemonSet 确保全部（或者某些）节点上运行一个 Pod 的副本。当有节点加入集群时，会为他们新增一个 Pod。当有节点从集群移除时，这些 Pod 也会被回收。删除 DaemonSet 将会删除它创建的所有 Pod。

DaemonSet 的一些典型用法：
在每个节点上运行集群存储 DaemonSet，例如 glusterd、ceph。
在每个节点上运行日志收集 DaemonSet，例如 fluentd、logstash。
在每个节点上运行监控 DaemonSet，例如 Prometheus Node Exporter、Flowmill、Sysdig 代理、collectd、Dynatrace OneAgent、AppDynamics 代理、Datadog 代理、New Relic 代理、Ganglia gmond 或者 Instana 代理。
一个简单的用法是在所有的节点上都启动一个 DaemonSet，并作为每种类型的 daemon 使用。

一个稍微复杂的用法是单独对每种 daemon 类型使用一种DaemonSet。这样有多个 DaemonSet，但具有不同的标识，并且对不同硬件类型具有不同的内存、CPU 要求。
```

------------------------------------------------
备注：DaemonSet 中的 Pod 可以使用 hostPort，从而可以通过节点 IP 访问到 Pod；因为DaemonSet模式下Pod不会被调度到其他节点。使用示例如下：

```yaml
 ports:
    - name: httpd
      containerPort: 80
      #除非绝对必要，否则不要为 Pod 指定 hostPort。 将 Pod 绑定到hostPort时，它会限制 Pod 可以调度的位置数；DaemonSet除外
      #一般情况下 containerPort与hostPort值相同
      hostPort: 8090     #可以通过宿主机+hostPort的方式访问该Pod。例如：pod在/调度到了k8s-node02			                      【192.168.153.147】，那么该Pod可以通过192.168.153.147:8090方式进行访问。
      protocol: TCP
```

下面举个栗子：

##### 1.创建DaemonSet

DaemonSet的描述文件和Deployment非常相似，只需要修改Kind，并去掉副本数量的配置即可

当然，我们这里的pod运行的是nginx，作为案例；

```
[root@k8s-master daemonset]# cat nginx-daemonset.yml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-daemonset
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - name: nginx
          containerPort: 80
          hostPort: 8090
          protocol: TCP
```

![image-20210922151929582](assets/image-20210922151929582.png)

##### 2.测试效果

用宿主机的ip+8090端口，即可访问到：

![image-20210922152257127](assets/image-20210922152257127.png)

![image-20210922152612016](assets/image-20210922152612016.png)

下面来看DaemonSet的效果；

也可以看到，每个node上，都会有一个DaemonSet的pod

![image-20210922152018783](assets/image-20210922152018783.png)

尝试删除，也会重建

```shell
[root@k8s-master daemonset]# kubectl delete pod nginx-daemonset-5trrn
```

![image-20210922152203320](assets/image-20210922152203320.png)

## 三、StatefulSet控制器

本次实验基于k8s-v1.19.0版本

![image-20211004151154033](assets/image-20211004151154033.png)

StatefulSet 是用来管理有状态应用的工作负载 API 对象。

StatefulSet 中的 Pod 拥有一个具有黏性的、独一无二的身份标识。这个标识基于 StatefulSet 控制器分配给每个 Pod 的唯一顺序索引。Pod 的名称的形式为<statefulset name>-<ordinal index> 。例如：web的StatefulSet 拥有两个副本，所以它创建了两个 Pod：web-0和web-1。

和 Deployment 相同的是，StatefulSet 管理了基于相同容器定义的一组 Pod。但和 Deployment 不同的是，StatefulSet 为它们的每个 Pod 维护了一个固定的 ID。这些 Pod 是基于相同的声明来创建的，但是不能相互替换：无论怎么调度，每个 Pod 都有一个永久不变的 ID。

【使用场景】StatefulSets 对于需要满足以下一个或多个需求的应用程序很有价值：

1.  稳定的、唯一的网络标识符，即Pod重新调度后其PodName和HostName不变【当然IP是会变的】

2.  稳定的、持久的存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC实现

3. 有序的、优雅的部署和缩放

4. 有序的、自动的滚动更新

   如上面，稳定意味着 Pod 调度或重调度的整个过程是有持久性的。

如果应用程序不需要任何稳定的标识符或有序的部署、删除或伸缩，则应该使用由一组无状态的副本控制器提供的工作负载来部署应用程序，比如使用 Deployment 或者 ReplicaSet 可能更适用于无状态应用部署需要。

### 1.限制

给定 Pod 的存储必须由 PersistentVolume 驱动 基于所请求的 storage class 来提供，或者由管理员预先提供。
删除或者收缩 StatefulSet 并不会删除它关联的存储卷。这样做是为了保证数据安全，它通常比自动清除 StatefulSet 所有相关的资源更有价值。
StatefulSet 当前需要 headless 服务 来负责 Pod 的网络标识。你需要负责创建此服务。
当删除 StatefulSets 时，StatefulSet 不提供任何终止 Pod 的保证。为了实现 StatefulSet 中的 Pod 可以有序和优雅的终止，可以在删除之前将 StatefulSet 缩放为 0。
在默认 Pod 管理策略(OrderedReady) 时使用滚动更新，可能进入需要人工干预才能修复的损坏状态。
有序索引
对于具有 N 个副本的 StatefulSet，StatefulSet 中的每个 Pod 将被分配一个整数序号，从 0 到 N-1，该序号在 StatefulSet 上是唯一的。

StatefulSet 中的每个 Pod 根据 StatefulSet 中的名称和 Pod 的序号来派生出它的主机名。组合主机名的格式为$(StatefulSet 名称)-$(序号)。

### 2.部署和扩缩保证

对于包含 N 个 副本的 StatefulSet，当部署 Pod 时，它们是依次创建的，顺序为 0~(N-1)。
当删除 Pod 时，它们是逆序终止的，顺序为 (N-1)~0。
在将缩放操作应用到 Pod 之前，它前面的所有 Pod 必须是 Running 和 Ready 状态。
在 Pod 终止之前，所有的继任者必须完全关闭。
StatefulSet 不应将 pod.Spec.TerminationGracePeriodSeconds 设置为 0。这种做法是不安全的，要强烈阻止。

### 3.部署顺序

在下面的 nginx 示例被创建后，会按照 web-0、web-1、web-2 的顺序部署三个 Pod。在 web-0 进入 Running 和 Ready 状态前不会部署 web-1。在 web-1 进入 Running 和 Ready 状态前不会部署 web-2。

如果 web-1 已经处于 Running 和 Ready 状态，而 web-2 尚未部署，在此期间发生了 web-0 运行失败，那么 web-2 将不会被部署，要等到 web-0 部署完成并进入 Running 和 Ready 状态后，才会部署 web-2。

### 4.收缩顺序

如果想将示例中的 StatefulSet 收缩为 replicas=1，首先被终止的是 web-2。在 web-2 没有被完全停止和删除前，web-1 不会被终止。当 web-2 已被终止和删除；但web-1 尚未被终止，如果在此期间发生 web-0 运行失败，那么就不会终止 web-1，必须等到 web-0 进入 Running 和 Ready 状态后才会终止 web-1。

### 5.项目实战

提前说明：由于本地动态实战，我在v1.22.2版本中，尝试多次未成功，采用了v1.19.0版本的k8s集群；

![image-20211004095455915](assets/image-20211004095455915.png)

Dynamic Provisioning机制工作的核心在于StorageClass的API对象。
StorageClass声明存储插件，用于自动创建PV

![image-20211004095551788](assets/image-20211004095551788.png)

当我们k8s业务上来的时候，大量的pvc,此时我们人工创建匹配的话，工作量就会非常大了，需要动态的自动挂载相应的存储，‘
我们需要使用到StorageClass，来对接存储，靠他来自动关联pvc,并创建pv。
Kubernetes支持动态供给的存储插件：
https://kubernetes.io/docs/concepts/storage/storage-classes/
因为NFS不支持动态存储，所以我们需要借用这个存储插件。
nfs动态相关部署可以参考：
https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client/deploy
部署步骤：

#### 5.1部署nfs

```shell
3个节点都下载：
# yum -y install nfs-utils rpcbind
主节点配置nfs服务端
[root@master pvc-test]# mkdir /opt/container_data
[root@master pvc-test]# chmod 777  -R /opt/container_data
[root@master pvc-test]# cat /etc/exports
/opt/container_data *(rw,no_root_squash,no_all_squash,sync)
[root@master pvc-test]# systemctl start rpcbind && systemctl start nfs
```

#### 5.2定义一个storage

```shell
[root@master pvc-test]# cat storageclass-nfs.yaml 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs
```

#### 5.3部署授权

因为storage自动创建pv需要经过kube-apiserver,所以要进行授权

创建1个sa

创建1个clusterrole，并赋予应该具有的权限，比如对于一些基本api资源的增删改查；

创建1个clusterrolebinding，将sa和clusterrole绑定到一起；这样sa就有权限了；

然后pod中再使用这个sa，那么pod再创建的时候，会用到sa，sa具有创建pv的权限，便可以自动创建pv；

```shell
[root@master pvc-test]# cat rbac.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
---

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
```

#### 5.4部署一个自动创建pv的服务

这里自动创建pv的服务由nfs-client-provisioner 完成

```
[root@master pvc-test]# cat deployment-nfs.yaml 
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  selector:
    matchLabels:
      app: nfs-client-provisioner
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
    #  imagePullSecrets:
    #    - name: registry-pull-secret
      serviceAccount: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          #image: quay.io/external_storage/nfs-client-provisioner:latest
          image: lizhenliang/nfs-client-provisioner:v2.0.0
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              #这个值是定义storage里面的那个值
              value: fuseim.pri/ifs
            - name: NFS_SERVER
              value: 172.17.0.21
            - name: NFS_PATH
              value: /opt/container_data
      volumes:
        - name: nfs-client-root
          nfs:
            server: 172.17.0.21
            path: /opt/container_data

```

创建：

```shell
[root@master pvc-test]# kubectl apply -f storageclass-nfs.yaml
[root@master pvc-test]# kubectl apply -f rbac.yaml
[root@master pvc-test]# kubectl apply -f deployment-nfs.yaml
```

查看创建好的storage:

```shell
[root@master storage]# kubectl get sc
```

![image-20211004152919525](assets/image-20211004152919525.png)

nfs-client-provisioner 会以pod运行在k8s中，

```shell
[root@master storage]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-855887f688-hrdwj   1/1     Running   0          77s
```

4、部署有状态服务，测试自动创建pv
部署yaml文件参考：https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/
我们部署一个nginx服务，让其html下面自动挂载数据卷，

```shell
[root@master pvc-test]# cat nginx.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
   matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "managed-nfs-storage"
      resources:
        requests:
          storage: 1Gi
          
[root@master pvc-test]# kubectl apply -f nginx.yaml
```

#### 5.5有序创建的特性

![image-20211004153024783](assets/image-20211004153024783.png)

![image-20211004153101887](assets/image-20211004153101887.png)

#### 5.6数据持久化特性

进入其中一个容器，创建一个文件：

```
[root@master pvc-test]# kubectl exec -it web-0 /bin/sh
# cd /usr/share/nginx/html
# touch 1.txt
```

![image-20211004100843403](assets/image-20211004100843403.png)

直接在web-1的目录下，创建一个文件：

```
[root@master pvc-test]# touch /opt/container_data/default-www-web-1-pvc-5efd9492-c13d-414b-8df3-68b0c37961dd/2.txt
```

![image-20211004100955972](assets/image-20211004100955972.png)

![image-20211004101027800](assets/image-20211004101027800.png)

而且，删除一个pod   web-0，数据仍然存在，不会丢失。保证了数据持久化；

![image-20211004101222350](assets/image-20211004101222350.png)

测试

```shell
[root@master container_data]# pwd
/opt/container_data
[root@master container_data]# kubectl get pod -o wide
```

![image-20211004153921892](assets/image-20211004153921892.png)

```shell
##1.
[root@master container_data]# echo "youngfit-1" >> default-www-web-0-pvc-fd4bf916-fe84-4b20-80b4-27442effb584/index.html
[root@master container_data]# curl 10.244.104.8
youngfit-1

##2.
[root@master container_data]# kubectl exec -it web-1 /bin/sh
# cd /usr/share/nginx/html
# echo youngfit-2 >> index.html
[root@master container_data]# ls default-www-web-1-pvc-5efd9492-c13d-414b-8df3-68b0c37961dd/
2.txt  index.html
[root@master container_data]# curl 10.244.166.138
youngfit-2
```

#### 5.7 验证解析

每个 Pod 都拥有一个基于其顺序索引的稳定的主机名

![image-20211004221413059](assets/image-20211004221413059.png)

使用 kubectl run 运行一个提供 nslookup 命令的容器，该命令来自于 dnsutils 包。通过对 Pod 的主机名执行 nslookup，你可以检查他们在集群内部的 DNS 地址

```shell
[root@master pvc-test]# cat pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: testnginx
spec:
  containers:
  - name: testnginx
    image: daocloud.io/library/nginx:1.12.0-alpine
[root@master pvc-test]# kubectl apply -f pod.yaml
[root@master pvc-test]# kubectl exec -it testnginx /bin/sh
```

![image-20211004222356547](assets/image-20211004222356547.png)

![image-20211004222542553](assets/image-20211004222542553.png)

重启pod会发现，pod中的ip已经发生变化，但是pod的名称并没有发生变化；这就是为什么不要在其他应用中使用 StatefulSet 中的 Pod 的 IP 地址进行连接，这点很重要

![image-20211004222810230](assets/image-20211004222810230.png)

```
[root@master pvc-test]# kubectl delete pod -l app=nginx
pod "web-0" deleted
pod "web-1" deleted
[root@master pvc-test]# kubectl get pod -o wide
```

![image-20211004222929002](assets/image-20211004222929002.png)

![image-20211004223037202](assets/image-20211004223037202.png)

![image-20211004223224296](assets/image-20211004223224296.png)

#### 5.8 写入稳定的存储

将 Pod 的主机名写入它们的index.html文件并验证 NGINX web 服务器使用该主机名提供服务

```
[root@k8s-master sts]# kubectl exec -it web-0 /bin/sh
# cd /usr/share/nginx/html
# echo youngfit-1 > index.html

[root@k8s-master sts]# kubectl exec -it web-1 /bin/sh
#  cd /usr/share/nginx/html
# echo youngfit-2 > index.html                

[root@k8s-master sts]# ls /opt/container_data/default-www-web-0-pvc-ae99bd8d-a337-458d-a178-928cf4602713/
index.html
[root@k8s-master sts]# ls /opt/container_data/default-www-web-1-pvc-afac76ea-9faf-41ac-b03d-7ffc9e277029/
index.html

```

![image-20211004223704087](assets/image-20211004223704087.png)

```shell

[root@k8s-master sts]# curl 10.244.4.5
youngfit-1
[root@k8s-master sts]# curl 10.244.1.4
youngfit-2

再次删除
[root@k8s-master sts]# kubectl delete pod -l app=nginx
pod "web-0" deleted
pod "web-1" deleted
[root@k8s-master sts]# kubectl apply -f  nginx.yaml
[root@k8s-master sts]# kubectl get pod
NAME                                     READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-56cc44bd5-2hgxc   1/1     Running   0          27m
testnginx                                1/1     Running   0          6m20s
web-0                                    1/1     Running   0          13s
web-1                                    1/1     Running   0          6s
```

再次查看

![image-20211004223758863](assets/image-20211004223758863.png)

![image-20211004223822651](assets/image-20211004223822651.png)



#### 5.9 扩容/缩容 StatefulSet

扩容/缩容StatefulSet 指增加或减少它的副本数。这通过更新`replicas`字段完成。你可以使用kubectl scale 或者kubectl patch来扩容/缩容一个 StatefulSet。

![image-20211004223934419](assets/image-20211004223934419.png)

![image-20211004224020526](assets/image-20211004224020526.png)

![image-20211004224051835](assets/image-20211004224051835.png)

![image-20211004224108793](assets/image-20211004224108793.png)

![image-20211004224204314](assets/image-20211004224204314.png)

