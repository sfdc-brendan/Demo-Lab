/**
 * Demo-mode service for the outage status card.
 *
 * Returns a fixed sample outage. No SOQL, no custom objects, no config — so the
 * card deploys into any org and renders on the first try. Swap the body of
 * sampleOutage() for your own query once you've seen it work; the shape the LWC
 * expects is documented in states.json next to this pack.
 */
public with sharing class OutageStatusCardDemo {

    public class Request {
        @InvocableVariable(label='Service Address' description='Ignored in demo mode. Present so the agent has somewhere to put the address it resolved.' required=false)
        public String serviceAddress;
    }

    public class Response {
        // Narrative: plain text for the agent to speak. is_displayable = false.
        @InvocableVariable
        public String narrative;

        // The card itself. Typed as the DTO class, never String or Object.
        // is_displayable = true, filter_from_agent = true.
        @InvocableVariable
        public OutageStatusCardData outageStatus;
    }

    @InvocableMethod(
        label='Get Outage Status (Demo)'
        description='Returns a sample network outage as a renderable card. Always show the outageStatus output to the user.'
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
            res.outageStatus = new OutageStatusCardData(JSON.serialize(sampleOutage()));
            res.narrative = 'There is an active network outage affecting this address. '
                + 'Crews are on site and service is expected back around 3:45 PM.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.outageStatus = new OutageStatusCardData('{"error":"Could not load outage status."}');
            res.narrative = 'I could not load the outage status right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleOutage() {
        return new Map<String, Object>{
            'outageFound' => true,
            'ticketNumber' => 'INC-48213',
            'status' => 'Crew on site',
            'cause' => 'Fiber cut from third-party excavation',
            'area' => 'Maple Grove / North Ridge',
            'crewStatus' => 'Splice crew on site',
            'etaTime' => '3:45 PM',
            'etaCountdown' => 'about 90 minutes from now',
            'startedAt' => '1:12 PM',
            'elapsed' => '2h 15m ago',
            'affectedCustomers' => 1284,
            'steps' => new List<Object>{
                step('Outage detected', 'done'),
                step('Crew dispatched', 'done'),
                step('Splice repair in progress', 'current'),
                step('Service restored', 'pending')
            }
        };
    }

    private static Map<String, Object> step(String label, String state) {
        return new Map<String, Object>{ 'label' => label, 'state' => state };
    }
}
