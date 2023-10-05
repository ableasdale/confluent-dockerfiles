# To run through a simple test case

Wait for everything to become available

```bash
watch -d curl localhost:8083
```

## Get the `cluster.id`

```bash
curl localhost:8082/v3/clusters | jq '."data"'
```

Look for the line containing the `"cluster_id"` property:

```json
    "cluster_id": "zqhe9SrmSrizZOIWN76blA",
```

In later versions of Confluent Platform you can also run:

```bash
docker-compose exec kafka kafka-cluster cluster-id --bootstrap-server kafka:29092
```

## Replace the `<cluster-id>` with in the cURL statement below to create the source topic

```bash
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
          --data '{"topic_name": "replicate-me", "partitions_count": 4, "replication_factor": 1}' \
          "http://localhost:8082/v3/clusters/<cluster-id>/topics" | jq
```

For example:

```bash
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
          --data '{"topic_name": "replicate-me", "partitions_count": 4, "replication_factor": 1}' \
          "http://localhost:8082/v3/clusters/zqhe9SrmSrizZOIWN76blA/topics" | jq
```

## Create the replicator instance

```bash
./replicator.sh
```

## Produce to the source topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-producer --bootstrap-server kafka:29092 --topic replicate-me
```

## Delete the existing Replicator instance

```bash
./delete_replicator.sh
```

## Consume from the replica topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-consumer --bootstrap-server kafka:29092 --topic replicate-me.replica --from-beginning
```

### Debug notes below

Logging for:

```java
io.confluent.connect.replicator.offsets.OffsetManager
```

## ksqlDB

Investigating using ksqlDB to explore the topics and connectors; to get started, run:

```bash
ksql
```

### List topics

```sql
show topics;
```

### To show ALL topics

```sql
show all topics;
```

### List Connectors

```sql
show connectors;
```

TODO:

```sql
SELECT * FROM docker-connect-configs;
select * from replicate-me.replica;
```
