# Schema Linking - Bidirectional

In this example Confluent Control Center (C3) has been configured to monitor both clusters:

![Dedicated Cluster](img/c3-2clusters.png)

## Troubleshooting: testing the Metrics output

This may be out of date now as all the metrics are being configured on the first broker (source)

For the first broker (`src`):

```bash
docker exec broker kafka-console-consumer --topic _confluent-metrics --bootstrap-server broker:9091 --formatter io.confluent.metrics.reporter.ConfluentMetricsFormatter
```

For the second broker (`tgt`):

```bash
docker exec broker2 kafka-console-consumer --topic _confluent-metrics --bootstrap-server broker2:9092 --formatter io.confluent.metrics.reporter.ConfluentMetricsFormatter
```
