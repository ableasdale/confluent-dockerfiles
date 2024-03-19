# 2 Data Centres

The aim of this repository is to provide a very lightweight "2-data centre" project for simple performance testing and demoing Replicator.  It's configured to be lightweight so it can be run locally whilst also screensharing over a call.

The walkthrough in this README demonstrates creating some load on the broker in one DC and then configuring Replicator and subsequently tuning Replicator for better performance.

## Getting started

```bash
docker-compose up -d
```

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

docker-compose exec broker-dc2 kafka-topics --list --bootstrap-server broker-dc2:29092
docker-compose exec broker-dc2 kafka-topics --describe --bootstrap-server broker-dc2:29092
docker-compose exec broker-dc2 kafka-topics --describe --topic replicate-me --bootstrap-server broker-dc2:29092




Troubleshootinh

waiting for replication to catch up.  Please check replication lag

org.apache.kafka.common.errors.InvalidConfigurationException: topic.whitelist contains topics: [replicate-me] but these are either not present in the source cluster or are missing DES
CRIBE ACLs. Please make sure that the topics are allowed to DESCRIBE in ACLs
[2024-03-19 12:46:53,159] ERROR WorkerConnector{id=replicator-dc1-to-dc2} Connector raised an error (org.apache.kafka.connect.runtime.WorkerConnector)
org.apache.kafka.common.errors.InvalidConfigurationException: topic.whitelist contains topics: [replicate-me] but these are either not present in the source cluster or are missing DESCRIBE ACLs. Please make sure that the topics are allowed to DESCRIBE in ACLs

```bash
docker logs connect-dc1 --follow
```

```bash
docker-compose exec broker-dc1 kafka-acls --list --bootstrap-server broker-dc1:29091 --topic replicate-me
```


https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/replicator-verifier.html

Run the replicator verifier:

```bash
docker-compose exec connect-dc1 replicator-verifier \
 --connect-url connect-dc1:8381 \
 --connector-name replicator-dc1-to-dc2
```

[2024-03-19 13:07:05,951] ERROR Unexpected exception in topic monitor thread (io.confluent.connect.replicator.NewTopicMonitorThread)
org.apache.kafka.common.errors.InvalidConfigurationException: topic.whitelist contains topics: [replicate-me] but these are either not present in the source cluster or are missing DESCRIBE ACLs. Please make sure that the topics are allowed to DESCRIBE in ACLs
[2024-03-19 13:07:05,951] ERROR WorkerConnector{id=replicator-dc1-to-dc2} Connector raised an error (org.apache.kafka.connect.runtime.WorkerConnector)
org.apache.kafka.common.errors.InvalidConfigurationException: topic.whitelist contains topics: [replicate-me] but these are either not present in the source cluster or are missing DESCRIBE ACLs. Please make sure that the topics are allowed to DESCRIBE in ACLs





[2024-03-19 12:47:03,174] ERROR [Worker clientId=connect-1, groupId=connect-dc1] Failed to reconfigure connector's tasks (replicator-dc1-to-dc2), retrying after backoff. (org.apache.k
afka.connect.runtime.distributed.DistributedHerder)
org.apache.kafka.connect.errors.ConnectException: Could not obtain timely topic metadata update from source cluster
        at io.confluent.connect.replicator.NewTopicMonitorThread.assignments(NewTopicMonitorThread.java:168)
        at io.confluent.connect.replicator.ReplicatorSourceConnector.taskConfigs(ReplicatorSourceConnector.java:114)
        at org.apache.kafka.connect.runtime.Worker.connectorTaskConfigs(Worker.java:479)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.reconfigureConnector(DistributedHerder.java:2103)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.reconfigureConnectorTasksWithExponentialBackoffRetries(DistributedHerder.java:2047)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.reconfigureConnectorTasksWithRetry(DistributedHerder.java:2034)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.lambda$null$38(DistributedHerder.java:1979)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.runRequest(DistributedHerder.java:2254)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.tick(DistributedHerder.java:471)
        at org.apache.kafka.connect.runtime.distributed.DistributedHerder.run(DistributedHerder.java:372)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)