# Confluent Platform Cluster Linking (with mTLS)

A project to demonstrate Cluster Linking (over mTLS) between two clusters running Confluent Platform (7.3.1).

The project will set up two single-broker Kafka "Clusters", each with a separate Zookeeper instance.

## Creating the certificates and stores

- Starting from the directory for this project (`confluent-dockerfiles/cluster-linking-mTLS`)
- `cd` to `security1` and run `create-certs.sh` from within the directory; this will create the root certificate and all the stores for both the server and the clients.
- `cd` to `security2` and run `create-certs.sh` from within the directory; this will copy over the previously created root certificate and create all the stores for both the server and the clients.

## Starting the clusters

Start both clusters using the provided `docker-compose.yaml` file:

```bash
docker-compose up
```

## Ensure everything is working and has started correctly

### Check the first cluster

We can quickly check the status of each cluster using `zookeeper-shell` on the first cluster:

```bash
docker-compose exec zookeeper1 zookeeper-shell localhost:2181
```

Ensure Zookeeper has a `/controller` zNode:

```bash
get /controller
{"version":1,"brokerid":1,"timestamp":"1679586476359"}
```

Later, when we establish the Cluster Link, we will need the Cluster ID; you can do this using Zookeeper:

```bash
get /cluster/id
{"version":"1","id":"VbspgOThRyWItHm3MJOaPw"}
```

### Check the second cluster

Now let's try to connect to Zookeeper instance (`zookeeper2`) on the second cluster using `zookeeper-shell`:

```bash
docker-compose exec zookeeper2 zookeeper-shell localhost:2182
```

Confirm the `/controller` is registered with Zookeeper:

```bash
get /controller
{"version":1,"brokerid":1,"timestamp":"1679586476334"}
```

Check the Cluster ID:

```bash
get /cluster/id
{"version":"1","id":"t5m8D-r0QYyGhKVBWM8kyg"}
```

### Ensure Clients can Produce to both brokers using the non-TLS plaintext listener

We're going to use `kafka-console-producer` to attempt to write to a Kafka Topic using the plaintext listeners in both clusters (ports 9091 and 9092 respectively):

```bash
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9091 --topic kafka-topic
```

And we will run the same test using the second broker (cluster):

```bash
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:9092 --topic kafka-topic
```

## Ensure Clients can Consume from both brokers using the non-TLS plaintext listener

```bash
docker-compose exec broker1 kafka-console-consumer --bootstrap-server broker1:9091 --from-beginning --topic kafka-topic
```

And again, confirm that the test works with the second broker/cluster:

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9092 --from-beginning --topic kafka-topic
```

## (Client) Producer on Broker 1 using mTLS

```bash
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

## (Client) Consumer on Broker 1 using mTLS

```bash
docker-compose exec broker1 kafka-console-consumer --bootstrap-server broker1:9093 --topic kafka-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## (Client) Producer on Broker 2 using mTLS

```bash
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:9094 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

## (Client) Consumer on Broker 2 using mTLS

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9094 --topic kafka-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## Establish the Cluster Link between the two brokers

To get a list of common switches for the `kafka-cluster-links` command, you can run:

```bash
docker-compose exec broker1 kafka-cluster-links --help
```

To start with, we need to get the Cluster ID for broker1:

```bash
docker-compose exec broker1 kafka-cluster cluster-id --bootstrap-server broker1:9091
Cluster ID: yHmKId23QNyxyTIrmbo2YA
```

Using that ID, we can build the command for `kafka-cluster-links`:

```bash
docker-compose exec broker1 kafka-cluster-links --bootstrap-server broker2:9094 --create --link my-link --command-config /tmp/producer/broker1-link-config.properties --config-file /tmp/producer/broker1-link-config.properties --cluster-id yHmKId23QNyxyTIrmbo2YA
```

You should see:

```bash
Cluster link 'my-link' creation successfully completed.
```

Let's confirm that the link has been set up by describing it:

```bash
docker-compose exec broker1 kafka-cluster-links --list --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-link-config.properties
```

Now let's try to create a topic (on broker1):

```bash
docker exec -it broker1 /bin/bash -c 'kafka-topics --bootstrap-server broker1:9091 --topic demo-cl-topic --replication-factor 1 --partitions 1 --create --config min.insync.replicas=1'
```

Now let's mirror it on broker2:

```bash
docker-compose exec broker1 kafka-mirrors --create --mirror-topic demo-cl-topic --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-link-config.properties
```

You should see:

```bash
Created topic demo-cl-topic.
```

## Produce to the topic on Broker 1; Consume from the mirror topic on Broker 2

We're going to set up our console producer to produce (over TLS) to the `demo-cl-topic`:

```bash
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic demo-cl-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

Let's ensure the messages can be read from the Consumer on `broker2`:

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9094 --topic demo-cl-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## Active / Passive setup - failover management

Let's describe the mirror topic using the `kafka-mirrors` command:

```bash
docker-compose exec broker1 kafka-mirrors --describe --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-link-config.properties
```

Note that the state (status) will be reported as `ACTIVE`:

```bash
docker-compose exec broker1 kafka-mirrors --describe --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-link-config.properties
Topic: demo-cl-topic	LinkName: my-link	LinkId: YJIZZLmoSiKW8_O50FA7hQ	SourceTopic: demo-cl-topic	State: ACTIVE	SourceTopicId: AAAAAAAAAAAAAAAAAAAAAA	StateTime: 2023-04-18 19:31:43
	Partition: 0	State: ACTIVE	DestLogEndOffset: 3	LastFetchSourceHighWatermark: 3	Lag: 0	TimeSinceLastFetchMs: 369859
```

Let's kill the broker with the primary topic:

```bash
docker stop broker1
```

Re-run the command; it will fail because we're trying to run it against `broker1` (which is now stopped):

```bash
docker-compose exec broker1 kafka-mirrors --describe --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-link-config.properties
service "broker1" is not running container #1
```

Run the command against `broker2`:

```bash
docker-compose exec broker2 kafka-mirrors --describe --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker2-link-config.properties
```

Note that the State is now `SOURCE_UNAVAILABLE`:

```bash
Topic: demo-cl-topic	LinkName: my-link	LinkId: YJIZZLmoSiKW8_O50FA7hQ	SourceTopic: demo-cl-topic	State: SOURCE_UNAVAILABLE	SourceTopicId: AAAAAAAAAAAAAAAAAAAAAA	StateTime: 2023-04-18 19:52:52
	Partition: 0	State: SOURCE_UNAVAILABLE	DestLogEndOffset: 3	LastFetchSourceHighWatermark: 3	Lag: 0	TimeSinceLastFetchMs: 1338107
```

If you want to perform Disaster Recovery, you can promote the mirror topic to a "normal" topic or failover:

```bash
docker-compose exec broker2 kafka-mirrors --promote --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker2-link-config.properties
docker-compose exec broker2 kafka-mirrors --failover --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker2-link-config.properties
```

You will now see:

```bash
Calculating max offset and ms lag for mirror topics: [demo-cl-topic]
Finished calculating max offset lag and max lag ms for mirror topics: [demo-cl-topic]
Request for stopping topic demo-cl-topic's mirror was successfully scheduled. Please use the describe command with the --pending-stopped-only option to monitor progress.
```

Describe the topic again:

```bash
docker-compose exec broker2 kafka-mirrors --describe --link my-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker2-link-config.properties
Topic: demo-cl-topic	LinkName: my-link	LinkId: YJIZZLmoSiKW8_O50FA7hQ	SourceTopic: demo-cl-topic	State: SOURCE_UNAVAILABLE	SourceTopicId: AAAAAAAAAAAAAAAAAAAAAA	StateTime: 2023-04-18 19:52:52
	Partition: 0	State: PENDING_STOPPED	DestLogEndOffset: 3	LastFetchSourceHighWatermark: -1	Lag: -1	TimeSinceLastFetchMs: 1681848069317
```

Write to the topic:

```bash
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:9094 --topic demo-cl-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

Consume from the topic:

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9094 --topic demo-cl-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## Creating an Active/Active ClusterLink Setup

The idea here is that you would configue bi-directional Cluster Linking, with a link from broker1 to broker2 and a link from broker2 back to broker1.

As soon as both links have been created, you can add prefixes to both topics and configure the Consumers to subscribe to both topics - the diagram below shows the architecture in slightly more detail:

[![Bi-Directional Cluster Linking](https://docs.confluent.io/cloud/current/_images/cluster-link-migrate-consumers-producers.png)](https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/migrate-cc.html#bidirectional-with-cluster-linking)

### Establishing Cluster Linking from broker1 to broker2

We're going to set up a new Cluster Link from Broker 1 with an additional property:

```properties
cluster.link.prefix=broker1_
```

This will prefix the mirror of the topic with `broker1`.

### Creating the Cluster Link for `broker1` to `broker2`

```bash
docker-compose exec broker1 kafka-cluster-links --bootstrap-server broker2:9094 --create --link broker1-link --command-config /tmp/producer/broker1-bidirectional-link-config.properties --config-file /tmp/producer/broker1-bidirectional-link-config.properties --cluster-id yHmKId23QNyxyTIrmbo2YA
```

Note that the destination cluster (broker2) is the bootstrap server for this connection and the `cluster-id` for this link is the id for the `broker1` cluster.

You should see:

```bash
[2023-03-23 20:32:10,973] WARN These configurations '[cluster.link.prefix]' were supplied but are not used yet. (org.apache.kafka.clients.admin.AdminClientConfig)
Cluster link 'broker1-link' creation successfully completed.
```

### Creating Source `clicks` topics on both clusters

We're going to create our "clicks" topics (which will be created on both broker1 and broker2):

```bash
docker exec broker1 kafka-topics --bootstrap-server broker1:9093 --topic clicks --replication-factor 1 --partitions 1 --create --config min.insync.replicas=1 --command-config /tmp/producer/client-ssl-auth.properties
```

And we will do the same for `broker2`:

```bash
docker exec broker2 kafka-topics --bootstrap-server broker2:9094 --topic clicks --replication-factor 1 --partitions 1 --create --config min.insync.replicas=1 --command-config /tmp/producer/client-ssl-auth.properties
```

### Creating the mirror from `broker1` to `broker2`

Now let's create the mirror for the topic on `broker1`:

```bash
docker-compose exec broker1 kafka-mirrors --create --source-topic clicks --mirror-topic broker1_clicks --link broker1-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-bidirectional-link-config.properties
```

And let's check that data produced on the source `clicks` topic is mirrored on `broker1_clicks`:

```bash
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic clicks --producer.config /tmp/producer/client-ssl-auth.properties
```

Let's ensure the messages can be read from the Consumer for `broker1_clicks` on `broker2`:

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9094 --topic broker1_clicks --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

### Creating the Cluster Link for `broker2` to `broker1`

```bash
docker-compose exec broker2 kafka-cluster-links --bootstrap-server broker1:9093 --create --link broker2-link --command-config /tmp/producer/broker2-bidirectional-link-config.properties --config-file /tmp/producer/broker2-bidirectional-link-config.properties --cluster-id yRIe4SqOTdKAEZVc-FgKtw
```

### Creating the mirror from `broker2` to `broker1`

Create the Mirror:

```bash
docker-compose exec broker2 kafka-mirrors --create --source-topic clicks --mirror-topic broker2_clicks --link broker2-link --bootstrap-server broker1:9093 --command-config /tmp/producer/broker2-bidirectional-link-config.properties
```

Produce to the `clicks` topic on broker2

```bash
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:9094 --topic clicks --producer.config /tmp/producer/client-ssl-auth.properties
```

Ensure that the messages can be read from the Consumer for `broker2_clicks` on `broker1`:

```bash
docker-compose exec broker1 kafka-console-consumer --bootstrap-server broker1:9093 --topic broker2_clicks --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

### Broker1: Consumer Subscribes to both topics; Producers write to each topic

We will create a wildcard include when we subscribe to the topic `--include "(.*)clicks$"`:

```bash
docker-compose exec broker1 kafka-console-consumer --bootstrap-server broker1:9093 --include "(.*)clicks$" --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

On `broker2`:

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:9094 --include "(.*)clicks$" --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

And then we can configure Producers for both source topics and we'll see updates reflected in both topics:

```bash
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic clicks --producer.config /tmp/producer/client-ssl-auth.properties
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:9094 --topic clicks --producer.config /tmp/producer/client-ssl-auth.properties
```

## Troubleshooting

### Checking topics

To list the topics on a given broker, you can run:

```bash
docker-compose exec broker2 kafka-topics --bootstrap-server broker1:9093 --list --command-config /tmp/producer/client-ssl-auth.properties
```

To check the destination topic:

```bash
docker-compose exec broker2 kafka-topics --bootstrap-server broker2:9094 --describe --topic broker1_clicks --command-config /tmp/producer/client-ssl-auth.properties
```

### JVM Heap Issues when running `kafka-cluster-links`

If you get an out of heap message that looks something like this:

```java
java.lang.OutOfMemoryError: Java heap space
    at java.base/java.nio.HeapByteBuffer.<init>(HeapByteBuffer.java:61)
```

Run this and try again:

```bash
export KAFKA_HEAP_OPTS="-Xmx1G -Xms1G"
```

Note that this message often appears if the command is missing something critical; double check what you're passing into `kafka-cluster-links`

### To debug directly on the host

You can ssh into the host by running:

```bash
docker-compose exec broker1 bash
```

From there you can look at what the docker-compose file has set up with respect to the brokers:

```bash
/etc/kafka
cat kafka.properties
```

### TLS/SSL Checks

Note that the TLS 1.3 check shows that the handshake was successful although there is a "bad certificate" error.  It does confirm that the connection works (which means the listener has been set up properly).

```bash
docker-compose exec broker1 openssl s_client -connect broker1:9093 -tls1_2 -showcerts
docker-compose exec broker1 openssl s_client -connect broker1:9093 -tls1_3 -showcerts
```

We can perform the same checks on Broker 2:

```bash
docker-compose exec broker2 openssl s_client -connect broker2:9094 -tls1_2 -showcerts
docker-compose exec broker2 openssl s_client -connect broker2:9094 -tls1_3 -showcerts
```

We can confirm that the TLS handshake takes place (and test the client keystore) by running:

```bash
docker-compose exec broker1 curl -k -v --cert-type P12 --cert /etc/kafka/secrets/kafka.client.keystore.jks:confluent https://broker1:9093
```

And we can perform the same check for broker2:

```bash
docker-compose exec broker2 curl -k -v --cert-type P12 --cert /etc/kafka/secrets/kafka.client.keystore.jks:confluent https://broker2:9094
```

### Checking the broker logs

You can use the `docker logs` command for this.  When Kafka brokers first start-up, they will log out the endpoints (listeners) that have been configured:

```bash
docker logs broker1 | grep "SocketServer"
```

You should see the following lines in the output:

```log
[2023-03-23 15:47:55,669] INFO [SocketServer listenerType=ZK_BROKER, nodeId=1] Created data-plane acceptor and processors for endpoint : ListenerName(PLAINTEXT) (kafka.network.SocketServer)
[2023-03-23 15:47:56,068] INFO [SocketServer listenerType=ZK_BROKER, nodeId=1] Created data-plane acceptor and processors for endpoint : ListenerName(SSL) (kafka.network.SocketServer)
```

#### Notes below

```bash
docker-compose exec broker1 kafka-console-producer --broker-list broker1:9093 --topic kafka-topic --producer.config /tmp/client-ssl-auth.properties
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic kafka-topic --producer.config /tmp/client-ssl-auth.properties
docker-compose exec broker1 kafka-console-producer --bootstrap-server localhost:29093 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

```bash
docker-compose exec broker1 kafka-mirrors --create --source-topic clicks --mirror-topic broker1_clicks --link broker1-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-bidirectional-link-config.properties
```

```bash
docker-compose exec broker1 kafka-mirrors --create --source-topic clicks2 --mirror-topic broker1_clicks2 --link broker1-link --bootstrap-server broker2:9094 --command-config /tmp/producer/broker1-bidirectional-link-config.properties
```