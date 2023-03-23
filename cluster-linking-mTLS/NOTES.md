
## Configure sshd?

## SSH into the instance

ssh vboxuser@192.168.1.221
PWD: changeme
ssh vboxuser@Ubuntu

## Set up the VM

Install VBox tools: 

cd /media/vboxuser/VBox_GAs_7.0.6/
./VBoxLinuxAdditions.run

I also installed jvm, downloaded kafka and tar xvfzd it...

## Test Kafka

cd /home/vboxuser/Downloads/kafka_2.13-3.4.0
bin/zookeeper-server-start.sh config/zookeeper.properties
bin/kafka-server-start.sh config/server.properties

### Producer test from host

cd /home/vboxuser/Downloads/kafka_2.13-3.4.0
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic kafka-test

### Consumer test from host

bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic kafka-test

*** NOT WORKING! ***

so, let's take a look:

su
Password:
root@Ubuntu:/home/vboxuser/Downloads/kafka_2.13-3.4.0# apt install vim
vim config/server.properties

visudo
vboxuser    ALL=(ALL:ALL) ALL

** uncomment listeners and advertised listeners

```
listeners=PLAINTEXT://:9092

# Listener name, hostname and port the broker will advertise to clients.
# If not set, it uses the value for "listeners".
advertised.listeners=PLAINTEXT://Ubuntu:9092
```

still not working... hmm...

was the topic created?

```bash
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Yep - we see kafka-test there! 

Has it been created with wonky settings?

```bash
Topic: kafka-test	TopicId: d8InAfy_SW279GLaet8-cg	PartitionCount: 1	ReplicationFactor: 1	Configs:
	Topic: kafka-test	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
```

looks good!

oops! missed out --from-beginning with the consumer:

```
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic kafka-test --from-beginning
```

## cruft

bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic kafka-test

kafka-topics --bootstrap-server broker1:9091 --topic demo-perf-topic --replication-factor 3 --partitions 1 --create --config min.insync.replicas=2



### Producer test from Desktop machine

```bash
~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --bootstrap-server 192.168.1.221:9092 --topic kafka-test
```
~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --bootstrap-server Ubuntu:9092 --topic kafka-test

### Consumer test from Desktop machine

```bash
~/Documents/kafka_2.13-3.4.0/bin/kafka-console-consumer.sh --bootstrap-server Ubuntu:9092 --topic kafka-test --from-beginning
```

Ok! great - all the simple tests are working... Let's set up mTLS!

## Create the TLS infra

```bash
cd ~/Documents/
vim create-server-certs.sh
```

```sh
echo "Step 1: Root Certificate (CA)"
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout certs/ca-key -out certs/ca-cert -nodes
echo "Step 2"
keytool -genkey -keystore certs/kafka.server.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=Ubuntu" -storetype pkcs12 -keyalg RSA
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

```bash
chmod a+x create-server-certs.sh
./create-server-certs.sh
```

Now let's configure Apache Kafka with our new certs!

```bash
sudo vim config/server.properties
```

Add the following:

```properties
# TLS / SSL
ssl.keystore.location=/home/vboxuser/Documents/certs/kafka.server.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
ssl.truststore.location=/home/vboxuser/Documents/certs/kafka.server.truststore.jks
ssl.truststore.password=confluent
```

And configure the SSL listeners:

```properties
listeners=PLAINTEXT://:9092,SSL://:9093
advertised.listeners=PLAINTEXT://Ubuntu:9092,SSL://Ubuntu:9093
```

Test the new endpoint:

```bash
openssl s_client -connect localhost:9093 -tls1_2 -showcerts
openssl s_client -connect localhost:9093 -tls1_3 -showcerts
sudo apt install curl
curl -k -v --cert-type P12 --cert ~/Documents/certs/kafka.server.keystore.jks:confluent https://localhost:9093
```

Let's configure the client certs and stores!

```bash
vim create-client-certs.sh
```

```sh
echo "Step 9: Client Truststore"
keytool -keystore certs/kafka.client.truststore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 10: Client Keystore"
keytool -genkey -keystore certs/kafka.client.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=Ubuntu" -alias my-local-pc -storetype pkcs12 -keyalg RSA
echo "Step 11: Client Cert signing request"
keytool -keystore certs/kafka.client.keystore.jks -certreq -file certs/client-cert-sign-request -alias my-local-pc -storepass confluent -keypass confluent
echo "Step 12: Sign Client Certificate"
openssl x509 -req -CA certs/ca-cert -CAkey certs/ca-key -in certs/client-cert-sign-request -out certs/client-cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 13: Import the signed client certificate and the CA into the keystore"
keytool -keystore certs/kafka.client.keystore.jks -alias CARoot -import -file certs/ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 13: Add Certificate Reply"
keytool -keystore certs/kafka.client.keystore.jks -import -file certs/client-cert-signed -alias my-local-pc -storepass confluent -keypass confluent -noprompt

```

```bash
chmod a+x create-client-certs.sh
```

We need to add some configuration to server.properties

## Configure the Kafka Broker to require SSL client Authentication

Now we need to edit the `server.properties` on the **broker**:

```bash
sudo vim config/server.properties
```

We need to add the following line to the broker's properties file:

```properties
# Client Authentication
ssl.client.auth=required
```

## Create the Client SSL Authentication Properties File

On your **client** machine, you need to create a properties file:

```bash
vim client-ssl-auth.properties
```

We're adding the following lines to the `client-ssl-auth.properties` properties file:

```properties
security.protocol=SSL
ssl.truststore.location=/home/vboxuser/Documents/certs/kafka.client.truststore.jks
ssl.truststore.password=confluent
ssl.keystore.location=/home/vboxuser/Documents/certs/kafka.client.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
```

## Test producer

```bash
bin/kafka-console-producer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test --producer.config ~/Documents/client-auth.properties
```

## Test Consumer

```bash
bin/kafka-console-consumer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test --consumer.config ~/Documents/client-auth.properties --from-beginning
```

Everything works as expected!  Let's now try to get the producer and consumer to run from a remote machine

```bash
scp vboxuser@Ubuntu:~/Documents/client-auth.properties .
scp vboxuser@Ubuntu:~/Documents/certs/kafka.client.keystore.jks .
scp vboxuser@Ubuntu:~/Documents/certs/kafka.client.truststore.jks .
```

Modify the properties file:

```bash
security.protocol=SSL
ssl.truststore.location=kafka.client.truststore.jks
ssl.truststore.password=confluent
ssl.keystore.location=kafka.client.keystore.jks
ssl.keystore.password=confluent
ssl.key.password=confluent
```

### Producer

```bash
~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test --producer.config client-auth.properties
```

### Consumer

```bash
~/Documents/kafka_2.13-3.4.0/bin/kafka-console-consumer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test --consumer.config client-auth.properties --from-beginning
```


~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh


~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test

~/Documents/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --bootstrap-server Ubuntu:9093 --topic kafka-test --producer.config ~/Documents/

