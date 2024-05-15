import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.util.Properties;

public class TestJavaClient {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) {
        final Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        Producer<String, String> producer = new KafkaProducer<>(props);
        produceTo(producer, "test-topic", "s");
        producer.flush();
        producer.close();
    }

    private static void produceTo(Producer<String, String> producer, String topic, Object o) {
        producer.send(new ProducerRecord(topic, o),
                (event, ex) -> {
                    if (ex != null)
                        LOG.error("Exception:", ex);
                    else
                        LOG.info(String.format("Produced event to topic %s: key = %-10s value = %s", "x", "y", "z"));
                });
    }
}