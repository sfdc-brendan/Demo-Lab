/**
 * Demo-mode service for the customer profile card.
 *
 * Returns a fixed sample profile. No SOQL, no custom objects, no config — so the
 * card deploys into any org and renders on the first try. Swap the body of
 * sampleProfile() for your own query once you've seen it work; the shape the LWC
 * expects is documented in states.json next to this pack.
 */
public with sharing class CustomerProfileCardDemo {

    public class Request {
        @InvocableVariable(label='Customer Identifier' description='Ignored in demo mode. Present so the agent has somewhere to put the account number, email, or record id it resolved.' required=false)
        public String customerIdentifier;
    }

    public class Response {
        // Narrative: plain text for the agent to speak. is_displayable = false.
        @InvocableVariable
        public String narrative;

        // The card itself. Typed as the DTO class, never String or Object.
        // is_displayable = true, filter_from_agent = true.
        @InvocableVariable
        public CustomerProfileCardData customerProfile;
    }

    @InvocableMethod(
        label='Get Customer Profile (Demo)'
        description='Returns a sample customer profile as a renderable card. Always show the customerProfile output to the user.'
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
            res.customerProfile = new CustomerProfileCardData(JSON.serialize(sampleProfile()));
            res.narrative = 'This is Dana Whitfield, account AC-4417029 — a Preferred-tier customer '
                + 'since March 2019. Health and CSAT are both strong and nothing is flagged on the account.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.customerProfile = new CustomerProfileCardData('{"error":"Could not load the customer profile."}');
            res.narrative = 'I could not load the customer profile right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleProfile() {
        return new Map<String, Object>{
            'profileFound' => true,
            'customerName' => 'Dana Whitfield',
            'accountNumber' => 'AC-4417029',
            'tier' => 'Preferred',
            'plan' => 'Premier Plan (Annual)',
            'customerSince' => 'March 2019',
            'tenure' => '6 yrs',
            'phone' => '(415) 555-0139',
            'email' => 'd.whitfield@example.com',
            'address' => '1420 Alder Street, Riverton, CA 94120',
            'preferredChannel' => 'SMS',
            'tags' => new List<Object>{ 'Autopay', 'Paperless', 'Multi-product' },
            'healthScore' => 82,
            'csat' => 91,
            'churnRisk' => 18,
            'alertActive' => false
        };
    }
}
