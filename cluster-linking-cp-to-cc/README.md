# Confluent Platform (on-prem) Cluster Link to Confluent Cloud

We're going to create a Source Initiated Cluster Link from an on-prem Confluent Platform Cluster to a Dedicated Cluster in Confluent Cloud.

## Prerequisites

Create a **Dedicated** cluster in Confluent Cloud to test this:

Log into <https://confluent.cloud/>

Select an Environment and click on **Add Cluster**

Choose Dedicated Cluster:

![Dedicated Cluster](images/dedicated.png)

Select your Geographic region and Cloud Provider (and availability):

![Region Selection](images/region.png)

Select the option for Public Internet:

![Internet](images/public_network.png)

Select Automatic so your keys are managed by your cloud provider:

![Automatic](images/automatic.png)

Give your cluster a name:

![Name your Cluster](images/name.png)

Wait for the cluster to be provisioned:

![Provisioning](images/provisioning.png)

Select the cluster as soon as it has been provisioned:

![Provisioning](images/provisioned.png)

On the left-hand menu, select **API Keys** and **Create Key**

For scope, give the key Global Access:

![Global Scope](images/global-api-key.png)

Give it a name and download the text file.

## Create the configuration and the Secret

To create the secret for Confluent Cloud, you need to combine the key and secret from the text file that you have just downloaded to create a base64-encoded string:

```bash
echo -n "KEY:SECRET" | base64
```

Paste the output from this command into `security/ccloud_creds`, replacing the placeholder line with your command output.

In a terminal session, start up the Confluent Platform side to create your broker and zookeeper instances:

```bash
docker-compose up
```

As soon as this is done, we will need to get the Cluster ID - to do this, we can run the `kafka-cluster` command on the container:

```bash
docker-compose exec broker1 kafka-cluster cluster-id --bootstrap-server broker1:9091
```

You should see something like:

```bash
Cluster ID: ZWe3nnZwTrKSM0aM2doAxQ
```

We will also need the bootstrap server URL for configuration to take place; to do this click on **Cluster Settings** under the Cluster Overview section of the navigation; the endpoints will be listed under that section:

![Endpoints](images/endpoints.png)

Now we're ready to start preparing the Cluster Link.

## Create the Cluster Link on the Confluent Cloud side

Open `client/ccloud-cluster-link.properties` and replace the following sections:

- << dedicated instance bootstrap host >> with your **bootstrap host**.
- << KEY >> with your API Key
- << SECRET >> with your Secret

Prior to modification, the file should look like this

```properties
bootstrap.servers=<< dedicated instance bootstrap host >>:9092
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<< KEY >>" password="<< SECRET >>";
link.mode=DESTINATION
#link.mode=SOURCE
connection.mode=INBOUND

local.listener.name=PLAINTEXT_HOST
local.security.protocol=PLAINTEXT
local.sasl.mechanism=PLAIN
```

Now log in using the Confluent CLI and run the following:

Set the correct environment for the dedicated cluster:

```bash
confluent environment list
confluent environment use <id>
```

Select the dedicated cluster within the environment:

```bash
confluent kafka cluster list
confluent kafka cluster use <id>
```

```bash
confluent kafka link create on-prem-link --cluster <ccloud cluster> --source-cluster <cp cluster> --config-file client/ccloud-cluster-link.properties
```

For example:

```bash
confluent kafka link create on-prem-link --cluster lkc-23pgvq --source-cluster ZWe3nnZwTrKSM0aM2doAxQ --config-file client/ccloud-cluster-link.properties
```

You should see:

```bash
Created cluster link "on-prem-link" with configs:
"bootstrap.servers"="pkc-yvw0p.eu-central-1.aws.confluent.cloud:9092"
"connection.mode"="INBOUND"
"link.mode"="DESTINATION"
"local.sasl.mechanism"="PLAIN"
"local.security.protocol"="PLAINTEXT"
"sasl.mechanism"="PLAIN"
"security.protocol"="SASL_SSL"
```

To confirm that the link has been created, run:

```bash
confluent kafka link list
```

You should see something like:

```
      Name     |     Source Cluster     | Destination Cluster |     Remote Cluster     | State  | Error | Error Message
---------------+------------------------+---------------------+------------------------+--------+-------+----------------
  on-prem-link | ZWe3nnZwTrKSM0aM2doAxQ |                     | ZWe3nnZwTrKSM0aM2doAxQ | ACTIVE |       |
```

To view the link in Confluent Cloud, you can go to <https://confluent.cloud/cluster-links> and click on `on-prem-link`, you'll see something like this:

![Cluster Link](images/clusterlink.png)

In order to complete the link and to start mirroring topics, we now need to create the link going from the source (CP) cluster.

## Create the Cluster Link on the Confluent Platform (aka: "on prem") side

```properties
link.mode=SOURCE
connection.mode=OUTBOUND

bootstrap.servers=<< dedicated instance bootstrap host >>:9092
ssl.endpoint.identification.algorithm=https
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<< KEY >>" password="<< SECRET >>";

local.listener.name=PLAINTEXT_HOST
local.security.protocol=PLAINTEXT
local.sasl.mechanism=PLAIN
```


### notes below

let's ssh to the CP instance:

```bash
docker-compose exec broker1 bash
```