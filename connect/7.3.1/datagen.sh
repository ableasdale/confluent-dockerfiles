#!/bin/bash

HEADER="Content-Type: application/json"
curl -X POST -H "${HEADER}" -d @./datagen.json http://localhost:8083/connectors | jq
