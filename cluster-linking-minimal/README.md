# Cluster Linking - Minimal Configuration

TODO...

## TODO - This is incomplete

```bash
docker-compose exec zookeeper zookeeper-shell localhost:2181
```

```bash
Connecting to localhost:2181
Welcome to ZooKeeper!
JLine support is disabled

WATCHER::

WatchedEvent state:SyncConnected type:None path:null
get /cluster/id
{"version":"1","id":"0ujxx5IgQ4qAYiUtfoRBOg"}
^C%
```

```bash
❯ docker-compose exec zookeeper2 zookeeper-shell localhost:2182
```

```bash
get /cluster/id
{"version":"1","id":"gDAqMfXQS3Ww2c_JTIXOXw"}
```

```bash
docker-compose exec broker1 kafka-cluster-links --bootstrap-server broker2:9092 --create --link ab-link --config-file /tmp/link.properties --cluster-id 0ujxx5IgQ4qAYiUtfoRBOg
```
