#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator-dc1-to-dc2-first-test",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",

    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "broker-dc2:29092",
    "src.kafka.bootstrap.servers": "broker-dc1:29091",
    "src.consumer.group.id": "replicator-connector-consumer-group",
    "src.kafka.timestamps.topic.replication.factor": 1,
    
    "dest.kafka.bootstrap.servers": "broker-dc2:29092",

    "topic.whitelist": "first-test",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",

    "confluent.topic.replication.factor": 1,
    "tasks.max": "1",
    "topic.auto.create":"true"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8381/connectors
