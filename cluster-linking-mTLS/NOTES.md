
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

bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

Yep - we see kafka-test there! 

Has it been created with wonky settings?
Topic: kafka-test	TopicId: d8InAfy_SW279GLaet8-cg	PartitionCount: 1	ReplicationFactor: 1	Configs:
	Topic: kafka-test	Partition: 0	Leader: 0	Replicas: 0	Isr: 0

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

