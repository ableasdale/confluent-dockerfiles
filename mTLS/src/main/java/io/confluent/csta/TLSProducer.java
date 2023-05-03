package io.confluent.csta;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.util.Properties;

public class TLSProducer {
    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) {
        LOG.info("Hello world!");
        final Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");

        // This is the necessary configuration for configuring TLS/SSL on the Producer
        props.put("security.protocol", "SSL");
        props.put("ssl.truststore.location", "security/kafka.client.truststore.jks");
        props.put("ssl.truststore.password", "confluent");
        props.put("ssl.keystore.location", "security/kafka.client.keystore.jks");
        props.put("ssl.keystore.password", "confluent");

        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        Producer<String, String> producer = new KafkaProducer<>(props);

        try {
            for (int i = 0; i < 5; i++) {
                double randomDouble = Math.random();
                int randomNum = (int) (randomDouble * 1000000000);
                producer.send(new ProducerRecord<>("test-topic", Integer.toString(i),
                        Integer.toString(randomNum)));
                LOG.info(String.format("Sent %d:%d", i, randomNum));
            }
        } catch (KafkaException e) {
            LOG.error(e.toString());
            producer.abortTransaction();
        }

        producer.flush();
        producer.close();
    }
}