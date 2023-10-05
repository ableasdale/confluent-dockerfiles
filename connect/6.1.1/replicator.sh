#!/bin/bash

HEADER="Content-Type: application/json"
curl -X POST -H "${HEADER}" -d @./payload.json http://localhost:8083/connectors | jq
