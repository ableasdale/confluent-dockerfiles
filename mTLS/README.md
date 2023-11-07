# Confluent Platform configured with Mutual TLS (mTLS)

This project demonstrates the setup of Kafka, Schema Registry and Control Center (C3) with each component secured with mTLS.

## Creating the certificates and stores

- Starting from the directory for this project (`confluent-dockerfiles/mTLS`)
- `cd` to `security` and run `create-certs.sh` from within the directory; this will create the root certificate and all the stores for both the server and the clients.

## Starting the clusters

Start both clusters using the provided `docker-compose.yaml` file:

```bash
docker-compose up
```

Wait for the cluster to start up fully; to do this you can check C3 at <http://localhost:9021/>

## Producing data to the cluster

Produce some data (using TLS); do this by connecting to the `tools` container and runing gradle from `/tmp/mTLS`:

```bash
docker-compose exec tools bash
cd /tmp/mTLS
./gradlew run
```

You should see some output like this:

```bash
09:45:42.078 INFO  io.confluent.csta.Main.main:11 - Running the TLS Producer...
09:45:43.510 INFO  io.confluent.csta.TLSProducer.main:27 - Sent 0:293536560
09:45:43.511 INFO  io.confluent.csta.TLSProducer.main:27 - Sent 1:416980828
09:45:43.515 INFO  io.confluent.csta.TLSProducer.main:27 - Sent 2:311873768
09:45:43.515 INFO  io.confluent.csta.TLSProducer.main:27 - Sent 3:586727041
09:45:43.515 INFO  io.confluent.csta.TLSProducer.main:27 - Sent 4:186154275
09:45:43.544 INFO  io.confluent.csta.Main.main:13 - Running the TLS Consumer...
09:45:46.839 INFO  io.confluent.csta.TLSConsumer.main:25 - Partition: 0 Offset: 0 Value: 293536560 Thread Id: 1
09:45:46.839 INFO  io.confluent.csta.TLSConsumer.main:25 - Partition: 0 Offset: 1 Value: 416980828 Thread Id: 1
09:45:46.839 INFO  io.confluent.csta.TLSConsumer.main:25 - Partition: 0 Offset: 2 Value: 311873768 Thread Id: 1
09:45:46.840 INFO  io.confluent.csta.TLSConsumer.main:25 - Partition: 0 Offset: 3 Value: 586727041 Thread Id: 1
09:45:46.840 INFO  io.confluent.csta.TLSConsumer.main:25 - Partition: 0 Offset: 4 Value: 186154275 Thread Id: 1
```

## Exploring the TLS Producer and Consumer code

If you look in `src/main/java`, there are examples for Producer, Consumer, ReST Proxy and Schema Registry clients.

If you look in `ClientTools.java`, for the Consumer we would need the following lines in the configuration map to allow it to access the truststore and keystore (and passwords):

```java
        props.put("bootstrap.servers", "broker:9092");

        // This is the necessary configuration for configuring TLS/SSL on the Producer
        props.put("security.protocol", "SSL");
        props.put("ssl.truststore.location", "/etc/kafka/secrets/client.truststore.jks");
        props.put("ssl.truststore.password", "confluent");
        props.put("ssl.keystore.location", "/etc/kafka/secrets/client.keystore.jks");
        props.put("ssl.keystore.password", "confluent");
        props.put("schema.registry.url", "https://schema-registry:8081");
```

Similarly for the Producer:

```java
        props.put("bootstrap.servers", "broker:9092");

        // This is the necessary configuration for configuring TLS/SSL on the Producer
        props.put("security.protocol", "SSL");
        props.put("ssl.truststore.location", "/etc/kafka/secrets/client.truststore.jks");
        props.put("ssl.truststore.password", "confluent");
        props.put("ssl.keystore.location", "/etc/kafka/secrets/client.keystore.jks");
        props.put("ssl.keystore.password", "confluent");
        props.put("schema.registry.url", "https://schema-registry:8081");
```

Note that in both cases, you're specifying `https` when you connect to the Schema Registry instance.

## Endpoints

- <http://localhost:9021/>
- <http://localhost:8082/>

## Exploring the `tools` container

If you want to explore the cluster using the command-line, there is a container called `tools`, which is configured with a number of applications (see the `Dockerfile` in the `tools` directory if you want to see what gets installed).   To connect to the instance, you can run:

```bash
docker exec -it tools bash
```

Or if you prefer:

```bash
docker-compose exec tools bash
```

From there, you can find the keystores and truststores in `/etc/kafka/secrets`.

### Running a Consumer from the container

Consumer without TLS on port 9091:

```bash
cd /opt/kafka/bin/
./kafka-console-consumer.sh --bootstrap-server broker:9091 --topic test-topic --from-beginning
```

Consumer with TLS on port 9092:

```bash
./kafka-console-consumer.sh --bootstrap-server broker:9092 --topic test-topic --from-beginning --consumer.config /tmp/client.properties
```

where `/tmp/client.properties` contains the following:

```properties
security.protocol=SSL
ssl.truststore.location=/etc/kafka/secrets/client.truststore.jks
ssl.truststore.password=confluent
ssl.keystore.location=/etc/kafka/secrets/client.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
```

### Producing with TLS

Similarly, you can use the same `client.properties` to configure the `kafka-console-producer` with TLS:

```bash
./kafka-console-producer.sh --bootstrap-server broker:9092 --topic test-topic --producer.config /tmp/client.properties
```
