/**
 * Renderer DTO for the customer profile card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the structure into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class CustomerProfileCardData {

    @AuraEnabled
    global String profileJSON;

    global CustomerProfileCardData(String profileJSON) {
        this.profileJSON = profileJSON;
    }

    // The parameterless constructor is required for deserialization.
    global CustomerProfileCardData() {
        this.profileJSON = '';
    }
}
