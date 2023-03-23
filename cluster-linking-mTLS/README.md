# Confluent Platform Cluster Linking

A project to demonstrate Cluster Linking Between two clusters running Confluent Platform (7.3.1).

The project will set up two single-broker Kafka "Clusters", each with a separate Zookeeper instance.

## Starting the Clusters

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
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:29093 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

## (Client) Consumer on Broker 1 using mTLS

```bash
docker-compose exec broker1 kafka-console-consumer --bootstrap-server broker1:29093 --topic kafka-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## (Client) Producer on Broker 2 using mTLS

```bash
docker-compose exec broker2 kafka-console-producer --bootstrap-server broker2:29094 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```

## (Client) Consumer on Broker 2 using mTLS

```bash
docker-compose exec broker2 kafka-console-consumer --bootstrap-server broker2:29094 --topic kafka-topic --consumer.config /tmp/producer/client-ssl-auth.properties --from-beginning
```

## Debug

```bash
docker-compose exec broker1 bash
```

```bash
docker-compose exec broker1 bash
/etc/kafka
cat kafka.properties
```

## SSL Checking

```bash
openssl s_client -connect localhost:29093 -tls1_2 -showcerts
openssl s_client -connect localhost:29093 -tls1_3 -showcerts
curl -k -v --cert-type P12 --cert kafka.client.keystore.jks:confluent https://localhost:29093
```

## Check logs

```bash
docker logs broker1 | grep "SocketServer"
```

#### Notes below

```bash
docker-compose exec broker1 kafka-console-producer --broker-list broker1:9093 --topic kafka-topic --producer.config /tmp/client-ssl-auth.properties
docker-compose exec broker1 kafka-console-producer --bootstrap-server broker1:9093 --topic kafka-topic --producer.config /tmp/client-ssl-auth.properties
docker-compose exec broker1 kafka-console-producer --bootstrap-server localhost:29093 --topic kafka-topic --producer.config /tmp/producer/client-ssl-auth.properties
```
