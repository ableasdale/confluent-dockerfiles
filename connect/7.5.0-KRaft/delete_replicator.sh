#!/bin/bash

HEADER="Content-Type: application/json"
curl -X DELETE http://localhost:8083/connectors/replicator | jq
