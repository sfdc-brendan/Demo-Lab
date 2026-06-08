public with sharing class IntakeFieldDescribe {

    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> listObjects(String search) {
        List<ObjectInfo> results = new List<ObjectInfo>();
        String needle = String.isNotBlank(search) ? search.toLowerCase() : null;

        for (Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult dsr = sot.getDescribe();
            if (!dsr.isCreateable()) continue;
            if (dsr.isCustomSetting()) continue;
            String apiName = dsr.getName();
            if (apiName.endsWithIgnoreCase('__History')
                    || apiName.endsWithIgnoreCase('__Share')
                    || apiName.endsWithIgnoreCase('__Tag')
                    || apiName.endsWithIgnoreCase('__Feed')
                    || apiName.endsWithIgnoreCase('__ChangeEvent')) {
                continue;
            }
            if (needle != null
                    && !apiName.toLowerCase().contains(needle)
                    && !dsr.getLabel().toLowerCase().contains(needle)) {
                continue;
            }
            results.add(new ObjectInfo(apiName, dsr.getLabel()));
        }
        results.sort();
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> listFields(String objectApiName, String typeFilter) {
        List<FieldInfo> results = new List<FieldInfo>();
        if (String.isBlank(objectApiName)) return results;

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectApiName);
        if (sot == null) return results;

        for (Schema.SObjectField f : sot.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if (!dfr.isUpdateable() && !dfr.isCreateable()) continue;
            String typeStr = String.valueOf(dfr.getType()).toLowerCase();
            if (String.isNotBlank(typeFilter) && !matchesTypeFilter(typeStr, typeFilter)) continue;
            results.add(new FieldInfo(dfr.getName(), dfr.getLabel(), typeStr, dfr.isCustom()));
        }
        results.sort();
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistValue> getPicklistValues(String objectApiName, String fieldApiName) {
        List<PicklistValue> results = new List<PicklistValue>();
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) return results;

        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectApiName);
        if (sot == null) return results;

        Schema.SObjectField f = sot.getDescribe().fields.getMap().get(fieldApiName);
        if (f == null) return results;

        for (Schema.PicklistEntry pe : f.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                results.add(new PicklistValue(pe.getLabel(), pe.getValue()));
            }
        }
        return results;
    }

    private static Boolean matchesTypeFilter(String type, String filter) {
        Set<String> textTypes = new Set<String>{ 'string', 'textarea', 'url', 'phone', 'email' };
        Set<String> numericTypes = new Set<String>{ 'double', 'currency', 'integer', 'percent' };

        switch on filter.toLowerCase() {
            when 'text' { return textTypes.contains(type); }
            when 'number' { return numericTypes.contains(type); }
            when 'date' { return type == 'date' || type == 'datetime'; }
            when 'picklist' { return type == 'picklist' || type == 'multipicklist'; }
            when 'boolean' { return type == 'boolean'; }
            when 'reference' { return type == 'reference'; }
            when else { return true; }
        }
    }

    public class ObjectInfo implements Comparable {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        public ObjectInfo(String apiName, String label) {
            this.apiName = apiName;
            this.label = label;
        }
        public Integer compareTo(Object other) {
            return this.label.compareTo(((ObjectInfo) other).label);
        }
    }

    public class FieldInfo implements Comparable {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isCustom;
        public FieldInfo(String apiName, String label, String type, Boolean isCustom) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.isCustom = isCustom;
        }
        public Integer compareTo(Object other) {
            return this.label.compareTo(((FieldInfo) other).label);
        }
    }

    public class PicklistValue {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}
