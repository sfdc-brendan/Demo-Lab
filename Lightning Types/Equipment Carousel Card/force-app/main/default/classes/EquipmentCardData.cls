/**
 * Renderer DTO for the equipment carousel card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the device array into separate outputs,
 * and so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class EquipmentCardData {

    @AuraEnabled
    global String equipmentJSON;

    global EquipmentCardData(String equipmentJSON) {
        this.equipmentJSON = equipmentJSON;
    }

    // The parameterless constructor is required for deserialization.
    global EquipmentCardData() {
        this.equipmentJSON = '';
    }
}
