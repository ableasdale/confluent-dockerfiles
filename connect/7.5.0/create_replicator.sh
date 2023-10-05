#!/bin/bash

HEADER="Content-Type: application/json"
curl -X POST -H "${HEADER}" -d @./replicator_config.json http://localhost:8083/connectors | jq
