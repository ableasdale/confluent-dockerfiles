#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator-dc1-to-dc2",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "replicate-me",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "src.kafka.bootstrap.servers": "broker-dc1:29091",
    "src.consumer.group.id": "replicator-dc1-to-dc2-topic1",
    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "broker-dc2:29092",
    
    "dest.kafka.bootstrap.servers": "broker-dc2:29092",
    "confluent.topic.replication.factor": 1,
    "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "tasks.max": "1",
    "topic.auto.create":"true"
    
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8381/connectors
