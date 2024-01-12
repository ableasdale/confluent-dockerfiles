# Recovery Process for a failed data volume on a broker

The aim of this project is to briefly test Kafka's resilience if you delete the contents of a data directory and restart.

This walkthrough makes a few assumptions in order for this test to work:

- All critical topics are configured with `replication-factor 3` and `min.insync.replicas=2`

- Each of the three brokers is configured to mount the data volume at a configured mountpoint:
  - broker1 mounts `/data/data1` which maps to the `data1` directory.
  - broker2 mounts `/data/data2` which maps to the `data2` directory.
  - broker3 mounts `/data/data3` which maps to the `data3` directory.

## Start the test

Run:

```bash
docker-compose up
```

Confirm that everything is running by visiting <http://localhost:9021/>

## Create a test topic

We're going to create a topic with 3 partitions, `replication-factor 3` and `min.insync.replicas=2`:

```bash
docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --topic test-one --replication-factor 3 --partitions 3 --create --config min.insync.replicas=2
```

## Produce some messages within the topic

We will use the `kafka-producer-perf-test` tool to quickly add some messages to the partitions:

```bash
docker-compose exec broker1 kafka-producer-perf-test --throughput -1 --num-records 10000000 --topic test-one --record-size 10 --producer-props bootstrap.servers='broker1:9092' acks=all
```

In each of the `data` directories you should now see:

- `test-one-0`
- `test-one-1`
- `test-one-2`

## Data Destruction Test

If we stop `broker1`:

```bash
docker-compose stop broker1
```

Now delete the `data1` directory in the same directory as this README (the project root):

```bash
rm -rf data1
```

If we restart `broker1`:

```bash
docker-compose start broker1
```

We should see that the `data1` directory is re-created along with the topic partition directories.

## Cleanup

Clear the data directories after testing by running:

```bash
rm -rf data*
```

## Debug

Connect to one of the instances to investigate any volume / data issues:

```bash
docker-compose exec broker1 bash
```
