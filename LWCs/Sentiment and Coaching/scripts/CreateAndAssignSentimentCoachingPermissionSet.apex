/**
 * Anonymous Apex: Create Sentiment Coaching permission set with field permissions
 * AND assign it to all System Administrators.
 *
 * Run in Developer Console: Debug → Open Execute Anonymous Window → paste → Execute.
 */

String permSetName = 'Sentiment_Coaching_Fields';
String permSetLabel = 'Sentiment Coaching Fields';

// ---------- 1. Create Permission Set (if not exists) ----------
List<PermissionSet> existing = [
    SELECT Id, Name, Label 
    FROM PermissionSet 
    WHERE Name = :permSetName 
    AND IsOwnedByProfile = false
    LIMIT 1
];

PermissionSet ps;
if (existing.isEmpty()) {
    ps = new PermissionSet();
    ps.Name = permSetName;
    ps.Label = permSetLabel;
    ps.Description = 'Grants read and edit access to Sentiment Coaching custom fields on Voice Call and Messaging Session.';
    insert ps;
    System.debug('Created permission set: ' + ps.Label);
} else {
    ps = existing[0];
    System.debug('Permission set already exists: ' + ps.Label);
}

// ---------- 2. Discover correct SobjectType values ----------
System.debug('--- Discovering SobjectType values ---');

Map<String, String> objectTypeMap = new Map<String, String>();

// Query ObjectPermissions to find valid SobjectType values
for (ObjectPermissions op : [
    SELECT SobjectType 
    FROM ObjectPermissions 
    WHERE SobjectType IN ('VoiceCall', 'MessagingSession')
    LIMIT 10
]) {
    System.debug('Found ObjectPermissions SobjectType: ' + op.SobjectType);
    objectTypeMap.put(op.SobjectType, op.SobjectType);
}

// If standard names didn't work, look for anything similar
if (objectTypeMap.isEmpty()) {
    System.debug('Standard names not found in ObjectPermissions, querying all...');
    for (ObjectPermissions op : [SELECT SobjectType FROM ObjectPermissions LIMIT 200]) {
        if (op.SobjectType.containsIgnoreCase('voice') || op.SobjectType.containsIgnoreCase('messaging')) {
            System.debug('Found related SobjectType: ' + op.SobjectType);
            if (op.SobjectType.containsIgnoreCase('voice')) {
                objectTypeMap.put('VoiceCall', op.SobjectType);
            }
            if (op.SobjectType.containsIgnoreCase('messaging')) {
                objectTypeMap.put('MessagingSession', op.SobjectType);
            }
        }
    }
}

// Default to standard names if nothing found (will try them)
if (!objectTypeMap.containsKey('VoiceCall')) {
    objectTypeMap.put('VoiceCall', 'VoiceCall');
    System.debug('Using default VoiceCall');
}
if (!objectTypeMap.containsKey('MessagingSession')) {
    objectTypeMap.put('MessagingSession', 'MessagingSession');
    System.debug('Using default MessagingSession');
}

System.debug('Object type map: ' + objectTypeMap);

// ---------- 3. Build field permissions ----------
Set<String> existingFields = new Set<String>();
for (FieldPermissions fp : [SELECT Field FROM FieldPermissions WHERE ParentId = :ps.Id]) {
    existingFields.add(fp.Field);
}

// Define the fields we want to add
Map<String, List<String>> fieldsByObject = new Map<String, List<String>>{
    'VoiceCall' => new List<String>{
        'Agent_Performance_Evaluation__c',
        'Agent_Performance_Rating__c',
        'Call_Sentiment__c',
        'Sentiment_Rating__c',
        'Request_Historical_Analysis__c'
    },
    'MessagingSession' => new List<String>{
        'AgentPerformanceEvaluation__c',
        'AgentPerformanceRating__c',
        'ChatSentiment__c',
        'SentimentRating__c',
        'Request_Historical_Analysis__c'
    }
};

// Try MessagingSession first (more likely to work)
List<String> objectOrder = new List<String>{'MessagingSession', 'VoiceCall'};

for (String objName : objectOrder) {
    String sobjectType = objectTypeMap.get(objName);
    List<FieldPermissions> fpToInsert = new List<FieldPermissions>();
    
    for (String fieldName : fieldsByObject.get(objName)) {
        String fieldRef = objName + '.' + fieldName;
        
        if (!existingFields.contains(fieldRef)) {
            FieldPermissions fp = new FieldPermissions();
            fp.ParentId = ps.Id;
            fp.SobjectType = sobjectType;
            fp.Field = fieldRef;
            fp.PermissionsRead = true;
            fp.PermissionsEdit = true;
            fpToInsert.add(fp);
        }
    }
    
    if (!fpToInsert.isEmpty()) {
        try {
            insert fpToInsert;
            System.debug('Added ' + fpToInsert.size() + ' field permission(s) for ' + objName);
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Failed to add ' + objName + ' fields: ' + e.getMessage());
            System.debug('You may need to add ' + objName + ' field permissions manually in Setup.');
        }
    } else {
        System.debug('All ' + objName + ' field permissions already exist.');
    }
}

// ---------- 4. Assign to System Administrators ----------
List<User> admins = [
    SELECT Id, Username 
    FROM User 
    WHERE Profile.Name = 'System Administrator' 
    AND IsActive = true
];

if (admins.isEmpty()) {
    System.debug('No active System Administrator users found.');
} else {
    Set<Id> alreadyAssigned = new Set<Id>();
    for (PermissionSetAssignment psa : [
        SELECT AssigneeId 
        FROM PermissionSetAssignment 
        WHERE PermissionSetId = :ps.Id
    ]) {
        alreadyAssigned.add(psa.AssigneeId);
    }

    List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
    for (User u : admins) {
        if (!alreadyAssigned.contains(u.Id)) {
            psaToInsert.add(new PermissionSetAssignment(
                PermissionSetId = ps.Id,
                AssigneeId = u.Id
            ));
        }
    }

    if (!psaToInsert.isEmpty()) {
        insert psaToInsert;
        System.debug('Assigned permission set to ' + psaToInsert.size() + ' System Administrator(s).');
    } else {
        System.debug('All System Administrators already have the permission set.');
    }
}

System.debug('Done. Permission set "' + permSetLabel + '" created and assigned to admins.');
System.debug('If VoiceCall fields failed, add them manually: Setup > Permission Sets > ' + permSetLabel + ' > Field Permissions.');
