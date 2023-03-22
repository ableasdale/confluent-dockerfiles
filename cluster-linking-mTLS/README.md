# Confluent Platform Cluster Linking 

A project to demonstrate Cluster Linking Between two clusters running Confluent Platform (7.3.1).

The project will set up two 3-broker Kafka Clusters, each with a separate Zookeeper instance.

## Starting the Clusters

Start both clusters using the provided `docker-compose.yaml` file:

```bash
docker-compose up
```

## Ensuring everything is working and has started correctly

### Checking the first cluster

We can quickly check the status of each cluster using `zookeeper-shell` on the first cluster:

```bash
docker-compose exec zookeeper zookeeper-shell localhost:2181
```

```bash
get /controller
{"version":1,"brokerid":2,"timestamp":"1673382716473"}
```

```bash
get /cluster/id
{"version":"1","id":"YTAd13fGSziks7O0NRs2QA"}
```

### Checking the second cluster

Now let's try to connect to Zookeeper instance on the second cluster using `zookeeper-shell`:

```bash
docker-compose exec zookeeper2 zookeeper-shell localhost:2182
```

```
get /controller
{"version":1,"brokerid":3,"timestamp":"1673382712259"}
```

```
get /cluster/id
{"version":"1","id":"3vcAUrrvSCqPDykFsSIhfg"}
```
