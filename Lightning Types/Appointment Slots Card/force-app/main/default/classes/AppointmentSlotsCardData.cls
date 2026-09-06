/**
 * Renderer DTO for the appointment slots card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the slot array into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class AppointmentSlotsCardData {

    @AuraEnabled
    global String slotsJSON;

    global AppointmentSlotsCardData(String slotsJSON) {
        this.slotsJSON = slotsJSON;
    }

    // The parameterless constructor is required for deserialization.
    global AppointmentSlotsCardData() {
        this.slotsJSON = '';
    }
}
