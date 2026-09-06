/**
 * Demo-mode service for the fiber availability card.
 *
 * Returns a fixed serviceable address. No SOQL, no custom objects, no config —
 * so the card deploys into any org and renders on the first try. Swap the body
 * of sampleAvailability() for your own footprint lookup once you've seen it
 * work; the shape the LWC expects is documented in states.json next to this
 * pack, including the not-serviceable and empty answers this demo never returns.
 */
public with sharing class FiberAvailabilityCardDemo {

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
        public FiberAvailabilityCardData fiberAvailability;
    }

    @InvocableMethod(
        label='Check Fiber Availability (Demo)'
        description='Returns a sample fiber serviceability check as a renderable card. Always show the fiberAvailability output to the user.'
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
            res.fiberAvailability = new FiberAvailabilityCardData(
                JSON.serialize(sampleAvailability())
            );
            res.narrative = 'Gigabit Fiber is live at this service address. The build through '
                + 'Rincon Hill & South Beach finished on August 13, 2026, and the fiber drop '
                + 'is already at the property.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.fiberAvailability = new FiberAvailabilityCardData('{"error":"Could not load fiber availability."}');
            res.narrative = 'I could not check fiber availability for this address right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleAvailability() {
        return new Map<String, Object>{
            'serviceable' => true,
            'statusLabel' => 'Live in this neighborhood',
            'headline' => 'Gigabit Fiber is live on Market St',
            'neighborhood' => 'Rincon Hill & South Beach',
            'city' => 'San Francisco',
            'postalCode' => '94105',
            'summary' => 'The Gigabit Fiber build through Rincon Hill & South Beach completed '
                + 'on August 13, 2026. This address is fully serviceable, the fiber drop is '
                + 'already at the property, and 63% of the homes on the route are connected.',
            'buildCompleted' => 'August 13, 2026',
            'facts' => new List<Object>{
                fact('Build status', 'Completed August 13, 2026'),
                fact('Homes passed on this route', '1,840'),
                fact('Neighbors already connected', '1,163 (63%)'),
                fact('Fiber drop at the property', 'Already installed'),
                fact('Top speed now available', '2 Gbps symmetric')
            },
            // The jump the customer would actually feel: their plan today against
            // the tier being recommended, never the route maximum.
            'currentDownloadMbps' => 500,
            'recommendedPlan' => 'Fiber 1 Gig',
            'recommendedDownloadMbps' => 1000,
            'speedMultiplier' => '2x',
            'headroom' => '2 Gbps',
            'promo' => 'Free white-glove install (a $99 value)',
            'promoEnds' => 'September 30',
            'recommendation' => 'Confirm the address is serviceable, then offer Fiber 1 Gig '
                + 'with the $99 install waived. Quote that plan\'s speed, not the route '
                + 'maximum. Send the availability to the customer so they have it in writing.'
        };
    }

    private static Map<String, Object> fact(String label, String value) {
        return new Map<String, Object>{ 'label' => label, 'value' => value };
    }
}
