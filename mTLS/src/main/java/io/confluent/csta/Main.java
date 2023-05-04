package io.confluent.csta;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;

public class Main {
    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());
    public static void main(String[] args) {
        LOG.info("Running the TLS Producer...");
        TLSProducer.main(null);
        LOG.info("Running the TLS Consumer...");
        TLSConsumer.main(null);
        LOG.info("Running the TLS Schema Registry Client...");
        TLSSchemaRegistryClient.main(null);
        LOG.info("Running the TLS ReST Proxy Client...");
        TLSRestProxy.main(null);
    }
}
