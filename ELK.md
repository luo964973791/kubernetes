```shell
[root@node1 tasks]# grep -vEn '^\s*$|^\s*#' /etc/filebeat/filebeat.yml
15:filebeat.inputs:
21:- type: log
24:  enabled: true
27:  symlinks: true    #这个必须打开,否则收集不到符号链接目录的日志
28:  paths:
29:    - "/var/log/containers/*.log"
30:    - "/var/log/*.log"
69:filebeat.config.modules:
71:  path: ${path.config}/modules.d/*.yml
74:  reload.enabled: true
81:setup.template.settings:
82:  index.number_of_shards: 1
118:setup.kibana:
162:output.kafka:
163:  hosts:  ["172.27.0.7:9092"]
164:  topic: "demo_log"
185:processors:
186:  - add_host_metadata: ~
187:  - add_cloud_metadata: ~
188:  - add_docker_metadata: ~
189:  - add_kubernetes_metadata: ~


## 不带行号.
[root@node1 tasks]# grep -vE '^\s*$|^\s*#' /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  symlinks: true
  paths:
    - "/var/log/containers/*.log"
    - "/var/log/*.log"
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
output.kafka:
  hosts:  ["172.27.0.7:9092"]
  topic: "demo_log"
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
```



```shell
cat <<EOF | tee -a /etc/logstash/conf.d/linux.conf
input {
    kafka {
        bootstrap_servers => "172.27.0.7:9092"
        auto_offset_reset => "latest" 
        consumer_threads => 1 
        decorate_events => true
        topics => ["demo_log"]
        codec => "json"
        group_id => "logstash"
    }
}
output {
    elasticsearch {
        hosts => ["http://172.27.0.6:9200"]
        user => elastic
        password => "elastic"
        index => "demo_log"
        ssl => false
    }  
}
EOF
```


```shell
shell run sed -i "s/demo_log/$(hostname -I | awk '{print $1}' | sed 's/\./-/g;s/$/-log/')/g" /etc/filebeat/filebeat.yml
shell run sed -i "s/demo_log/$(hostname -I | awk '{print $1}' | sed 's/\./-/g;s/$/-log/')/g" /etc/logstash/conf.d/linux.conf
systemctl restart filebeat
systemctl restart logstash
```
