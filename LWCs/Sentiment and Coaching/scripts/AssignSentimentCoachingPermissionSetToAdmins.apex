/**
 * Anonymous Apex: Assign Sentiment Coaching permission set to all System Administrators.
 *
 * PREREQUISITE: The permission set must already exist in the org. Deploy it first, e.g.:
 *   sf project deploy start --metadata PermissionSet:Sentiment_Coaching_Fields_Only --target-org "Winter 25"
 * Or create it in Setup → Permission Sets, then run this script in Developer Console (Debug → Open Execute Anonymous Window).
 *
 * This script:
 * 1. Finds the permission set by name (tries Sentiment_Coaching_Fields_Only, then Sentiment_Coaching_Fields).
 * 2. Finds all users with the System Administrator profile (active users only).
 * 3. Assigns the permission set to each admin who does not already have it.
 */

// Permission set names to try (first found wins)
List<String> permissionSetNames = new List<String>{
    'Sentiment_Coaching_Fields_Only',
    'Sentiment_Coaching_Fields'
};

List<PermissionSet> permissionSets = [
    SELECT Id, Name, Label
    FROM PermissionSet
    WHERE Name IN :permissionSetNames
    AND IsOwnedByProfile = false
    LIMIT 1
];

if (permissionSets.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'Sentiment Coaching: No permission set found. Deploy or create one of: ' + permissionSetNames);
    throw new Exception('Permission set not found. Deploy PermissionSet Sentiment_Coaching_Fields_Only (or Sentiment_Coaching_Fields) first.');
}

PermissionSet ps = permissionSets[0];
System.debug('Using permission set: ' + ps.Label + ' (' + ps.Name + ')');

// All active users with System Administrator profile
List<User> admins = [
    SELECT Id, Username, Profile.Name
    FROM User
    WHERE Profile.Name = 'System Administrator'
    AND IsActive = true
];

if (admins.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'Sentiment Coaching: No active System Administrator users found.');
} else {
    Set<Id> existingAssigneeIds = new Set<Id>();
    for (PermissionSetAssignment psa : [
        SELECT AssigneeId
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :ps.Id
    ]) {
        existingAssigneeIds.add(psa.AssigneeId);
    }

    List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
    for (User u : admins) {
        if (!existingAssigneeIds.contains(u.Id)) {
            toInsert.add(new PermissionSetAssignment(
                PermissionSetId = ps.Id,
                AssigneeId = u.Id
            ));
        }
    }

    if (toInsert.isEmpty()) {
        System.debug('Sentiment Coaching: All System Administrators already have the permission set assigned.');
    } else {
        insert toInsert;
        System.debug('Sentiment Coaching: Assigned permission set to ' + toInsert.size() + ' user(s).');
    }
}
