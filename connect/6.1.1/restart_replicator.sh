#!/bin/bash

HEADER="Content-Type: application/json"
curl -X POST http://localhost:8083/connectors/replicator/restart | jq
