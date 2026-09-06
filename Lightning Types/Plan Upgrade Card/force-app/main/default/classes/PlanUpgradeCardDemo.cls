/**
 * Demo-mode service for the plan upgrade card.
 *
 * Returns a fixed plan comparison. No SOQL, no custom objects, no config — so
 * the card deploys into any org and renders on the first try. Swap the body of
 * samplePlans() for your own catalog lookup once you've seen it work; the shape
 * the LWC expects is documented in states.json next to this pack.
 *
 * Read-only by design. Applying the upgrade is a separate confirmed action, so
 * showing the comparison can never change what the customer is billed.
 */
public with sharing class PlanUpgradeCardDemo {

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
        public PlanUpgradeCardData planUpgrade;
    }

    @InvocableMethod(
        label='Get Plan Options (Demo)'
        description='Returns the customer current plan alongside the recommended next tier as a renderable comparison card. Always show the planUpgrade output to the user.'
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
            res.planUpgrade = new PlanUpgradeCardData(JSON.serialize(samplePlans()));
            res.narrative = 'This customer is on Fiber 500 today. Fiber 1 Gig doubles the '
                + 'download speed and takes upload from 100 to 500 Mbps for $20 more a month, '
                + 'with the install fee waived.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.planUpgrade = new PlanUpgradeCardData('{"error":"Could not load plan options."}');
            res.narrative = 'I could not load the plan options right now.';
        }
        return res;
    }

    private static Map<String, Object> samplePlans() {
        return new Map<String, Object>{
            'current' => new Map<String, Object>{
                'name' => 'Fiber 500',
                'downloadMbps' => 500,
                'uploadMbps' => 100,
                'monthlyPrice' => 79.99,
                'features' => new List<String>{
                    '500 Mbps download / 100 Mbps upload',
                    'Whole-home WiFi included',
                    'Standard support'
                }
            },
            'recommended' => new Map<String, Object>{
                'name' => 'Fiber 1 Gig',
                'downloadMbps' => 1000,
                'uploadMbps' => 500,
                'monthlyPrice' => 99.99,
                'promo' => 'Free professional install (a $99 value)',
                'features' => new List<String>{
                    '1 Gbps download / 500 Mbps upload',
                    'Whole-home WiFi 6E mesh',
                    'Priority 24/7 support',
                    'Free professional install'
                }
            },
            'monthlyIncrease' => 20.00,
            'reason' => 'Faster upload speeds and priority support, with the install fee waived.'
        };
    }
}
