# Schema Linking Walkthrough Scenarios

We're going to cover two scenarios in this walkthrough:

An **Active/Passive** Schema Registry setup (where only one Schema Registry can be written to).
Then we will demonstrate a way to perform an **Active/Active** setup - we will show the drawbacks and trade-offs for both solutions.

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

### Demonstrate that the Schema is identical on both sides

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

Next we'll look at the **Active/Active** configuration - and you'll see why the **Active/Passive** architecture has some advantages through it's simplicity.

To clean up everything and restart, run:

```bash
docker-compose down && docker container prune -f && docker-compose up -d
```

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

So what does this mean for our schemas? Let's inspect the same two again - starting with the `pageviews-value` subject on the `source` Schema Registry:

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
curl --silent http://localhost:8082/subjects/ | jq
```

And we should see:

```json
[
  ":.source:pageviews-value",
  "stock_trades-value"
]
```

```bash
curl --silent http://localhost:8081/subjects/ | jq
```

```json
[
  ":.target:stock_trades-value",
  "pageviews-value"
]
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

Finally, to clean up everything and restart, run:

```bash
docker-compose down && docker container prune -f && docker-compose up -d
```

## Schema Linking: Active/Active Setup (with replicated Contexts)

Now we're going to do something a little different - rather than specifying individual `--subjects`, we're going to just replicate the Default context on each Schema Registry to a separate Context on both sides.

We will start by creating our two `Datagen` connectors:

### Create `pageviews` Datagen on the Source

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

### Create `stock_trades` Datagen on the Target

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

From here, let's check Control Center to confirm that both Connectors are running and that the `pageviews` and the `stock_trades` topics are both receiving messages.

### Schema Linking (bi-directional)

Next step will be to create our replica contexts by creating the Schema Exporters - note that we're not specifying subjects in either case this time when we create the Schema Exporter instances.

#### Configure Schema Exporter from `Source` to `Target` cluster

We're going to set up the first of the two Schema Exporters - we're going to start with the `source` Schema Registry (listening on port 8081) and we're configuring the link there, creating a context called `source` which will reside on the `target` cluster.  So we're replicating the Schemas created on the source into a context on the target Schema Registry instance:

```bash
docker-compose exec schemaregistry schema-exporter --create \
    --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-name source --context-type CUSTOM
```

#### Schema Exporter from the `Target` to the `Source` Schema Registries

As this is bi-directional, again, we're setting up the Schema Exporter from the `target` Schema Registry (listening on port 8082).  The default context of the Schema Registry will be replicated to a context called `target`:

```bash
docker-compose exec schemaregistry2 schema-exporter --create \
    --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

### Check to ensure the schemas are being replicated

We will start with the first Schema Registry:

```bash
curl --silent http://localhost:8081/subjects/ | jq
```

What we should now see is the default context subject (`pageviews-value`) and we should also see the schema from the `target` context for the `stocktrades` Datagen connector:

```json
[
  ":.target:stock_trades-value",
  "pageviews-value"
]
```

Let's now do the same with the second Schema Registry:

```bash
curl --silent http://localhost:8082/subjects/ | jq
```

And we should see the two subjects:

```json
[
  ":.source:pageviews-value",
  "stock_trades-value"
]
```

### Subjects and Contexts in more detail

You can use the Schema Registry HTTP API to get schemas from all contexts (note we're using quotes around the URL to get around the globbing `*` characters):

Using the `source` Schema Registry:

```bash
curl --silent "http://localhost:8081/schemas?subjectPrefix=:*:" | jq
```

Using the `target` Schema Registry:

```bash
curl --silent "http://localhost:8082/schemas?subjectPrefix=:*:" | jq
```

Get schemas from a given Schema Registry Context: `.source`:

```bash
curl --silent "http://localhost:8082/schemas?subjectPrefix=:.source:" | jq
```

Get schemas from a given Schema Registry Context: `.target`:

```bash
curl --silent "http://localhost:8081/schemas?subjectPrefix=:.target:" | jq
```

### Describe `schema-exporter` instances

If you start creating multiple exporters, it's useful to know

```bash
docker-compose exec schemaregistry schema-exporter --describe --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081 | jq
```

```json
{
  "name": "src-to-tgt-link",
  "subjects": [
    "*"
  ],
  "contextType": "CUSTOM",
  "context": "source",
  "config": {
    "schema.registry.url": "http://schemaregistry2:8082"
  }
}
```

```bash
docker-compose exec schemaregistry2 schema-exporter --describe --name tgt-to-src-link --schema.registry.url http://schemaregistry2:8082 | jq
```

```json
{
  "name": "tgt-to-src-link",
  "subjects": [
    "*"
  ],
  "contextType": "CUSTOM",
  "context": "target",
  "config": {
    "schema.registry.url": "http://schemaregistry:8081"
  }
}
```

### List the Schema Exporters

Starting with the `source` Schema Registry instance:

```bash
docker-compose exec schemaregistry schema-exporter --list --schema.registry.url http://schemaregistry:8081
```

You should see:

```bash
[src-to-tgt-link]
```

And on the `target` Schema Registry instance:

```bash
docker-compose exec schemaregistry2 schema-exporter --list --schema.registry.url http://schemaregistry2:8082
```

You should see:

```bash
[tgt-to-src-link]
```

### Schema Registry: Review configured Contexts

The Schema Registry ReST API has a `/contexts` endpoint, which will give you a list of all the available contexts known to each Schema Registry instance:

```bash
curl --silent http://localhost:8081/contexts | jq
```

```json
[
  ".",
  ".target"
]
```

And:

```bash
curl --silent GET http://localhost:8082/contexts | jq
```

```json
[
  ".",
  ".source"
]
```

### Debugging Operations for `schema-exporter`

You can get the status of your `schema-exporter` instance using the `--get-status` switch:

```bash
docker-compose exec schemaregistry schema-exporter --get-status --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081 | jq
```

This shows us that there has been a problem and the exporter has been placed in a `PAUSED` state:

```json
{
  "name": "src-to-tgt-link",
  "state": "PAUSED",
  "offset": 4,
  "ts": 1701292093264,
  "trace": "io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException: Subject :.source.target:stock_trades-value is not in import mode; error code: 42205\n\tat io.confluent.kafka.schemaregistry.client.rest.RestService.sendHttpRequest(RestService.java:335)\n\tat io.confluent.kafka.schemaregistry.client.rest.RestService.httpRequest(RestService.java:408)\n\tat io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:588)\n\tat io.confluent.kafka.schemaregistry.client.rest.RestService.registerSchema(RestService.java:576)\n\tat io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.registerAndGetId(CachedSchemaRegistryClient.java:320)\n\tat io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.registerWithResponse(CachedSchemaRegistryClient.java:426)\n\tat io.confluent.kafka.schemaregistry.client.CachedSchemaRegistryClient.register(CachedSchemaRegistryClient.java:397)\n\tat io.confluent.schema.exporter.storage.AbstractSchemaExporterTask.lambda$registerSchema$5(AbstractSchemaExporterTask.java:393)\n\tat io.confluent.kafka.schemaregistry.rest.client.RetryExecutor.retry(RetryExecutor.java:36)\n\tat io.confluent.schema.exporter.storage.AbstractSchemaExporterTask.registerSchema(AbstractSchemaExporterTask.java:392)\n\tat io.confluent.schema.exporter.storage.AbstractSchemaExporterTask.exportSchema(AbstractSchemaExporterTask.java:379)\n\tat io.confluent.schema.exporter.storage.AbstractSchemaExporterTask.export(AbstractSchemaExporterTask.java:273)\n\tat io.confluent.schema.exporter.storage.SchemaExporterRunningTask.run(SchemaExporterRunningTask.java:93)\n\tat java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)\n\tat java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)\n\tat io.confluent.schema.exporter.util.StripedExecutorService$SerialExecutor$1.run(StripedExecutorService.java:436)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)\n\tat java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)\n\tat java.base/java.lang.Thread.run(Thread.java:829)\n"
}
```

We'll dig deeper into fixing this issue shortly, but before we do that, let's get the status of the other `schema-exporter` instance on the `target` cluster:

```bash
docker-compose exec schemaregistry2 schema-exporter --get-status --name tgt-to-src-link --schema.registry.url http://schemaregistry2:8082 | jq
```

```json
{
  "name": "tgt-to-src-link",
  "state": "RUNNING",
  "offset": 2,
  "ts": 1701290473581
}
```

So `tgt-to-src-link` is in a `RUNNING` state.  
We can use `date -r` to find out the timestamp of the epoch - we will need to delete the last 3 digits to lower the precision from miliseconds to seconds:

```bash
date -r 1701290473
Wed 29 Nov 2023 20:41:13 GMT
```

Back to the failing `schema-exporter`:

```bash
Subject :.source.target:stock_trades-value is not in import mode;
```

Now at this point, this seems to be a bug; look at how the context is being constructed within the exception - it's almost as if it's appending the `source` and `target` contexts together - and from our earlier tests, we know that's not what is happening (at least with respect to where the replicated Schemas are - we've checked the contexts on both sides and we've read the Schemas in all cases - but let's try to resolve this by setting this context into `import mode`:

### Set the `.source.target` Context into `IMPORT` mode

```bash
curl --silent -X PUT "http://localhost:8081/mode/:.source.target:" -d "{\"mode\": \"IMPORT\"}" -H "Content-Type: application/json" | jq
```

Let's confirm that the `.source.target` context has been set to `IMPORT` mode:

```bash
curl --silent "http://localhost:8081/mode/:.source.target:" | jq
```

This will confirm that the mode is now correct:

```json
{
  "mode": "IMPORT"
}
```

### Resume the failed `schema-exporter`

```bash
docker-compose exec schemaregistry schema-exporter --resume --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081
```

As soon as that is run, you should see:

```
Successfully resumed exporter src-to-tgt-link
```

Let's get the status again:

```bash
bash-5.2$ docker-compose exec schemaregistry schema-exporter --get-status --name src-to-tgt-link --schema.registry.url http://schemaregistry:8081 | jq
```

And this confirms that the `schema-exporter` is runnning:

```json
{
  "name": "src-to-tgt-link",
  "state": "RUNNING",
  "offset": 4,
  "ts": 1701292093264
}
```

### Schema Checks from both Schema Registry instances

```bash
curl --silent http://localhost:8082/subjects/stock_trades-value/versions/1 | jq
curl --silent http://localhost:8081/subjects/stock_trades-value/versions/1 | jq
```

```bash
curl --silent http://localhost:8081/subjects/pageviews-value/versions/1 | jq
curl --silent http://localhost:8082/subjects/pageviews-value/versions/1 | jq
```

You can also get the first Schema from each Schema Reigstry instance:

```bash
curl --silent http://localhost:8081/schemas/ids/1 | jq
curl --silent http://localhost:8082/schemas/ids/1 | jq
```

### Compatibility Level Check

```bash
curl --silent http://localhost:8081/config | jq
```

```json
{
  "compatibilityLevel": "BACKWARD"
}
```

### Connectivity

```bash
nc -zv localhost 8081
telnet localhost 8081
```

### Further Reading

- <https://docs.confluent.io/cloud/current/sr/schema-linking.html#configuration-options>
