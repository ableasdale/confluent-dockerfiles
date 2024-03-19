#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator-dc1-to-dc2",
  "config": {
  

    "src.consumer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "src.consumer.confluent.monitoring.interceptor.bootstrap.servers": "broker-dc2:29092",
    
    "dest.kafka.bootstrap.servers": "broker-dc2:29092",

      "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
      "topic.whitelist": "replicate-me",
      "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
      "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
      "src.kafka.bootstrap.servers": "broker-dc1:29091",
      "src.consumer.group.id": "replicator-connector-consumer-group",
      "src.kafka.timestamps.topic.replication.factor": 1,
      "dest.kafka.bootstrap.servers": "broker-dc2:29092",
      "confluent.topic.replication.factor": 1,
      "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
      "tasks.max": "4",
      "topic.auto.create":"true",

      "producer.override.linger.ms":"100",
      "producer.override.batch.size": "800000",
      "producer.override.compression.type":"lz4",
      "offset.translator.tasks.max": "0",
      "offset.timestamps.commit": "false",
      "offset.topic.commit": "true",
      "connector.client.config.override.policy": "All",
      "src.consumer.fetch.min.bytes": "800000",
      "src.consumer.fetch.max.wait.ms": "500",
      "src.consumer.max.partition.fetch.bytes": "10485760",


      "consumer.override.bootstrap.servers": "broker-dc1:29091",
      "producer.override.bootstrap.servers": "broker-dc2:29092",

      "src.kafka.security.protocol": "PLAINTEXT", 
      "dest.kafka.security.protocol": "PLAINTEXT"
      
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8381/connectors
