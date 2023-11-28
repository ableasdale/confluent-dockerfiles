# Schema Linking Walkthrough Scenarios

We're going to cover two scenarios in this walkthrough:

An Active/Passive Schema Registry setup (where only one Schema Registry can be written to).
Then we will demonstrate a way to perform an Active/Active setup - we will show the drawbacks and trade-offs for both solutions.

## Getting Started

Start up all the containers for this demo:

```bash
docker-compose up -d
```

Then visit <http://localhost:9021/> to confirm that Confluent Control Center is available.

## Schema Linking: Active/Passive Setup

First we will start by configuring Schema Linking to copy the default context from one Schema Registry to another - in this setup, we have one Schema Registry which is writeable and the other that is read-only.  We will start by setting up this configuration.

### Configure Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-type NONE
```

You should see the message in response:

```bash
Successfully created exporter src-to-tgt-link
```

Verify that the Schema Link is available:

```bash
docker-compose exec schemaregistry schema-exporter --list --schema.registry.url http://schemaregistry:8081
```

You shoudld see the link being listed in the response:

```bash
[src-to-tgt-link]
```

The following command can be run (`--get-status`) to confirm that the link is running as expected:

```bash
docker-compose exec schemaregistry schema-exporter --get-status --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081
```

You should see something like this in response:

```json
{"name":"src-to-tgt-link","state":"RUNNING","offset":-1,"ts":0}
```

Let's start a connector and make sure we can see the Schema on both sides:

#### Create `pageviews` Datagen on Source

```bash
curl -i -X PUT http://localhost:8083/connectors/pageviews/config \
     -H "Content-Type: application/json" \
     -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "pageviews",
            "quickstart": "pageviews",
            "max.interval": 1000,
            "iterations": 10000000,
            "tasks.max": "1"
        }'
```

You should see an `HTTP 201` response code:

```bash
HTTP/1.1 201 Created
```

If you run this request to get the list of subjects:

```bash
curl http://localhost:8081/subjects/
```

You should see this in response:

```json
["pageviews-value"]
```

Let's now confirm that the Schema is available on the second Schema Registry instance:

```bash
curl http://localhost:8082/subjects/
```

This confirms that the Schema is available:

```json
["pageviews-value"]
```

#### Demonstrate that the Schema is identical on both sides

```bash
curl http://localhost:8081/subjects/pageviews-value/versions/1 | md5
curl http://localhost:8082/subjects/pageviews-value/versions/1 | md5
```

In both cases, we can confirm that the MD5 checksum is identical:

```bash
7586b6964c0772cad625264fea2ddc49
```

Let's read some of those messages back:

```bash
docker-compose exec connect kafka-avro-console-consumer \
 --bootstrap-server broker:29091 \
 --property schema.registry.url=http://schemaregistry:8081 \
 --topic pageviews \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

Okay - that's great; it shows us that we can retrieve the original schema and use `kafka-avro-console-consumer` to read back the messages.  Let's now perform the same operation - only this time, we're specifying the second Schema Registry instance (reading the Schema Linked copy of the Schema):

```bash
docker-compose exec connect2 kafka-avro-console-consumer \
 --bootstrap-server broker:29091 \
 --property schema.registry.url=http://schemaregistry2:8082 \
 --topic pageviews \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

Important to note here that while we're retrieving the Schema from our second (`read-only`) Schema Registry although we're retrieving the messages from the first Kafka broker - this is because we're not replicating the Datagen data in this example.

So that covers Schema Linking using the Default Context of the first Schema Registry and replicating that to the Default Context of the second Schema Registry.  

Next we'll look at the Active/Active configuration - and you'll see why the Active/Passive architecture has some advantages through it's simplicity.

## Schema Linking: Active/Active Setup (with specific subjects)

For an **Active/Active** setup, we're going to set up `schema-exporter` for bi-directional Schema Linking, so we're going to maintain two links:

- One going from the Schema Registries of the `source` to the `target` cluster.
- One going from the Schema Registries of the `target` to the `source` cluster.

We're going to start by demonstrating the process for replicating a subject on each side:

- On the `source` cluster, we're going to replicate the `pageviews-value` subject over to our `target` cluster.
- On the `target` cluster, we're going to replicate the `stock_trades-value` subject over to our `source` cluster.

### Configure Schema Exporter to replicate from Source to Target cluster

First, let's configure Schema Exporter to replicate the `pageviews-value` subject from the Source to Target cluster:

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg --subjects pageviews-value \
    --schema.registry.url http://schemaregistry:8081 \
    --context-name source --context-type CUSTOM
```

### Configure Schema Exporter to replicate from Target and Source cluster

Secondly, the Schema Exporter will be configured to replicate the `stock_trades-value` subject from the Target to Source cluster:

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg --subjects stock_trades-value \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

The following command can be run (`--get-status`) to confirm that the link from `source` to `target` is running as expected:

```bash
docker-compose exec schemaregistry schema-exporter --get-status --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081
```

You should see:

```json
{"name":"src-to-tgt-link","state":"RUNNING","offset":2,"ts":1701201449055}
```

And now we will check the status of the second link (from the `target` to the `source`):

```bash
docker-compose exec schemaregistry2 schema-exporter --get-status --name tgt-to-src-link --schema.registry.url http://schemaregistry2:8082
```

You should see:

```json
{"name":"tgt-to-src-link","state":"RUNNING","offset":-1,"ts":0}
```

With the links created (and verified), now let's create our Datagen connectors.

### Create `pageviews` Datagen on Source

```bash
curl -i -X PUT http://localhost:8083/connectors/pageviews/config \
     -H "Content-Type: application/json" \
     -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "pageviews",
            "quickstart": "pageviews",
            "max.interval": 1000,
            "iterations": 10000000,
            "tasks.max": "1"
        }'
```

If successful, the output response from this `curl` request should return an `HTTP 201` Status code:

```bash
HTTP/1.1 201 Created
```

### Create `stock_trades` Datagen on Target

```bash
curl -i -X PUT http://localhost:8084/connectors/stock_trades/config \
     -H "Content-Type: application/json" \
     -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "stock_trades",
            "quickstart": "stock_trades",
            "max.interval": 1000,
            "iterations": 10000000,
            "tasks.max": "1"
        }'
```

Again, the output response from this `curl` request should return an `HTTP 201` Status code:

```bash
HTTP/1.1 201 Created
```

With everything created, the next task is to visit <http://localhost:9021/> to confirm that Confluent Control Center is available and that topic data is visibly being created in each case.

### Let's take a look at the Schemas

Let's start by inspecting the `pageviews-value` subject on the first Schema Registry instance:

```bash
curl http://localhost:8081/subjects/pageviews-value/versions/1
```

```bash
curl http://localhost:8082/subjects/pageviews-value/versions/1
```

At a quick glance, these schemas may look different - and this is with good reason; they are:

```bash
curl --silent http://localhost:8081/subjects/pageviews-value/versions/1 | md5
curl --silent http://localhost:8082/subjects/pageviews-value/versions/1 | md5
```

The `md5` checksums confirm this: they are not the same:

```bash
7586b6964c0772cad625264fea2ddc49
ad2d29c1101ce8b2cb4f68afba28e3e9
```

Why?  Well this is because we're now introducing Contexts into the mix.  Let's take a further look - we can do this by using the `/contexts` endpoint that Schema Registry now supports.

### Explore the Schema Contexts

```bash
curl -X GET http://localhost:8081/contexts
```

```json
[".",".target"]
```

```bash
curl -X GET http://localhost:8082/contexts
```

```json
[".",".source"]
```

In order for the writes to happen (to the default Context) on both sides, we've created contexts on each side to represent the inbound schema data on the other side; so on the `source` Schema Registry, we now have a `target` context; and on the `target` Schema Registry, we have our `source` context.

So what does this mean for our schemas? Let's inspect the same two again..  Starting with the `pageviews-value` subject on the `source` Schema Registry:

```bash
curl http://localhost:8081/subjects/pageviews-value/versions/1
```

We see:

```json
{"subject":"pageviews-value" [...]}
```

If we inspect the `pageviews-value` subject on the `target` Schema Registry:

```json
{"subject":":.source:pageviews-value", [...]}
```

We can immediately see why the `MD5` checksums were different - when Schema Linking is used with Contexts, Schema Registry adds a namespace segment to the subject name.

So what does this mean for our Consumers?  We will start by attempting to read the topic data using the `source` Schema Registry first: 

```bash
docker-compose exec connect kafka-avro-console-consumer \
 --bootstrap-server broker:29091 \
 --property schema.registry.url=http://schemaregistry:8081 \
 --topic pageviews \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

As expected, everything works without issue: we see 10 messages and we can see that there is no sequence of magic bytes at the beginning of each String - meaning that the Schema has been identifed and the messages are being consumed correctly:

```bash
34721 : {"viewtime":34721,"userid":"User_2","pageid":"Page_32"}
34731 : {"viewtime":34731,"userid":"User_7","pageid":"Page_22"}
```

What happens if we try to use our other schema (the one in the `source` context on the `target` schema registry)?

```bash
docker-compose exec connect2 kafka-avro-console-consumer \
 --bootstrap-server broker:29091 \
 --property schema.registry.url=http://schemaregistry2:8082 \
 --topic pageviews \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

So it looks like there are no issues reading the topic data when using the schema in the `source` context.  Now, we set up two datagen connectors - one on each side; let's briefly confirm that we can read from the `stock_trades` datagen topics too.

Just as a quick reminder:

```bash
curl http://localhost:8082/subjects/
```

```json
[":.source:pageviews-value","stock_trades-value"]
```

```bash
curl http://localhost:8081/subjects/
```

```json
[":.target:stock_trades-value","pageviews-value"]
```

We want to read our `stock_trades-value` schema from the `target` cluster (the one configured to listen on port `8082`) and we're going to read the replicated schema (`:.target:stock_trades-value`) from our `source` cluster (listening on port `8081`).

Before that, let's just perform one more check to confirm that the schemas are materially different (because of the separate contexts):

```bash
curl --silent http://localhost:8082/subjects/stock_trades-value/versions/1 | md5
curl --silent http://localhost:8081/subjects/stock_trades-value/versions/1 | md5
```

The response output confirms that this is the case:

```bash
4df985e4e6d8a504c37ae4b25201575b
000b0ecfb8706e94dc0fcd8e4787aa44
```

First, read the topic data from the `target` cluster

```bash
docker-compose exec connect2 kafka-avro-console-consumer \
 --bootstrap-server broker2:29092 \
 --property schema.registry.url=http://schemaregistry2:8082 \
 --topic stock_trades \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

And everything looks good - as expected, we can read the data as Avro:

```bash
ZWZZT : {"side":"BUY","quantity":2899,"symbol":"ZWZZT","price":648,"account":"ABC123","userid":"User_5"}
ZVZZT : {"side":"SELL","quantity":4859,"symbol":"ZVZZT","price":349,"account":"XYZ789","userid":"User_1"}
```

Now we're going to read the messages using the `:.target:stock_trades-value` schema on the first Schema Registry instance:

```bash
docker-compose exec connect2 kafka-avro-console-consumer \
 --bootstrap-server broker2:29092 \
 --property schema.registry.url=http://schemaregistry:8081 \
 --topic stock_trades \
 --property print.key=true \
 --property key.deserializer=org.apache.kafka.common.serialization.StringDeserializer \
 --property key.separator=" : " \
 --max-messages 10
```

Everything looks fine:

```bash
ZJZZT : {"side":"BUY","quantity":3357,"symbol":"ZJZZT","price":744,"account":"LMN456","userid":"User_1"}
ZBZX : {"side":"SELL","quantity":700,"symbol":"ZBZX","price":412,"account":"XYZ789","userid":"User_9"}
```

To clean up everything and restart, run:

```bash
docker-compose down && docker container prune -f && docker-compose up -d
```

(TODO - check ^^)

## Schema Linking: Active/Active Setup (with replicated Contexts)

Now we're going to do something a little different - rather than specifying individual `--subjects`, we're going to just replicate the Default context on each Schema Registry to a separate Context on both sides.

We will start by creating the Cluster Links - note that we're not specifying subjects in either case this time:

### Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-name source --context-type CUSTOM
```

### Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

As with the previous run, you should see the following responses respectively:

```bash
Successfully created exporter src-to-tgt-link
Successfully created exporter tgt-to-src-link
```

Before we can configure the Datagen connectors, we need to add a further step for this to work - we need to set our `source` and `target` Contexts (on the `target` and the `source` host respectively) into `IMPORT` mode; failure to do this will cause Connectors to fail to start.

### Set the `source` Context into `IMPORT` mode

```bash
curl --silent -X PUT http://localhost:8082/mode/:.source: -d "{  \"mode\": \"IMPORT\"}" -H "Content-Type: application/json"
```

You should see the following JSON in the response:

```json
{"mode":"IMPORT"}
```

Let's confirm that the `.source` context has been set to `IMPORT` mode:

```bash
curl --silent -X GET http://localhost:8082/mode/:.source: | jq
```

And we should see this confirmed in the response:

```json
{
  "mode": "IMPORT"
}
```




curl -X GET http://localhost:8082/mode/:.source: | jq







---- NOTES BELOW

### Configure Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-type NONE
```







## Bidirectional Cluster Linking walkthrough

Schema Exporter from Source to Target cluster



    curl --silent -X PUT http://localhost:8086/mode/:.left: -d "{  \"mode\": \"IMPORT\"}" -H "Content-Type: application/json"
    # confirm change was applied
    curl --silent -X GET http://localhost:8086/mode/:.left:

curl --silent -X GET http://localhost:8081/mode/:.target:


## This set works

Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg --subjects pageviews-value \
    --schema.registry.url http://schemaregistry:8081
```

Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg --subjects stock_trades-value \
    --schema.registry.url http://schemaregistry2:8082
```









Then

```bash
curl -X GET http://localhost:8081/contexts
```
curl --silent -X PUT http://localhost:8082/mode/:.source: -d "{  \"mode\": \"IMPORT\"}" -H "Content-Type: application/json"

Confirm

curl --silent -X GET http://localhost:8082/mode/:.source:

You should see:

```json
{"mode":"IMPORT"}
```



docker-compose exec schemaregistry2 schema-exporter --list --schema.registry.url http://schemaregistry2:8082

curl --silent -X PUT http://localhost:8081/mode/:.target: -d "{  \"mode\": \"IMPORT\"}" -H "Content-Type: application/json"

curl --silent -X GET http://localhost:8081/mode/:.target:

```bash
curl http://localhost:8082/subjects/
```

```json
[":.source:pageviews-value","stock_trades-value"]
```

```bash
curl http://localhost:8081/subjects/
```

```json
[":.target:stock_trades-value","pageviews-value"]
```

❯ curl http://localhost:8081/subjects/pageviews-value/versions/1
{"subject":"pageviews-value","version":1,"id":1,"schema":"{\"type\":\"record\",\"name\":\"pageviews\",\"namespace\":\"ksql\",\"fields\":[{\"name\":\"viewtime\",\"type\":\"long\"},{\"name\":\"userid\",\"type\":\"string\"},{\"name\":\"pageid\",\"type\":\"string\"}],\"connect.name\":\"ksql.pageviews\"}"}%

❯ curl http://localhost:8082/subjects/pageviews-value/versions/1
{"subject":":.source:pageviews-value","version":1,"id":1,"schema":"{\"type\":\"record\",\"name\":\"pageviews\",\"namespace\":\"ksql\",\"fields\":[{\"name\":\"viewtime\",\"type\":\"long\"},{\"name\":\"userid\",\"type\":\"string\"},{\"name\":\"pageid\",\"type\":\"string\"}],\"connect.name\":\"ksql.pageviews\"}"}%

nc -zv localhost 8081
telnet localhost 8081
curl -X GET http://localhost:8081/config



curl --silent -X PUT http://localhost:8082/mode/:.source: -d "{  \"mode\": \"IMPORT\"}" -H "Content-Type: application/json"

Get schemas from all contexts:

```bash
curl -X GET http://localhost:8082/schemas?subjectPrefix=:*:
```

Get schemas from a given Schema Registry Context:

```bash
curl -X GET http://localhost:8082/schemas?subjectPrefix=:.source:
```

```bash
curl -X GET http://localhost:8081/schemas?subjectPrefix=:.target:
```






docker-compose exec schemaregistry schema-exporter --list --schema.registry.url http://schemaregistry:8081

docker-compose exec schemaregistry2 schema-exporter --list --schema.registry.url http://schemaregistry2:8082


docker-compose exec schemaregistry schema-exporter --get-status --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081

docker-compose exec schemaregistry2 schema-exporter --get-status --name tgt-to-src-link --schema.registry.url http://schemaregistry2:8082

curl http://localhost:8081/subjects/
curl http://localhost:8082/subjects/

curl http://localhost:8081/subjects/pageviews-value/versions/1
curl http://localhost:8081/schemas/ids/1 | jq




## Consume from topic using both SR instances



## Create `pageviews` Datagen on Source

```bash
curl -i -X PUT http://localhost:8083/connectors/pageviews/config \
     -H "Content-Type: application/json" \
     -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "pageviews",
            "quickstart": "pageviews",
            "max.interval": 1000,
            "iterations": 10000000,
            "tasks.max": "1"
        }'
```

## Create `stock_trades` Datagen on Target

```bash
curl -i -X PUT http://localhost:8084/connectors/stock_trades/config \
     -H "Content-Type: application/json" \
     -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "stock_trades",
            "quickstart": "stock_trades",
            "max.interval": 1000,
            "iterations": 10000000,
            "tasks.max": "1"
        }'
```