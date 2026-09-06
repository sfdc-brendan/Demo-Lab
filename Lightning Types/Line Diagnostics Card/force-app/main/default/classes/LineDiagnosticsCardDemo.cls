/**
 * Demo-mode service for the line diagnostics card.
 *
 * Returns a fixed sample line test. No SOQL, no custom objects, no config — so
 * the card deploys into any org and renders on the first try. Swap the body of
 * sampleDiagnostics() for your own telemetry call once you've seen it work; the
 * shape the LWC expects is documented in states.json next to this pack.
 *
 * The sample deliberately comes back with a fault on it. An all-green result is
 * the less interesting half of the card, and it hides the warn and fault styling.
 */
public with sharing class LineDiagnosticsCardDemo {

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
        public LineDiagnosticsCardData lineDiagnostics;
    }

    @InvocableMethod(
        label='Run Line Test (Demo)'
        description='Runs a sample remote line test and returns the readings plus a verdict as a renderable card. Always show the lineDiagnostics output to the user.'
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
            res.lineDiagnostics = new LineDiagnosticsCardData(JSON.serialize(sampleDiagnostics()));
            res.narrative = 'I ran a remote line test. The equipment inside the home is fine, but no '
                + 'optical signal is reaching the ONT, so the fault sits upstream in the fiber.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.lineDiagnostics = new LineDiagnosticsCardData('{"error":"Could not run the line test."}');
            res.narrative = 'I could not run the line test right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleDiagnostics() {
        return new Map<String, Object>{
            'testedAt' => 'Today, 2:58 PM',
            'verdict' => 'Fault is upstream of the home',
            'verdictState' => 'fault',
            'summary' => 'The premises network is healthy. No optical signal is reaching the ONT, which places the fault in the fiber plant rather than in the home.',
            'recommendation' => 'No customer action required. This address is covered by outage INC-48213. Do not ask the customer to reset equipment — it will restore on its own.',
            'metrics' => new List<Object>{
                metric('Optical Rx power', 'No signal', 'fault', 0),
                metric('ONT sync status', 'Down', 'fault', 0),
                metric('Gateway uptime', '3 hr 7 min', 'warn', 35),
                metric('Devices on home WiFi', '6 connected', 'ok', 100),
                metric('Last recorded throughput', '934 Mbps', 'ok', 94)
            }
        };
    }

    /** `bar` is a 0-100 fill used by the card; it is a visual scale, not a unit. */
    private static Map<String, Object> metric(String label, String value, String state, Integer bar) {
        return new Map<String, Object>{
            'label' => label,
            'value' => value,
            'state' => state,
            'bar' => bar
        };
    }
}
