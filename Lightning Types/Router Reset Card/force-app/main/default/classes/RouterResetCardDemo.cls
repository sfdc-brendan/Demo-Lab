/**
 * Demo-mode service for the router health and reset card.
 *
 * Returns a fixed degraded gateway. No SOQL, no custom objects, no config — so
 * the card deploys into any org and renders on the first try. Swap the body of
 * sampleGateway() for your own diagnostics once you've seen it work; the shape
 * the LWC expects is documented in states.json next to this pack.
 *
 * Read-only on purpose. The restart the card offers is a separate, confirmed
 * action; this class only reports what the gateway is doing.
 */
public with sharing class RouterResetCardDemo {

    /**
     * Unplanned restarts recorded on this gateway in the last 30 days. This is
     * the whole reason a restart is triage and not a fix: a device rebooting
     * itself twice a week has a hardware fault a restart cannot clear.
     */
    private static final Integer REBOOTS_30D = 14;

    public class Request {
        @InvocableVariable(label='Customer ID' description='Ignored in demo mode. Present so the agent has somewhere to put the customer it resolved.' required=false)
        public String customerId;
    }

    public class Response {
        // Narrative: plain text for the agent to speak. is_displayable = false.
        @InvocableVariable
        public String narrative;

        // The card itself. Typed as the DTO class, never String or Object.
        // is_displayable = true, filter_from_agent = true.
        @InvocableVariable
        public RouterResetCardData routerHealth;
    }

    @InvocableMethod(
        label='Get Router Health (Demo)'
        description='Returns a sample home gateway with its latency, jitter, packet loss, Wi-Fi channel congestion, and self-restart history as a renderable card, and says whether a remote restart is worth doing. Always show the routerHealth output to the user.'
    )
    public static List<Response> run(List<Request> requests) {
        Integer count = (requests == null || requests.isEmpty()) ? 1 : requests.size();
        List<Response> responses = new List<Response>();
        for (Integer i = 0; i < count; i++) {
            responses.add(buildResponse());
        }
        return responses;
    }

    private static Response buildResponse() {
        Response res = new Response();
        try {
            res.routerHealth = new RouterResetCardData(JSON.serialize(sampleGateway()));
            res.narrative = 'The line into the home is clean, but the gateway is losing '
                + 'packets on a congested Wi-Fi channel and has been restarting itself for '
                + 'weeks. A network-side restart should clear it today.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.routerHealth = new RouterResetCardData('{"error":"Could not load gateway health."}');
            res.narrative = 'I could not load the gateway health right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleGateway() {
        return new Map<String, Object>{
            'gatewayFound' => true,
            'device' => new Map<String, Object>{
                'name' => 'Residential Gateway AX6',
                'serial' => 'GWAX6-4417-8890',
                'health' => 'Degraded'
            },
            'verdict' => 'Degraded — a restart should clear this',
            'verdictState' => 'warn',
            'summary' => 'The fiber line into the home is clean and the gateway is holding a '
                + 'WAN session, but it is dropping 6.4% of packets and its Wi-Fi radio is '
                + 'sharing channel 6 with eleven neighboring networks. That combination is '
                + 'what the customer is experiencing as buffering and dropped calls.',
            'recommendation' => 'Send a network-side restart. It re-provisions the WAN session '
                + 'and moves the Wi-Fi radio to a clear channel, which a customer power-cycle '
                + 'cannot do. The unit has also restarted itself ' + REBOOTS_30D + ' times in '
                + '30 days and is out of warranty, so plan on replacing it as the permanent fix.',
            'lastRestarted' => 'Today, 4:12 AM',
            'canRestart' => true,
            'replacementRecommended' => true,
            'outOfWarranty' => true,
            'rebootCount' => REBOOTS_30D,
            'metrics' => new List<Object>{
                metric('Gateway status', 'Online', 'ok', 100),
                metric('WAN session', 'Established', 'ok', 100),
                metric('Latency to internet', '188 ms', 'warn', 34),
                metric('Jitter', '42 ms', 'warn', 28),
                metric('Packet loss', '6.4%', 'fault', 10),
                metric('Wi-Fi channel congestion', 'Channel 6 — 11 networks', 'fault', 8),
                metric('Devices on home Wi-Fi', '6 connected, 2 dropping', 'warn', 55)
            },
            // Five most recent of the fourteen. The card shows these and counts
            // the rest, so the pattern is visible without a 14-row list.
            'rebootHistory' => new List<Object>{
                reboot('Today, 4:12 AM', 'Watchdog timeout'),
                reboot('Yesterday, 3:47 AM', 'Watchdog timeout'),
                reboot('Mar 3, 4:05 AM', 'Thermal shutdown'),
                reboot('Mar 1, 2:19 AM', 'Watchdog timeout'),
                reboot('Feb 27, 3:52 AM', 'Thermal shutdown')
            }
        };
    }

    /**
     * `bar` is a 0-100 fill for the card's meter — a visual scale, not a unit, so
     * a good reading is always a full bar whichever direction the metric runs in.
     */
    private static Map<String, Object> metric(String label, String value, String state, Integer bar) {
        return new Map<String, Object>{
            'label' => label,
            'value' => value,
            'state' => state,
            'bar' => bar
        };
    }

    // `when` is the JSON key but not the parameter name — it is reserved in Apex.
    private static Map<String, Object> reboot(String stamp, String reason) {
        return new Map<String, Object>{ 'when' => stamp, 'reason' => reason };
    }
}
