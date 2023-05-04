package io.confluent.csta;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.util.Properties;

public class TLSProducer {
    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) {

        Producer<String, String> producer = new KafkaProducer<>(ClientTools.getProducerProperties());

        try {
            for (int i = 0; i < 5; i++) {
                double randomDouble = Math.random();
                int randomNum = (int) (randomDouble * 1000000000);
                producer.send(new ProducerRecord<>("test-topic", Integer.toString(i),
                        Integer.toString(randomNum)));
                LOG.info(String.format("Sent %d:%d", i, randomNum));
            }
        } catch (KafkaException e) {
            LOG.error("KafkaException encountered: %s".formatted(e.toString()));
        }
        producer.flush();
        producer.close();
    }
}