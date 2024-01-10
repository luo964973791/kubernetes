```shell
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
# ------------------------------ Kafka Output ---------------------------------- #大约161行
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
