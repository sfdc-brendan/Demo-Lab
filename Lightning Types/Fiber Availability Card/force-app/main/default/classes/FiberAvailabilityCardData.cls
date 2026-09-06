/**
 * Renderer DTO for the fiber availability card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the structure into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class FiberAvailabilityCardData {

    @AuraEnabled
    global String fiberJSON;

    global FiberAvailabilityCardData(String fiberJSON) {
        this.fiberJSON = fiberJSON;
    }

    // The parameterless constructor is required for deserialization.
    global FiberAvailabilityCardData() {
        this.fiberJSON = '';
    }
}
