
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

TODO - finish
`vim create-server-certs.sh`

```
echo "Step 1: Root Certificate (CA)"
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout certs/ca-key -out certs/ca-cert -nodes
echo "Step 2"
keytool -genkey -keystore certs/kafka.server.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=localhost" -storetype pkcs12 -keyalg RSA
echo "Step 3"
keytool -keystore certs/kafka.server.keystore.jks -certreq -file certs/cert-file -storepass confluent -keypass confluent
echo "Step 4"
openssl x509 -req -CA certs/ca-cert -CAkey certs/ca-key -in certs/cert-file -out certs/cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 5"
keytool -keystore certs/kafka.server.truststore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 6"
keytool -keystore certs/kafka.server.keystore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 7"
keytool -keystore certs/kafka.server.keystore.jks -import -file certs/cert-signed -storepass confluent -keypass confluent -noprompt
echo "Step 8"
tee certs/broker_sslkey_creds << EOF >/dev/null
confluent
EOF

```

`create-client-certs.sh`

```
echo "Step 9: Client Truststore"
keytool -keystore certs/kafka.client.truststore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 10: Client Keystore"
keytool -genkey -keystore certs/kafka.client.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=localhost" -alias my-local-pc -storetype pkcs12 -keyalg RSA
echo "Step 11: Client Cert signing request"
keytool -keystore certs/kafka.client.keystore.jks -certreq -file certs/client-cert-sign-request -alias my-local-pc -storepass confluent -keypass confluent
echo "Step 12: Sign Client Certificate"
openssl x509 -req -CA certs/ca-cert -CAkey certs/ca-key -in certs/client-cert-sign-request -out certs/client-cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 13: Import the signed client certificate and the CA into the keystore"
keytool -keystore certs/kafka.client.keystore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 13: Add Certificate Reply"
keytool -keystore certs/kafka.client.keystore.jks -import -file certs/client-cert-signed -alias my-local-pc -storepass confluent -keypass confluent -noprompt
```

Config:

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

bin/kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic kafka-test --consumer.config ~/Documents/workspace/client-ssl-auth.properties --from-beginning