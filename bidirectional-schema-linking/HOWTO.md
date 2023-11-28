# Schema Linking Walkthrough

We're going to cover two scenarios in this walkthrough: an Active/Passive Schema Registry setup (where only one Schema Registry can be written to) and a way to perform an Active/Active setup - we will show the drawbacks and trade-offs for both solutions.

## Getting Started

Start up all the containers for this demo:

```bash
docker-compose up -d
```

Then visit <http://localhost:9021/> to confirm that Confluent Control Center is available.

## Active/Passive Setup

First we will start by configuring Schema Linking to copy the default context from one Schema Registry to another - in this setup, we have one Schema Registry which is writeable and the other that is read-only.  We will start by setting up this configuration.

### Configure Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-type NONE
```

### Configure Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-type NONE
```




## Bidirectional Cluster Linking walkthrough

Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg --subjects pageviews-value \
    --schema.registry.url http://schemaregistry:8081 \
    --context-name source --context-type CUSTOM
```

Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg --subjects stock_trades-value \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

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







Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-name source --context-type CUSTOM
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

Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

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

## Explore the Schema Contexts

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

### Prove that the Schema is identical on both sides

curl http://localhost:8081/subjects/pageviews-value/versions/1 | md5
curl http://localhost:8082/subjects/pageviews-value/versions/1 | md5


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