## 1、 Head插件安装

**前提**： head插件是Nodejs实现的，所以需要先安装Nodejs。

### 1.1 安装nodejs

nodejs官方下载地址：https://nodejs.org/

下载linux64位：

```shell
[root@es-3-head-kib ~]# wget https://nodejs.org/dist/v14.17.6/node-v14.17.6-linux-x64.tar.xz
[root@es-3-head-kib ~]# tar xf node-v14.17.6-linux-x64.tar.xz -C /usr/local/
[root@localhost nodejs]# vim /etc/profile
# 添加 如下配置
NODE_HOME=/usr/local/node-v14.17.6-linux-x64
JAVA_HOME=/usr/local/java
PATH=$NODE_HOME/bin:$JAVA_HOME/bin:$PATH
export JAVA_HOME PATH
#由于我这里，ES也装在了此台机器上，所以环境变量这样配置；不能删除jdk的配置
[root@es-3-head-kib ~]# source /etc/profile
[root@es-3-head-kib ~]# node --version
v14.17.6
[root@es-3-head-kib ~]# npm -v
6.14.15
```

npm 是随同NodeJS一起安装的包管理工具,能解决NodeJS代码部署上的很多问题。

### 1.2 安装git

需要使用git方式下载head插件，下面安装git：

```shell
[root@es-3-head-kib local]# yum install -y git
[root@es-3-head-kib local]# git --version
git version 1.8.3.1
```

### 1.3 下载及安装head插件

```shell
[root@es-3-head-kib ~]# cd /usr/local/
[root@es-3-head-kib local]# git clone git://github.com/mobz/elasticsearch-head.git
[root@es-3-head-kib local]# cd elasticsearch-head/
[root@es-3-head-kib elasticsearch-head]# npm install   #注意：这里直接安装，可能会失败，如果你的网络没问题，才能下载成功
#也可以将npm源设置为国内淘宝的，确保能下载成功
[root@es-3-head-kib elasticsearch-head]# npm install -g cnpm --registry=https://registry.npm.taobao.org
[root@es-3-head-kib elasticsearch-head]# npm install #报错，不用管它
```

修改地址：如果你的head插件和ES没在一台机器上，需要进行如下2处修改，在一台机器，不修改即可

```
[root@es-3-head-kib elasticsearch-head]# vim Gruntfile.js
```

![image-20210916163427164](assets/image-20210916163427164.png)

```
[root@es-3-head-kib elasticsearch-head]# vim _site/app.js #配置连接es的ip和port
```

![image-20210916163543021](assets/image-20210916163543021.png)

### 1.4 配置elasticsearch，允许head插件访问

```
[root@es-3-head-kib ~]# vim /usr/local/elasticsearch-6.5.4/config/elasticsearch.yml
在配置最后面，加2行
```

![image-20210916162555873](assets/image-20210916162555873.png)

然后，重启elasticsearch

### 1.5 测试

进入到head目录，执行npm run start

```shell
[root@es-3-head-kib ~]# cd /usr/local/elasticsearch-head/
[root@es elasticsearch-head]# nohup npm  run start &
```

启动成功后，在浏览器访问：http://192.168.153.190:9100/ ，内部输入 http://192.168.153.190:9200/ 点击连接测试，输出黄色背景字体说明配置OK。

![image-20210916162805718](assets/image-20210916162805718.png)
