package io.confluent.csta;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.lang.invoke.MethodHandles;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Properties;

public class ClientTools {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    protected static String getClusterId(HttpClient httpClient) {
        JsonObject jsonObject = JsonParser.parseString(ClientTools.httpPostBodyAsString(httpClient, "https://rest-proxy:8082/v3/clusters/")).getAsJsonObject();

        final JsonArray data = jsonObject.getAsJsonArray("data");
        String id = null;
        for (JsonElement element : data) {
            id = (((JsonObject) element).get("cluster_id").getAsString());
        }
        return id;
    }

    protected static void httpClientConfigureTlsProperties() {
        Properties props = System.getProperties();
        //props.setProperty("jdk.internal.httpclient.disableHostnameVerification", Boolean.TRUE.toString());
        props.setProperty("javax.net.ssl.keyStore", "/etc/kafka/secrets/client.keystore.jks");
        props.setProperty("javax.net.ssl.keyStorePassword", "confluent");
        props.setProperty("javax.net.ssl.trustStore", "/etc/kafka/secrets/client.truststore.jks");
        props.setProperty("javax.net.ssl.trustStorePassword", "confluent");
    }

    protected static Properties getProducerProperties() {
        final Properties props = new Properties();
        props.put("bootstrap.servers", "broker:9092");

        // This is the necessary configuration for configuring TLS/SSL on the Producer
        props.put("security.protocol", "SSL");
        props.put("ssl.truststore.location", "/etc/kafka/secrets/client.truststore.jks");
        props.put("ssl.truststore.password", "confluent");
        props.put("ssl.keystore.location", "/etc/kafka/secrets/client.keystore.jks");
        props.put("ssl.keystore.password", "confluent");
        props.put("schema.registry.url", "https://schema-registry:8081");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        return props;
    }

    protected static Properties getConsumerProperties() {
        final Properties props = new Properties();
        props.put("bootstrap.servers", "broker:9092");

        // This is the necessary configuration for configuring TLS/SSL on the Producer
        props.put("security.protocol", "SSL");
        props.put("ssl.truststore.location", "/etc/kafka/secrets/client.truststore.jks");
        props.put("ssl.truststore.password", "confluent");
        props.put("ssl.keystore.location", "/etc/kafka/secrets/client.keystore.jks");
        props.put("ssl.keystore.password", "confluent");
        props.put("schema.registry.url", "https://schema-registry:8081");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "cg-1");

        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

        props.put("enable.auto.commit", "false");
        props.put("auto.offset.reset", "earliest");
        return props;
    }

    public static void httpGet(HttpClient httpClient, String url) {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .build();
        try {
            LOG.info("URL: "+url);
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            LOG.info("HTTP Response code: %d".formatted(response.statusCode()));
            LOG.info("Body: %s".formatted(response.body()));
        } catch (IOException e) {
            LOG.error("%s exception encountered:\n%s".formatted(e.toString(), ExceptionUtils.getStackTrace(e)));
        } catch (InterruptedException e) {
            LOG.error("%s exception encountered:\n%s".formatted(e.toString(), ExceptionUtils.getStackTrace(e)));
        }
    }

    public static String httpPostBodyAsString(HttpClient httpClient, String url) {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .build();
        HttpResponse<String> response = null;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            LOG.error("%s exception encountered:\n%s".formatted(e.toString(), ExceptionUtils.getStackTrace(e)));
        } catch (InterruptedException e) {
            LOG.error("%s exception encountered:\n%s".formatted(e.toString(), ExceptionUtils.getStackTrace(e)));
        }
        return response.body();
    }
}
