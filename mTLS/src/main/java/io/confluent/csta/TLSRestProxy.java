package io.confluent.csta;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.net.http.HttpClient;

public class TLSRestProxy {
    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) {

        ClientTools.httpClientConfigureTlsProperties();
        HttpClient httpClient = HttpClient.newHttpClient();
        String clusterId = ClientTools.getClusterId(httpClient);

        ClientTools.httpGet(httpClient,"https://rest-proxy:8082/v3/clusters/");

        // GET /clusters/{cluster_id}/brokers
        ClientTools.httpGet(httpClient, "https://rest-proxy:8082/v3/clusters/%s/brokers".formatted(clusterId));

        // GET /clusters/{cluster_id}/broker-configs
        ClientTools.httpGet(httpClient, "https://rest-proxy:8082/v3/clusters/%s/broker-configs".formatted(clusterId));


        /*
        LOG.info("recordsTotal : " + jsonObject.get("recordsTotal"));
        List<String> list = new ArrayList<String>();
        for (JsonElement element : data) {
            list.add(((JsonObject) element).get("part_number").getAsString());

        } */

/*
        String JSON = ClientTools.httpPostBodyAsString(httpClient,"https://rest-proxy:8082/v3/clusters/");
        LOG.info(JSON);
        String jsonStr = gson.toJson(foo);
        Foo result = gson.fromJson(jsonStr, Foo.class);
        assertEquals(foo.getId(),result.getId()); */

        // GET /clusters/{cluster_id}/broker-configs
    }
}
