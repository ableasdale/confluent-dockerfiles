#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator-dc1-to-dc2-fifth-test",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    
    "producer.override.linger.ms":"100",
    "producer.override.batch.size": "800000",
    "producer.override.compression.type":"lz4",
    "producer.override.acks":"all",

    "src.consumer.fetch.min.bytes": "800000",
    "src.consumer.fetch.max.wait.ms": "500",
    "src.consumer.max.partition.fetch.bytes": "10485760",

    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "broker-dc2:29092",
    "src.kafka.bootstrap.servers": "broker-dc1:29091",
    "src.consumer.group.id": "replicator-connector-fifth-test-consumer-group",
    "src.kafka.timestamps.topic.replication.factor": 1,
    
    "dest.kafka.bootstrap.servers": "broker-dc2:29092",

    "topic.whitelist": "fifth-test",
    "offset.translator.tasks.max": "0",
    "offset.timestamps.commit": "false",
    "offset.topic.commit": "true",
    
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",

    "confluent.topic.replication.factor": 1,
    "tasks.max": "10",
    "topic.auto.create":"true",
    "consumer.override.bootstrap.servers": "broker-dc1:29091",
    "producer.override.bootstrap.servers": "broker-dc2:29092",

    "src.kafka.security.protocol": "PLAINTEXT", 
    "dest.kafka.security.protocol": "PLAINTEXT"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8381/connectors
