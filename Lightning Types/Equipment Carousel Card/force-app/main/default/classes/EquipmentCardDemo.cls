/**
 * Demo-mode service for the equipment carousel card.
 *
 * Returns a fixed set of installed devices. No SOQL, no custom objects, no
 * config — so the card deploys into any org and renders on the first try. Swap
 * the body of sampleEquipment() for your own query once you've seen it work;
 * the shape the LWC expects is documented in states.json next to this pack.
 */
public with sharing class EquipmentCardDemo {

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
        public EquipmentCardData equipment;
    }

    @InvocableMethod(
        label='Get Equipment (Demo)'
        description='Returns the sample equipment installed at a service address as a renderable carousel card. Always show the equipment output to the user.'
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
            res.equipment = new EquipmentCardData(JSON.serialize(sampleEquipment()));
            res.narrative = 'There are four devices at this service address. The residential '
                + 'gateway is degraded and out of warranty, and the fiber terminal is offline '
                + 'because of the outage in the area rather than a fault of its own.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.equipment = new EquipmentCardData('{"error":"Could not load equipment."}');
            res.narrative = 'I could not load the equipment for this address right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleEquipment() {
        List<Object> devices = new List<Object>{
            device(
                'ONT-500 Fiber Terminal',
                'Optical Network Terminal',
                'ONT500-4417-0231',
                'Apr 2023',
                'Offline',
                'No optical signal. Consistent with the active fiber cut in the 94105 service area — not a device fault.',
                false
            ),
            device(
                'Gateway AX6',
                'Residential Gateway',
                'GWAX6-4417-8890',
                'Aug 2022',
                'Degraded',
                '14 unplanned reboots in the last 30 days and elevated operating temperature. Out of warranty and eligible for replacement.',
                true
            ),
            device(
                'Mesh Extender M2',
                'Mesh Extender',
                'MESHM2-4417-1174',
                'Oct 2025',
                'Healthy',
                'Backhaul stable. Covering the upstairs bedrooms.',
                false
            ),
            device(
                'StreamBox 4K',
                'Set-Top Box',
                'SB4K-4417-6602',
                'Feb 2025',
                'Healthy',
                'Firmware current. No reported playback faults.',
                false
            )
        };

        return new Map<String, Object>{
            'devices' => devices,
            'deviceCount' => devices.size()
        };
    }

    /**
     * Only a degraded device is a genuine hardware fault, so only a degraded
     * device gets rmaEligible. An offline device is usually a symptom of an
     * upstream outage, and offering to replace it sends the rep down the wrong
     * path.
     */
    private static Map<String, Object> device(
        String name,
        String deviceType,
        String serialNumber,
        String installedOn,
        String health,
        String note,
        Boolean rmaEligible
    ) {
        return new Map<String, Object>{
            'name' => name,
            'deviceType' => deviceType,
            'serialNumber' => serialNumber,
            'installedOn' => installedOn,
            'health' => health,
            'note' => note,
            'rmaEligible' => rmaEligible
        };
    }
}
