# 2 Data Centres

The aim of this repository is to provide a very lightweight "2-data centre" project for simple performance testing and demoing Replicator.  It's configured to be lightweight so it can be run locally whilst also screensharing over a call.

The walkthrough in this README demonstrates creating some load on the broker in one DC and then configuring Replicator and subsequently tuning Replicator for better performance.

## Prerequisites

We will start by creating the `replicate-me` topic for replication:

```bash
docker-compose exec broker-dc1 kafka-topics --bootstrap-server broker-dc1:29091 --topic replicate-me --replication-factor 1 --partitions 1 --create
```

You should see:

```bash
Created topic replicate-me.
```

Create some sample data:

```bash
docker-compose exec broker-dc1 kafka-producer-perf-test --throughput -1 --num-records 1000000 --topic replicate-me --record-size 10 --producer-props bootstrap.servers='broker-dc1:29091' acks=all
```

Create the Replicator instance:

```bash
./submit_replicator_dc1_to_dc2.sh
```

You should see:

```json
{"name":"replicator-dc1-to-dc2-shiz","config":{"connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector","topic.whitelist":"replicate-me","key.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","value.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","src.kafka.bootstrap.servers":"broker-dc1:29091","src.consumer.group.id":"replicator-dc1-to-dc2-topic1","src.consumer.interceptor.classes":"io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor","src.consumer.confluent.monitoring.interceptor.bootstrap.servers":"broker-dc2:29092","src.kafka.timestamps.topic.replication.factor":"1","src.kafka.timestamps.producer.interceptor.classes":"io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor","src.kafka.timestamps.producer.confluent.monitoring.interceptor.bootstrap.servers":"broker-dc2:29092","dest.kafka.bootstrap.servers":"broker-dc2:29092","confluent.topic.replication.factor":"1","provenance.header.enable":"true","header.converter":"io.confluent.connect.replicator.util.ByteArrayConverter","tasks.max":"1","topic.auto.create":"true","topic.rename.format":"xxxxxxxx..replicated","name":"replicator-dc1-to-dc2-shiz"},"tasks":[],"type":"source"}
```
