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

To create the secret for Confluent Cloud, you need to combine the key and secret to create a base64-encoded string:

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

## Create the Cluster Link on the Confluent Platform (aka: "on prem") side




### notes below

let's ssh to the CP instance:

```bash
docker-compose exec broker1 bash
```