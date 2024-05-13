import org.jolokia.client.J4pClient;
import org.jolokia.client.request.J4pReadRequest;
import org.jolokia.client.request.J4pReadResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;

public class WildcardExample {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) throws Exception {
        J4pClient j4pClient = new J4pClient("http://localhost:8778/jolokia");
        J4pReadRequest req = new J4pReadRequest("java.lang:type=GarbageCollector,*", "LastGcInfo");
        J4pReadResponse resp = j4pClient.execute(req);
        LOG.info("Active Broker Count: "+resp.getValue("Value"));
    }
    // kafka.serve?:* --attributes Count,FifteenMinuteRate \
    //  --jmx-url service:jmx:rmi:///jndi/rmi://broker:9101/jmxrmi \
    //  --reporting-interval 1000
}
