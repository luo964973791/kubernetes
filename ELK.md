```shell
[root@node1 ~]# grep -vE '^\s*$|^\s*#' /etc/filebeat/filebeat.yml
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
        topics => ["172-27-0-6-log"]
        codec => "json"
        group_id => "logstash"
    }
}


filter{
    grok{
      match => {"message" => "%{TIMESTAMP_ISO8601:log_timestamp} \| %{LOGLEVEL:level} %{SPACE}* \| (?<class>[__main__:[\w]*:\d*]+) \- %{GREEDYDATA:content}"}
    }
    mutate {
        gsub =>[
            "content", "'", '"'
        ]
        lowercase => [ "level" ]
    }
    json {
        source => "content"
    }
    mutate {
        remove_field => ["content", "@version", "tags"]
    }
}

#输出调式模式
#output {
#  stdout {
#    codec => rubydebug
#  }
#}


output {
    elasticsearch {
        hosts => ["http://172.27.0.6:9200"]
        user => elastic
        password => "elastic"
        index => "172-27-0-6-log"
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
