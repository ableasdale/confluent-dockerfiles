# To run through a simple test case

## Get the `cluster.id`

```bash
curl localhost:8082/v3/clusters | jq
```

## Replace the `cluster.id` with in the cURL statement below to create the source topic

```bash
curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
          --data '{"topic_name": "replicate-me", "partitions_count": 4, "replication_factor": 1}' \
          "http://localhost:8082/v3/clusters/<cluster-id>/topics" | jq
```

## Create the replicator instance

```bash
./replicator.sh
```

## Produce to the source topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-producer --bootstrap-server kafka:29092 --topic replicate-me
```

## Consume from the replica topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-consumer --bootstrap-server kafka:29092 --topic replicate-me.replica --from-beginning
```

### Debug notes below

io.confluent.connect.replicator.offsets.OffsetManager
debugging on offsetManager.class