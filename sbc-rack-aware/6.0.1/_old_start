#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function wait_for_datagen_connector_to_inject_data () {
  sleep 3
  connector_name="$1"
  datagen_tasks="$2"
  prefix_cmd="$3"
  set +e
  # wait for all tasks to be FAILED with org.apache.kafka.connect.errors.ConnectException: Stopping connector: generated the configured xxx number of messages
  MAX_WAIT=3600
  CUR_WAIT=0
  echo "Waiting up to $MAX_WAIT seconds for connector $connector_name to finish injecting requested load"
  $prefix_cmd curl -s -X GET http://localhost:8083/connectors/datagen-${connector_name}/status | jq .tasks[].trace | grep "generated the configured" | wc -l > /tmp/out.txt 2>&1
  while [[ ! $(cat /tmp/out.txt) =~ "${datagen_tasks}" ]]; do
    sleep 5
    $prefix_cmd curl -s -X GET http://localhost:8083/connectors/datagen-${connector_name}/status | jq .tasks[].trace | grep "generated the configured" | wc -l > /tmp/out.txt 2>&1
    CUR_WAIT=$(( CUR_WAIT+10 ))
    if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
      echo -e "\nERROR: Please troubleshoot'.\n"
      $prefix_cmd curl -s -X GET http://localhost:8083/connectors/datagen-${connector_name}/status | jq
      exit 1
    fi
  done
  echo "Connector $connector_name has finish injecting requested load"
  set -e
}

function wait_for_connect_to_start () {
     MAX_WAIT=600
     CUR_WAIT=0
     echo "Waiting up to $MAX_WAIT seconds for connect to start"
     docker container logs connect > /tmp/out.txt 2>&1
     while ! grep "Finished starting connectors and tasks" /tmp/out.txt > /dev/null;
     do
          sleep 10
          docker container logs connect > /tmp/out.txt 2>&1
          CUR_WAIT=$(( CUR_WAIT+10 ))
          if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
               echo -e "\nERROR: The logs in all connect containers do not show 'Finished starting connectors and tasks' after $MAX_WAIT seconds. Please troubleshoot with 'docker container ps' and 'docker container logs'.\n"
               exit 1
          fi
     done
     echo "Connect has started!"
}

NOW="$(date +%s)000"
sed -e "s|:NOW:|$NOW|g" \
    ${DIR}/schemas/orders-template.avro > ${DIR}/schemas/orders.avro
sed -e "s|:NOW:|$NOW|g" \
    ${DIR}/schemas/shipments-template.avro > ${DIR}/schemas/shipments.avro

docker-compose down -v
docker-compose up -d

wait_for_connect_to_start

echo "Create topic orders"
curl -s -X PUT \
      -H "Content-Type: application/json" \
      --data '{
                "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
                "kafka.topic": "orders",
                "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                "value.converter": "org.apache.kafka.connect.json.JsonConverter",
                "value.converter.schemas.enable": "false",
                "max.interval": 1,
                "iterations": "10000",
                "tasks.max": "10",
                "schema.filename" : "/tmp/schemas/orders.avro",
                "schema.keyfield" : "orderid"
            }' \
      http://localhost:8083/connectors/datagen-orders/config | jq

wait_for_datagen_connector_to_inject_data "orders" "10"

echo "Create topic shipments"
curl -s -X PUT \
      -H "Content-Type: application/json" \
      --data '{
                "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
                "kafka.topic": "shipments",
                "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                "value.converter": "org.apache.kafka.connect.json.JsonConverter",
                "value.converter.schemas.enable": "false",
                "max.interval": 1,
                "iterations": "10000",
                "tasks.max": "10",
                "schema.filename" : "/tmp/schemas/shipments.avro"
            }' \
      http://localhost:8083/connectors/datagen-shipments/config | jq

wait_for_datagen_connector_to_inject_data "shipments" "10"

echo "Create topic products"
curl -s -X PUT \
      -H "Content-Type: application/json" \
      --data '{
                "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
                "kafka.topic": "products",
                "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                "value.converter": "org.apache.kafka.connect.json.JsonConverter",
                "value.converter.schemas.enable": "false",
                "max.interval": 1,
                "iterations": "100",
                "tasks.max": "10",
                "schema.filename" : "/tmp/schemas/products.avro",
                "schema.keyfield" : "productid"
            }' \
      http://localhost:8083/connectors/datagen-products/config | jq

wait_for_datagen_connector_to_inject_data "products" "10"

echo "Create topic customers"
curl -s -X PUT \
      -H "Content-Type: application/json" \
      --data '{
                "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
                "kafka.topic": "customers",
                "key.converter": "org.apache.kafka.connect.storage.StringConverter",
                "value.converter": "org.apache.kafka.connect.json.JsonConverter",
                "value.converter.schemas.enable": "false",
                "max.interval": 1,
                "iterations": "1000",
                "tasks.max": "10",
                "schema.filename" : "/tmp/schemas/customers.avro",
                "schema.keyfield" : "customerid"
            }' \
      http://localhost:8083/connectors/datagen-customers/config | jq

wait_for_datagen_connector_to_inject_data "customers" "10"

