package io.confluent.csta;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.net.http.HttpClient;

public class TLSSchemaRegistryClient {
    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());
    public static void main(String[] args) {

        ClientTools.httpClientConfigureTlsProperties();
        HttpClient httpClient = HttpClient.newHttpClient();

        ClientTools.httpGet(httpClient,"https://schema-registry:8081/subjects");
        ClientTools.httpGet(httpClient,"https://schema-registry:8081/schemas/types");

        /* TODO:
        curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data '{"schema": "{\"type\": \"string\"}"}' \
http://localhost:8081/subjects/Kafka-value/versions
         */

    }
}
