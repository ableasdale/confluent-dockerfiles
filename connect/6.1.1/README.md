


### Consume from the replica topic

```bash
docker-compose exec kafka /usr/bin/kafka-console-consumer --bootstrap-server kafka:29092 --topic replicate-me.replica
```