## Docker Compose files for Confluent Platform

### Quick Start

```bash
cd confluent-dockerfiles/connect-cluster/classic-with-replicator
docker system prune -f && docker-compose up
```

### Wait for startup
```bash
watch -d curl localhost:8083
```

### Confirm the Connect Cluster is available

```bash
curl localhost:8083 | jq
```

### Confirm the ReplicatorSourceConnector is a listed Connector Plugin

```bash
curl localhost:8083/connector-plugins | jq
```

### Retrieve the Cluster information (and id) using ReST Proxy

```bash
curl localhost:8082/v3/clusters | jq
```

### Create the replicator topic using ReST Proxy

```bash
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
          --data '{"topic_name": "replicate-me", "partitions_count": 4, "replication_factor": 1}' \
          "http://localhost:8082/v3/clusters/<cluster-id>/topics" | jq
```

### Create the replicator

```bash
./replicator.sh
```

### Get the status of the replicator

```bash
curl localhost:8083/connectors/replicator/status | jq
```

### Start Producing to the topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-producer --broker-list kafka:29092 --topic replicate-me
```

Open Confluent Control Centre <http:hostname:9021>

### Troubleshooting

Connect to the First Kafka Connect instance

```bash
docker-compose exec connect1 bash
```

Delete the replicator

```bash
curl -X DELETE connect1:8083/connectors/replicator
```


