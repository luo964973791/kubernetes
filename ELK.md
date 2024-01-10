```shell
[root@node1 tasks]# grep -vE '^\s*$|^\s*#' /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  symlinks: true      #大约27行添加
  paths:
    - "/var/log/containers/*.log"
    - "/var/log/*.log"
# ------------------------------ Kafka Output ---------------------------------- #大约161行添加
output.kafka:
  hosts:  ["172.27.0.7:9092"]
  topic: "demo_log"
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
for i in {2..4};do ./bin/kafka-topics.sh --bootstrap-server 172.27.0.7:9092 --create --topic 172-27-0-$i-log --partitions 3 --replication-factor 3;done
shell run sed -i "s/demo_log/$(hostname -I | awk '{print $1}' | sed 's/\./-/g;s/$/-log/')/g" /etc/filebeat/filebeat.yml
shell run sed -i "s/demo_log/$(hostname -I | awk '{print $1}' | sed 's/\./-/g;s/$/-log/')/g" /etc/logstash/conf.d/linux.conf
systemctl restart filebeat
systemctl restart logstash
```
