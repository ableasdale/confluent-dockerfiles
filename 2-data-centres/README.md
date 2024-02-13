

```bash
docker-compose exec broker-dc1 kafka-topics --bootstrap-server broker-dc1:29091 --topic replicate-me --replication-factor 1 --partitions 1 --create
```

```bash
docker-compose exec broker-dc1 kafka-producer-perf-test --throughput -1 --num-records 1000000 --topic replicate-me --record-size 10 --producer-props bootstrap.servers='broker-dc1:29091' acks=all
```

```bash
./submit_replicator_dc1_to_dc2.sh
```