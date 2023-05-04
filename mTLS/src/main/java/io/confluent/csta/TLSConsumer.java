package io.confluent.csta;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.time.Duration;
import java.util.List;
import java.util.Properties;

public class TLSConsumer {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) {

        try (var consumer = new KafkaConsumer<String, String>(ClientTools.getConsumerProperties())) {
            consumer.subscribe(List.of(Config.TOPIC));
            ConsumerRecords<?, ?> records = consumer.poll(Duration.ofSeconds(5));
            for (ConsumerRecord<?, ?> record : records)
                LOG.info(String.format("Partition: %s Offset: %s Value: %s Thread Id: %s", record.partition(), record.offset(), record.value(), Thread.currentThread().getId()));
        }
    }
}
