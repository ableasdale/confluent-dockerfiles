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

Here's another example that uses the `-d` (domain) and `-b` (bean) switches:

```terminal
$>get -d rest-utils -b type=jersey-metrics  request-total
#mbean = rest-utils:type=jersey-metrics:
request-total = 0.0;
```

When you're finished, you can exit the JMXTerm session by running:

```terminal
$>exit
#bye
```

And you can exit the shell session on the `broker` instance by running `exit` again at the prompt:

```terminal
[appuser@broker ~]$ exit
exit
```

## JConsole

JMXTerm is great - but that's a lot of typing!  It might make sense to look at `JConsole` next, let's start it (note that you don't need to be in a shell session in the container for this):

```bash
jconsole
```

This will open a GUI Tool to allow you to view the JMX Metrics in a tree view.  

To connect, you need two values from the `docker-compose.yaml` file:

```properties
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost
```

To establish the JMX connection, select the **Remote Process** option and enter `localhost:9101` into the input field:

![Connect to JMX](jconsole.png)

There will be a warning about not being able to connect using TLS (SSL), let's ignore this for now and specify that we're fine to establish an insecure connection.

Along the top, you should see a tab called **MBeans**, select this and all the JMX Domains should be listed in a folder view on the left-hand panel.  From there, you can dig into any particular JMX Metric as necessary:

![View MBean](mbean.png)

### Jolokia

Jolokia is available on port 8778 and it's a ReST API, so you can ask it to `/list` and `/read` values for you:

- http://localhost:8778/jolokia/list
- http://localhost:8778/jolokia/read/java.lang:type=Runtime/Name
- http://localhost:8778/jolokia/read/kafka.controller:name=ActiveBrokerCount,type=KafkaController

http://localhost:8778/jolokia/read/java.lang:type=GarbageCollector,*
LastGcInfo

Example Jolokia output for `ActiveBrokerCount` (returned as JSON):

```json
{"request":{"mbean":"kafka.controller:name=ActiveBrokerCount,type=KafkaController","type":"read"},"value":{"Value":1},"status":200,"timestamp":1715327704}
```

And of course, you can use a tool like `cURL` to gather those metrics too:

```bash
curl -s localhost:8778/jolokia/list | python3 -m json.tool
```

#### Using an HTTP POST Request with a JSON Payload

```bash
curl --json @payload.json  http://localhost:8778/jolokia/
```

Where an example payload is:

```json
[
  {
    "type" : "read",
    "attribute" : "HeapMemoryUsage",
    "mbean" : "java.lang:type=Memory",
    "path" : "used"
  },
  {
    "type" : "search",
    "mbean" : "*:type=Memory,*"
  }
]
```


## JMXTool

We have to run this directly on the broker:

```bash
docker exec -it broker /bin/bash
```

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=KafkaRequestHandlerPool,name=RequestHandlerAvgIdlePercent \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 > filename.csv
```

You should see:

```bash
Trying to connect to JMX url: service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi
```

After JMXTool has run for a while, you should see some output in your csv file:

```csv
1715338651075,25329887207625,percent,1.9993699989996927,1.9996093560199015,1.9990898175825642,2.0009824284484403,NANOSECONDS
1715338652075,25331862709017,percent,1.9993699989996927,1.9996093560199015,1.9990879928187326,2.0009824284484403,NANOSECONDS
```

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=([-.\w]+),topic=([-.\w]+),partition=([0-9]+) \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```
#### BytesInPerSec

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```
#### BytesInPerSec - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### MessagesInPerSec

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### MessagesInPerSec - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### Wildcard - kafka.server: all metrics

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.serve?:* \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```
#### Wildcard - kafka.server: all metrics - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.serve?:* --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### Multiple Wildcards - kafka.*:* - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.*:* --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```
#### Property List Wildcard - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.server:type=BrokerTopicMetrics,* --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### Property Value Wildcard - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.server:type=BrokerTopicMetrics,name=*InPerSec --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

#### Wildcard on Lists and Properties - FifteenMinuteRate

```bash
kafka-run-class org.apache.kafka.tools.JmxTool  \
  --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec --object-name kafka.server:type=*,* --attributes Count,FifteenMinuteRate \
  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
  --reporting-interval 1000 
```

### Notes below

```
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
```