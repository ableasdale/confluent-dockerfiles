import org.jolokia.client.J4pClient;
import org.jolokia.client.request.J4pReadRequest;
import org.jolokia.client.request.J4pReadResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;

public class ConsumerLagMetricsExample {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    // Example: kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=([-.\w]+),topic=([-.\w]+),partition=([0-9]+)
    /* FIXME: Currently not working */

    public static void main(String[] args) throws Exception {
        J4pClient j4pClient = new J4pClient("http://localhost:8778/jolokia");
        J4pReadRequest req = new J4pReadRequest("kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=([-.\\w]+),topic=([-.\\w]+),partition=([0-9]+)", "Value");
        J4pReadResponse resp = j4pClient.execute(req);
        LOG.info("Active Broker Count: "+resp.getValue("Value"));
    }



}
