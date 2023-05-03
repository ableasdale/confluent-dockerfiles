# Confluent Platform configured with Mutual TLS (mTLS)

This project demonstrates the setup of Kafka, Schema Registry and Control Center (C3) with each component secured with mTLS.

## Creating the certificates and stores

- Starting from the directory for this project (`confluent-dockerfiles/mTLS`)
- `cd` to `security` and run `create-certs.sh` from within the directory; this will create the root certificate and all the stores for both the server and the clients.

## Starting the clusters

Start both clusters using the provided `docker-compose.yaml` file:

```bash
docker-compose up
```
