/**
 * Renderer DTO for the router health and reset card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the nested metrics and reboot history into
 * separate outputs, and so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class RouterResetCardData {

    @AuraEnabled
    global String routerJSON;

    global RouterResetCardData(String routerJSON) {
        this.routerJSON = routerJSON;
    }

    // The parameterless constructor is required for deserialization.
    global RouterResetCardData() {
        this.routerJSON = '';
    }
}
