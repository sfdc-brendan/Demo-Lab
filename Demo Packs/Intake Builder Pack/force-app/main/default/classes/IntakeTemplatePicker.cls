/**
 * Lightning App Builder dynamic picklist for Intake_Template__c records.
 *
 * Wired into intakeRuntime.js-meta.xml so admins pick a template by name
 * instead of pasting a Salesforce Id. Leaving the property blank in App
 * Builder is supported — the runtime LWC will render its own template
 * chooser for the agent.
 */
global with sharing class IntakeTemplatePicker extends VisualEditor.DynamicPickList {

    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('— Let agent choose at runtime —', '');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows rows = new VisualEditor.DynamicPickListRows();
        rows.addRow(new VisualEditor.DataRow('— Let agent choose at runtime —', ''));
        for (Intake_Template__c t : [
            SELECT Id, Name, Version__c, Status__c
            FROM Intake_Template__c
            ORDER BY Name ASC, Version__c DESC
            LIMIT 200
        ]) {
            String label = t.Version__c != null
                ? t.Name + ' (v' + String.valueOf(t.Version__c) + ')'
                : t.Name;
            if (String.isNotBlank(t.Status__c)) {
                label += ' — ' + t.Status__c;
            }
            rows.addRow(new VisualEditor.DataRow(label, String.valueOf(t.Id)));
        }
        return rows;
    }
}
