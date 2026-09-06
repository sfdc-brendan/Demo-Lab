/**
 * Demo-mode service for the appointment slots card.
 *
 * Returns a fixed set of technician visit windows. No SOQL, no custom objects,
 * no config — so the card deploys into any org and renders on the first try.
 * Swap the body of sampleSlots() for your own scheduling query once you've seen
 * it work; the shape the LWC expects is documented in states.json next to this
 * pack.
 */
public with sharing class AppointmentSlotsCardDemo {

    private static final String AM_LABEL = '8:00 AM - 12:00 PM';
    private static final String PM_LABEL = '1:00 PM - 5:00 PM';

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
        public AppointmentSlotsCardData appointmentSlots;
    }

    @InvocableMethod(
        label='Get Appointment Slots (Demo)'
        description='Returns sample technician visit windows as a renderable card the customer can pick from. Always show the appointmentSlots output to the user.'
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
            res.appointmentSlots = new AppointmentSlotsCardData(JSON.serialize(sampleSlots()));
            res.narrative = 'Here are the technician visit windows open at this address over the '
                + 'next three business days. Monday afternoon is the soonest one.';
        } catch (Exception e) {
            // The displayable output must never be null. A null here makes the
            // planner route the result as plain text and the card never mounts,
            // so failures ship a sentinel the LWC knows how to render instead.
            res.appointmentSlots = new AppointmentSlotsCardData('{"error":"Could not load appointment slots."}');
            res.narrative = 'I could not load the available appointment slots right now.';
        }
        return res;
    }

    private static Map<String, Object> sampleSlots() {
        // Monday morning is absent because it is already booked. Real
        // availability has holes in it, and the card should show that.
        List<Map<String, Object>> slots = new List<Map<String, Object>>{
            slot('2026-09-07', 'Afternoon', 'Monday', 'Sep 7'),
            slot('2026-09-08', 'Morning', 'Tuesday', 'Sep 8'),
            slot('2026-09-08', 'Afternoon', 'Tuesday', 'Sep 8'),
            slot('2026-09-09', 'Morning', 'Wednesday', 'Sep 9'),
            slot('2026-09-09', 'Afternoon', 'Wednesday', 'Sep 9')
        };

        // The first remaining slot is the soonest one, so flag it as the
        // default rather than making the rep compare dates.
        slots[0].put('soonest', true);

        return new Map<String, Object>{
            'slots' => slots,
            'slotCount' => slots.size()
        };
    }

    private static Map<String, Object> slot(String isoDate, String window, String dayName, String dateLabel) {
        return new Map<String, Object>{
            'slotId' => isoDate + '_' + window,
            'isoDate' => isoDate,
            'window' => window,
            'dayName' => dayName,
            'dateLabel' => dateLabel,
            'windowLabel' => window == 'Morning' ? AM_LABEL : PM_LABEL
        };
    }
}
