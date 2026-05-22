/*
 * Post-deploy helper:
 * Assigns Knowledge_AI_Drafting_FLS to the running user.
 *
 * Run after metadata deploy:
 * sf apex run --target-org <alias> --file scripts/post_deploy_assign_permset.apex
 */
Id me = UserInfo.getUserId();

PermissionSet ps = [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name = 'Knowledge_AI_Drafting_FLS'
    LIMIT 1
];

Integer existing = [
    SELECT COUNT()
    FROM PermissionSetAssignment
    WHERE AssigneeId = :me
      AND PermissionSetId = :ps.Id
];

if (existing == 0) {
    insert new PermissionSetAssignment(
        AssigneeId = me,
        PermissionSetId = ps.Id
    );
    System.debug('Assigned Knowledge_AI_Drafting_FLS to current user: ' + me);
} else {
    System.debug('Knowledge_AI_Drafting_FLS already assigned to current user: ' + me);
}
