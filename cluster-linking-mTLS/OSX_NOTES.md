
Install Kafka and unpack the tgz file
https://kafka.apache.org/downloads


```bash
cd Documents/workspace/kafka_2.13-3.4.0
```

Start Zk:

```bash
bin/zookeeper-server-start.sh config/zookeeper.properties
```

Start Kafka:

```bash
bin/kafka-server-start.sh config/server.properties
```

bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic kafka-test


```properties
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://localhost:9092
```

## Test Producer

bin/kafka-console-producer.sh --bootstrap-server c02gg0j6md6t.home:9092 --topic kafka-test

## Test Consumer

bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic kafka-test --from-beginning

Now let's set up TLS and the broker certs!

```properties
# TLS / SSL
ssl.keystore.location=/Users/ableasdale/Documents/workspace/certs/kafka.server.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
ssl.truststore.location=/Users/ableasdale/Documents/workspace/certs/kafka.server.truststore.jks
ssl.truststore.password=confluent
```

And add the listener:

```properties
listeners=PLAINTEXT://:9092,SSL://:9093
advertised.listeners=PLAINTEXT://localhost:9092,SSL://localhost:9093
```

Test

```bash
curl -k -v --cert-type P12 --cert ~/Documents/workspace/certs/kafka.server.keystore.jks:confluent https://localhost:9093
```

Now let's configure the client certs and stores..

```
security.protocol=SSL
ssl.truststore.location=/Users/ableasdale/Documents/workspace/certs/kafka.client.truststore.jks
ssl.truststore.password=confluent
ssl.keystore.location=/Users/ableasdale/Documents/workspace/certs/kafka.client.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
```

Final test:
```
bin/kafka-console-producer.sh --bootstrap-server localhost:9093 --topic kafka-test --producer.config ~/Documents/workspace/client-ssl-auth.properties
```

Not working! :(  So... works in ubuntu with standalone kafka... doesn't work in osx... :(