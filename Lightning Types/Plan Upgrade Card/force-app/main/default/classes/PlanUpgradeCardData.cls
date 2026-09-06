/**
 * Renderer DTO for the plan upgrade card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the structure into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class PlanUpgradeCardData {

    @AuraEnabled
    global String upgradeJSON;

    global PlanUpgradeCardData(String upgradeJSON) {
        this.upgradeJSON = upgradeJSON;
    }

    // The parameterless constructor is required for deserialization.
    global PlanUpgradeCardData() {
        this.upgradeJSON = '';
    }
}
