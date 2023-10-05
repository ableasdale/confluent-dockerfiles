# To run through a simple test case

Start the containers:

```bash
docker-compose -d up
```

Wait for the ReST endpoint to become available:

```bash
watch -d curl localhost:8083
```

When the endpoint is ready, you should see:

```bash
{"version":"7.5.0-ce","commit":"be816cdb62b83d78","kafka_cluster_id":"bTk1h9nGSAitTieoK2o7AA"}
```

## Alternative ways to get the `cluster.id`

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
          "http://localhost:8082/v3/clusters/bTk1h9nGSAitTieoK2o7AA/topics" | jq
```

Or, alternately, use `kafka-topics` to create the initial topic:

```bash
docker-compose exec kafka kafka-topics --bootstrap-server kafka:29092 --create --topic replicate-me --partitions 4 --replication-factor 1
```

## Create the replicator instance

```bash
./create_replicator.sh
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

## Debugging

Logging for:

```java
io.confluent.connect.replicator.offsets.OffsetManager
```

### Check `connect-offsets`

View the offsets `connect-offsets` topic:

```bash
docker exec kafka kafka-console-consumer --bootstrap-server kafka:29092 --topic connect-offsets --from-beginning --property print.key=true --property print.timestamp=true
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

## Viewing the `__consumer_offsets` topic

Note that this approach works for `__consumer_offsets` but doesn't work for `connect-offsets`

```bash
docker-compose exec kafka kafka-console-consumer --from-beginning --topic __consumer_offsets --bootstrap-server kafka:29092 --formatter "kafka.coordinator.group.GroupMetadataManager\$OffsetsMessageFormatter"
```

## Create some load

To test / performance tune Replicator, the `kafka-producer-perf-test` gives you a repeatable method for loading a set amount of data into a given topic:

```bash
docker-compose exec kafka kafka-producer-perf-test --throughput -1 --num-records 1000000 --topic replicate-me --record-size 1000 --producer-props bootstrap.servers=kafka:29092 acks=all
```

For a larger batch (and a longer running test):

```bash
docker-compose exec kafka kafka-producer-perf-test --throughput 50000 --num-records 10000000 --topic replicate-me --record-size 100 --producer-props bootstrap.servers=kafka:29092 acks=all compression.type=lz4 batch.size=800000 linger.ms=100
```

## Restart a single Replicator Task

```bash
curl -X POST http://localhost:8083/connectors/replicator/tasks/0/restart | jq
```

## SSH to the Connect instance

```bash
docker-compose exec connect bash
```

## View the Worker properties (on the Connect instance)

```bash
more /etc/kafka/connect-distributed.properties
```

## Tail the Connect Logs

```bash
docker logs -f connect --tail 10
```
