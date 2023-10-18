# Schema Linking - Bidirectional

In this example, Confluent Control Center (C3) has been configured to monitor both clusters:

![Dedicated Cluster](img/c3-2clusters.png)

## Troubleshooting: testing the Metrics output

This may be out of date now as all the metrics are being configured on the first broker (source)

For the first broker (`src`):

```bash
docker exec broker kafka-console-consumer --topic _confluent-metrics --bootstrap-server broker:9091 --formatter io.confluent.metrics.reporter.ConfluentMetricsFormatter
```

Create a topic on the target cluster:

```bash
docker-compose exec broker2 kafka-topics --bootstrap-server broker2:9092 --topic cluster-link-topic --replication-factor 1 --partitions 1 --create --config min.insync.replicas=1'
```



## Notes below

Note that MetricsReporter (or more accurately, C3) requires that a single 

For the second broker (`tgt`):

```bash
docker exec broker2 kafka-console-consumer --topic _confluent-metrics --bootstrap-server broker2:9092 --formatter io.confluent.metrics.reporter.ConfluentMetricsFormatter
```
