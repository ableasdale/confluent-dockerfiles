# JMX (Jolokia) Testing Environment

This environment consists of:

- 1 Broker (running Kraft Mode)
- Confluent Control Center (C3)
- Schema Registry

For the broker, JMX is configured on TCP port **9101**
The Jolokia agent is configured on TCP port **8778** 

As of May 2024, all components are running CP 7.6.1.

## Getting Started

To start the components, from a terminal, run:

```bash
docker-compose up -d
```

As soon as the broker is started, you can start a shell session by running:

```bash
docker exec -it broker /bin/bash
```

## JMXTerm

To start working with JMXTerm, from a shell session to the `broker` container, run:

```bash
java -jar /usr/share/jmx-term/jmxterm-1.0.4-uber.jar
```

From there, you can get a list of JVMs to connect to by running the `jvms` command:

```terminal
$>jvms
1        (m) - kafka.Kafka /etc/kafka/kafka.properties
363      ( ) - jmxterm-1.0.4-uber.jar
```

To open the session with the Kafka broker, use the `open <pid>` command:

```terminal
$>open 1
#Connection to 1 is opened
```

Start by getting a list of all the JMX domains:

```terminal
domains
```

Select a domain by running:

```terminal
$>domain kafka.controller
#domain is set to kafka.controller
```

List all available JMX beans within the domain by running:

```terminal
beans
```

Let's choose a JMX metric (`ActiveBrokerCount`) to dig into more detail:

```terminal
$>bean kafka.controller:name=ActiveBrokerCount,type=KafkaController
#bean is set to kafka.controller:name=ActiveBrokerCount,type=KafkaController
```

Use the `info` command to find out what metrics are available:

```terminal
$>info
#mbean = kafka.controller:name=ActiveBrokerCount,type=KafkaController
#class name = com.yammer.metrics.reporting.JmxReporter$Gauge
# attributes
  %0   - Value (java.lang.Object, r)
# operations
  %0   - javax.management.ObjectName objectName()
#there's no notifications
```

We can see that there is a `Value` attribute, so we can run `get Value` to get the value for the JMX Bean to find out that there is one active broker available:

```terminal
$>get Value
#mbean = kafka.controller:name=ActiveBrokerCount,type=KafkaController:
Value = 1;
```

## JConsole

```bash
jconsole
```

![Connect to JMX](jconsole.png)

![View MBean](mbean.png)

### Jolokia

- http://localhost:8778/jolokia/list
- http://localhost:8778/jolokia/read/java.lang:type=Runtime/Name
- 

```bash
curl -s localhost:8778/jolokia/list | python3 -m json.tool
```

### Notes below
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"