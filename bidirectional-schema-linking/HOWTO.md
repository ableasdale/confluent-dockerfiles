


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

Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-name target --context-type CUSTOM
```

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


Schema Exporter from Source to Target cluster

```bash
docker-compose exec schemaregistry schema-exporter --create --name src-to-tgt-link \
    --config-file /tmp/config/schemalink-src.cfg \
    --schema.registry.url http://schemaregistry:8081 \
    --context-type NONE
```

Schema Exporter from Target to Source cluster

```bash
docker-compose exec schemaregistry2 schema-exporter --create --name tgt-to-src-link \
    --config-file /tmp/config/schemalink-tgt.cfg \
    --schema.registry.url http://schemaregistry2:8082 \
    --context-type NONE
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