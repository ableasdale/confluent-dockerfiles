# Three Confluent Platform Brokers and one Zookeeper Instance

Last updated: 9th August 2024
CP Version: 7.7.0

- 3 Brokers
- Zookeeper
- Schema Registry
- Confluent Control Center (C3)

## Getting started

Run:

```bash
docker-compose up -d
```

Check to ensure everything is running as expected by going to: <http://localhost:9021> to view the cluster in Control Center

If you run this, a successful startup should show 6 containers are running:

```bash
docker ps
```

Let's use Zookeeper shell to perform a brief sanity check:

```bash
docker-compose exec zookeeper zookeeper-shell localhost:2181
```

Confirm that the cluster has a controller:

```bash
get /controller
```

Use `CTRL + C` to exit `zookeeper-shell`

## Setup

First let's connect to the broker to ensure that the `kafka-topics` command is responsive:

```bash 
docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --describe
```

We're going to create a topic and we're going to configure it with a larger `max.message.bytes` to test performance for messages of 5MB in size:

```bash
docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --topic test-topic --replication-factor 3 --partitions 3 --create --config min.insync.replicas=2 max.message.bytes=5242880
```

## Running Kafka Perf Test

1KB Record Size; 1 Million Records

```bash
docker-compose exec broker1 kafka-producer-perf-test --throughput 500000 --num-records 1000000 --topic test-topic --record-size 1000 --producer-props bootstrap.server broker1:9092 acks=all linger.ms=100 batch.size=300000 compression-type=lz4 --print-metrics
```