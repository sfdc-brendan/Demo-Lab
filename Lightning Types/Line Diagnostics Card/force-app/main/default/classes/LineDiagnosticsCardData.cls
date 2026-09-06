/**
 * Renderer DTO for the line diagnostics card.
 *
 * One @AuraEnabled String by design. The whole payload travels as serialized
 * JSON so Agent Builder can't flatten the metric list into separate outputs, and
 * so nested shapes survive the chat boundary intact.
 *
 * One DTO per renderer — never share it between cards.
 */
@JsonAccess(serializable='always' deserializable='always')
global class LineDiagnosticsCardData {

    @AuraEnabled
    global String diagnosticsJSON;

    global LineDiagnosticsCardData(String diagnosticsJSON) {
        this.diagnosticsJSON = diagnosticsJSON;
    }

    // The parameterless constructor is required for deserialization.
    global LineDiagnosticsCardData() {
        this.diagnosticsJSON = '';
    }
}
