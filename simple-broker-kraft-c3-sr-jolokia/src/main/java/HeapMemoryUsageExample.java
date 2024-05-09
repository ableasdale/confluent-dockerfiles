

import org.jolokia.client.*;
import org.jolokia.client.request.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.invoke.MethodHandles;
import java.util.Map;

public class HeapMemoryUsageExample {

    private static final Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    public static void main(String[] args) throws Exception {
        J4pClient j4pClient = new J4pClient("http://localhost:8778/jolokia");
        J4pReadRequest req = new J4pReadRequest("java.lang:type=Memory", "HeapMemoryUsage");
        J4pReadResponse resp = j4pClient.execute(req);
        Map<String, Long> vals = resp.getValue();
        long used = vals.get("used");
        long max = vals.get("max");
        int usage = (int) (used * 100 / max);
        LOG.info("Memory usage - used: %d - max: %d = %d%%".formatted(used, max, usage));
    }
}
