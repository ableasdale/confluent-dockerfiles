#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "replicator",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.whitelist": "replicate-me",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "src.kafka.bootstrap.servers": "broker:9092",
    "src.consumer.group.id": "replicator-dc1-to-dc2-topic1",
    "src.kafka.timestamps.topic.replication.factor": 1,
    "dest.kafka.bootstrap.servers": "broker:9092",
    "confluent.topic.replication.factor": 1,
    "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "tasks.max": "4",
    "topic.rename.format":"backup_${topic}"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
