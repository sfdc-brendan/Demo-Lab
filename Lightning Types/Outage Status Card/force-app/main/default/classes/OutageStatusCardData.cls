/**
 * Renderer DTO for the outage status card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the structure into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class OutageStatusCardData {

    @AuraEnabled
    global String outageJSON;

    global OutageStatusCardData(String outageJSON) {
        this.outageJSON = outageJSON;
    }

    // The parameterless constructor is required for deserialization.
    global OutageStatusCardData() {
        this.outageJSON = '';
    }
}
