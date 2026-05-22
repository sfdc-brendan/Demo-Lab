/*
 * Seed 5 Pearson-specific demo Cases for Einstein Knowledge Creation.
 *
 * Cases are tagged with [KC-DEMO-PEARSON] and are idempotent:
 * re-running this script deletes previous Pearson demo cases first.
 *
 * Each case includes:
 * - Rich Description (customer problem + environment details)
 * - 4 Case Comments (triage, root cause, workaround, final resolution)
 * - 3 EmailMessage records (customer + agent conversation)
 */

// 0) Idempotency: remove prior Pearson demo cases.
List<Case> oldCases = [SELECT Id FROM Case WHERE Subject LIKE '[KC-DEMO-PEARSON]%'];
if (!oldCases.isEmpty()) {
    delete oldCases;
}

// 1) Ensure Accounts exist.
Map<String, Account> acctsByName = new Map<String, Account>();
for (Account a : [
    SELECT Id, Name
    FROM Account
    WHERE Name IN (
        'Pearson Higher Education',
        'Pearson VUE Enterprise Testing',
        'Pearson K-12 District Services',
        'Pearson Digital Learning Support',
        'Pearson Integration Services'
    )
]) {
    acctsByName.put(a.Name, a);
}

List<Account> newAccts = new List<Account>();
if (!acctsByName.containsKey('Pearson Higher Education')) {
    newAccts.add(new Account(Name='Pearson Higher Education', Industry='Education'));
}
if (!acctsByName.containsKey('Pearson VUE Enterprise Testing')) {
    newAccts.add(new Account(Name='Pearson VUE Enterprise Testing', Industry='Education'));
}
if (!acctsByName.containsKey('Pearson K-12 District Services')) {
    newAccts.add(new Account(Name='Pearson K-12 District Services', Industry='Education'));
}
if (!acctsByName.containsKey('Pearson Digital Learning Support')) {
    newAccts.add(new Account(Name='Pearson Digital Learning Support', Industry='Education'));
}
if (!acctsByName.containsKey('Pearson Integration Services')) {
    newAccts.add(new Account(Name='Pearson Integration Services', Industry='Technology'));
}
if (!newAccts.isEmpty()) {
    insert newAccts;
    for (Account a : newAccts) {
        acctsByName.put(a.Name, a);
    }
}

// 2) Ensure one contact per account.
Map<Id, Contact> contactByAcct = new Map<Id, Contact>();
for (Contact c : [
    SELECT Id, AccountId
    FROM Contact
    WHERE AccountId IN :acctsByName.values()
    ORDER BY CreatedDate
]) {
    if (!contactByAcct.containsKey(c.AccountId)) {
        contactByAcct.put(c.AccountId, c);
    }
}

List<Contact> newContacts = new List<Contact>();
Account aHE   = acctsByName.get('Pearson Higher Education');
Account aVUE  = acctsByName.get('Pearson VUE Enterprise Testing');
Account aK12  = acctsByName.get('Pearson K-12 District Services');
Account aDL   = acctsByName.get('Pearson Digital Learning Support');
Account aINT  = acctsByName.get('Pearson Integration Services');

if (!contactByAcct.containsKey(aHE.Id)) {
    newContacts.add(new Contact(
        FirstName='Maya',
        LastName='Lopez',
        Email='maya.lopez@pearson-he.example',
        Title='Course Coordinator',
        AccountId=aHE.Id
    ));
}
if (!contactByAcct.containsKey(aVUE.Id)) {
    newContacts.add(new Contact(
        FirstName='Andre',
        LastName='Patel',
        Email='andre.patel@pearsonvue.example',
        Title='Testing Center Operations Manager',
        AccountId=aVUE.Id
    ));
}
if (!contactByAcct.containsKey(aK12.Id)) {
    newContacts.add(new Contact(
        FirstName='Elena',
        LastName='Brooks',
        Email='elena.brooks@pearsonk12.example',
        Title='District Assessment Admin',
        AccountId=aK12.Id
    ));
}
if (!contactByAcct.containsKey(aDL.Id)) {
    newContacts.add(new Contact(
        FirstName='Jordan',
        LastName='Ng',
        Email='jordan.ng@pearsonplus.example',
        Title='Subscriber Success Specialist',
        AccountId=aDL.Id
    ));
}
if (!contactByAcct.containsKey(aINT.Id)) {
    newContacts.add(new Contact(
        FirstName='Rina',
        LastName='Chen',
        Email='rina.chen@pearsonlti.example',
        Title='LMS Integration Engineer',
        AccountId=aINT.Id
    ));
}
if (!newContacts.isEmpty()) {
    insert newContacts;
    for (Contact c : newContacts) {
        contactByAcct.put(c.AccountId, c);
    }
}

// 3) Use Service Case record type.
Id serviceCaseRtId;
for (RecordType rt : [
    SELECT Id
    FROM RecordType
    WHERE SobjectType='Case' AND DeveloperName='SDO_Service_Case'
    LIMIT 1
]) {
    serviceCaseRtId = rt.Id;
}

// 4) Create 5 Pearson demo cases.
List<Case> pearsonCases = new List<Case>();

// A) MyLab assignment sync issue
Case c1 = new Case(
    AccountId=aHE.Id,
    ContactId=contactByAcct.get(aHE.Id).Id,
    RecordTypeId=serviceCaseRtId,
    Subject='[KC-DEMO-PEARSON] MyLab assignment scores not syncing to Canvas gradebook',
    Type='Problem',
    Origin='Email',
    Priority='High',
    Status='New',
    Description=
        'Faculty reported that student submissions in MyLab Statistics are grading correctly ' +
        'inside MyLab, but scores are not posting to the Canvas gradebook for Assignment Group ' +
        '"Homework Week 3". Problem started after SIS roster refresh on 2026-05-18. ' +
        'Environment: Canvas LMS (production), MyLab integration via LTI 1.3, course shell ' +
        'STAT-201-22341. Approximately 180 students affected. Instructors need grades synced ' +
        'before midterm cutoff at 11:59 PM ET.'
);
pearsonCases.add(c1);

// B) Pearson VUE check-in ID mismatch
Case c2 = new Case(
    AccountId=aVUE.Id,
    ContactId=contactByAcct.get(aVUE.Id).Id,
    RecordTypeId=serviceCaseRtId,
    Subject='[KC-DEMO-PEARSON] Pearson VUE candidate blocked at check-in due to name mismatch',
    Type='Question',
    Origin='Phone',
    Priority='Medium',
    Status='New',
    Description=
        'Testing center staff report multiple candidates being rejected at check-in because the ' +
        'name on government ID includes a middle initial while the exam registration record does not. ' +
        'The exam delivery workstation shows "Identity Verification Failed: Name mismatch threshold exceeded." ' +
        'Environment: Pearson VUE test center app v12.7, secure browser kiosk mode, ' +
        'high-stakes certification exams. Team needs a standard support workflow to avoid same-day ' +
        'exam cancellations when mismatch is minor and identity is otherwise valid.'
);
pearsonCases.add(c2);

// C) eText offline access on iPad
Case c3 = new Case(
    AccountId=aK12.Id,
    ContactId=contactByAcct.get(aK12.Id).Id,
    RecordTypeId=serviceCaseRtId,
    Subject='[KC-DEMO-PEARSON] Pearson eText iPad app loses downloaded chapters in offline mode',
    Type='Problem',
    Origin='Web',
    Priority='Medium',
    Status='New',
    Description=
        'District devices using Pearson eText on managed iPads show downloaded chapters as available, ' +
        'but content disappears after app restart when students are offline on school buses. ' +
        'Issue appears on iPadOS 18.2 with app version 6.14 and MDM storage optimization policy enabled. ' +
        'Teachers report students cannot complete reading assignments outside Wi-Fi coverage. ' +
        'Need immediate workaround and long-term fix guidance before next grading cycle.'
);
pearsonCases.add(c3);

// D) Pearson+ subscription entitlement delay
Case c4 = new Case(
    AccountId=aDL.Id,
    ContactId=contactByAcct.get(aDL.Id).Id,
    RecordTypeId=serviceCaseRtId,
    Subject='[KC-DEMO-PEARSON] Pearson+ paid subscribers still seeing paywall after upgrade',
    Type='Problem',
    Origin='Chat',
    Priority='High',
    Status='New',
    Description=
        'Customer support reports spike in chats where learners complete payment for Pearson+ ' +
        'Premium but continue to see "Upgrade to unlock chapter quizzes" for up to 45 minutes. ' +
        'Payment processor confirms successful charge and user receipt email is sent immediately. ' +
        'Environment: Pearson+ web app, entitlement service v4, cache layer Redis cluster us-east-1. ' +
        'Need knowledge article for agents to verify entitlement state, force refresh safely, and ' +
        'decide when to issue goodwill credit.'
);
pearsonCases.add(c4);

// E) LTI deep-linking duplicate grade columns
Case c5 = new Case(
    AccountId=aINT.Id,
    ContactId=contactByAcct.get(aINT.Id).Id,
    RecordTypeId=serviceCaseRtId,
    Subject='[KC-DEMO-PEARSON] LTI deep-linking creates duplicate assignment columns in Blackboard',
    Type='Problem',
    Origin='Email',
    Priority='Low',
    Status='New',
    Description=
        'Integration team observed duplicate grade columns being created in Blackboard Ultra when ' +
        'instructors deep-link Pearson content more than once to the same module. Duplicates cause ' +
        'gradebook confusion and occasional overwrite of weighted category settings. ' +
        'Environment: Blackboard Ultra SaaS, LTI 1.3 Advantage, Pearson content tool v2.9. ' +
        'Need repeatable steps to prevent duplicates and cleanup guidance for already impacted courses.'
);
pearsonCases.add(c5);

insert pearsonCases;

Id c1Id = c1.Id;
Id c2Id = c2.Id;
Id c3Id = c3.Id;
Id c4Id = c4.Id;
Id c5Id = c5.Id;

// 5) Add case comments (triage + root cause + workaround + resolution).
List<CaseComment> cc = new List<CaseComment>();

// Case 1 comments
cc.add(new CaseComment(ParentId=c1Id, IsPublished=true, CommentBody=
    'Triage confirmed LTI launch and assignment retrieval are healthy. Manual grade sync API calls from MyLab to Canvas return HTTP 200 for 92% of students, but 8% fail with roster mismatch on user IDs.'));
cc.add(new CaseComment(ParentId=c1Id, IsPublished=true, CommentBody=
    'Root cause: SIS refresh changed Canvas user SIS IDs for a subset of students while MyLab still held stale cached IDs. Grade sync service rejects postbacks when user mapping checksum does not match current roster.'));
cc.add(new CaseComment(ParentId=c1Id, IsPublished=true, CommentBody=
    'Workaround: run "Roster Reconcile" from the MyLab LMS Integration admin panel, then trigger "Repost Missing Grades" for affected assignment group. This backfills grades without reopening submissions.'));
cc.add(new CaseComment(ParentId=c1Id, IsPublished=true, CommentBody=
    'Resolution applied: completed roster reconcile + grade repost. 180/180 students now show grades in Canvas within 6 minutes. Added proactive monitor alert when SIS mapping drift exceeds 2%.'));

// Case 2 comments
cc.add(new CaseComment(ParentId=c2Id, IsPublished=true, CommentBody=
    'Validated issue at center: candidates with minor name variations (middle initial, hyphen) fail automated threshold check despite matching DOB and confirmation number.'));
cc.add(new CaseComment(ParentId=c2Id, IsPublished=true, CommentBody=
    'Root cause: stricter identity matching policy deployed in v12.7 changed fuzzy-name threshold from 0.82 to 0.94 without updating center runbook for exception handling.'));
cc.add(new CaseComment(ParentId=c2Id, IsPublished=true, CommentBody=
    'Workaround for same-day appointments: use Supervisor Override flow when government ID + candidate photo + DOB match, and record reason code "Minor Name Variation".'));
cc.add(new CaseComment(ParentId=c2Id, IsPublished=true, CommentBody=
    'Resolution: distributed updated check-in SOP and restored threshold to 0.88 for low-risk exams while policy team finalizes permanent standards. Candidate no-show rate normalized.'));

// Case 3 comments
cc.add(new CaseComment(ParentId=c3Id, IsPublished=true, CommentBody=
    'Replicated on managed iPad: downloaded chapter metadata persists, but content files are evicted after app restart when MDM "Offload unused app data" policy runs.'));
cc.add(new CaseComment(ParentId=c3Id, IsPublished=true, CommentBody=
    'Root cause: eText cache directory was incorrectly tagged as purgeable by iPad storage optimization profile. App interpreted missing blobs as expired downloads.'));
cc.add(new CaseComment(ParentId=c3Id, IsPublished=true, CommentBody=
    'Workaround: set district MDM profile to exempt Pearson eText app from data offload and instruct users to keep "Offline Mode Lock" enabled per class period.'));
cc.add(new CaseComment(ParentId=c3Id, IsPublished=true, CommentBody=
    'Resolution: hotfix 6.14.2 writes offline chapters to protected container path and verifies integrity at launch. District pilot confirms offline chapters persist across restarts.'));

// Case 4 comments
cc.add(new CaseComment(ParentId=c4Id, IsPublished=true, CommentBody=
    'Payments verified successful in gateway logs; entitlement lookup service shows delayed propagation for users routed to stale cache shard.'));
cc.add(new CaseComment(ParentId=c4Id, IsPublished=true, CommentBody=
    'Root cause: Redis shard failover left stale entitlement entries with 30-minute TTL. Frontend trusted cached deny-state instead of authoritative entitlement service response.'));
cc.add(new CaseComment(ParentId=c4Id, IsPublished=true, CommentBody=
    'Workaround: agent runs entitlement refresh action in Support Console, asks learner to sign out/in, then validates premium access via /me/entitlements endpoint.'));
cc.add(new CaseComment(ParentId=c4Id, IsPublished=true, CommentBody=
    'Resolution: deployed cache invalidation patch to always purge deny-state on successful payment webhook. Median post-payment unlock time reduced from 22 minutes to under 90 seconds.'));

// Case 5 comments
cc.add(new CaseComment(ParentId=c5Id, IsPublished=true, CommentBody=
    'Observed duplicate columns when instructor deep-links same Pearson activity multiple times without selecting existing gradebook item. Blackboard accepts each LTI line item as new.'));
cc.add(new CaseComment(ParentId=c5Id, IsPublished=true, CommentBody=
    'Root cause: tool did not pass stable lineItemId on repeated deep-link operations; generated a new UUID each launch, creating additional columns.'));
cc.add(new CaseComment(ParentId=c5Id, IsPublished=true, CommentBody=
    'Workaround: instructors must choose "Attach to existing grade column" in deep-link wizard and avoid creating fresh links for already-linked activities.'));
cc.add(new CaseComment(ParentId=c5Id, IsPublished=true, CommentBody=
    'Resolution: tool v2.9.3 now reuses deterministic lineItemId based on courseId+activityId, and includes admin cleanup script for duplicate columns created before patch.'));

insert cc;

// 6) Add email threads for each case.
List<EmailMessage> em = new List<EmailMessage>();
DateTime t0 = DateTime.now().addDays(-5);

// Case 1 emails
em.add(new EmailMessage(ParentId=c1Id, Status='0', Incoming=true, FromAddress='maya.lopez@pearson-he.example', FromName='Maya Lopez',
    ToAddress='support@pearson.example', Subject='Canvas not receiving MyLab assignment grades',
    TextBody='Our STAT-201 section shows grades in MyLab but not in Canvas for Week 3 homework. Midterm grading deadline is tonight. Please advise urgent recovery steps.',
    MessageDate=t0));
em.add(new EmailMessage(ParentId=c1Id, Status='3', Incoming=false, FromAddress='support@pearson.example', FromName='Pearson Support',
    ToAddress='maya.lopez@pearson-he.example', Subject='RE: Canvas not receiving MyLab assignment grades',
    TextBody='We confirmed a roster ID drift after SIS refresh. Please run Roster Reconcile, then Repost Missing Grades from Integration Admin. This should backfill all missing grades.',
    MessageDate=t0.addHours(2)));
em.add(new EmailMessage(ParentId=c1Id, Status='0', Incoming=true, FromAddress='maya.lopez@pearson-he.example', FromName='Maya Lopez',
    ToAddress='support@pearson.example', Subject='RE: Canvas not receiving MyLab assignment grades',
    TextBody='Confirmed. Grades are now visible for all students in Canvas. Thank you.',
    MessageDate=t0.addHours(3)));

// Case 2 emails
em.add(new EmailMessage(ParentId=c2Id, Status='0', Incoming=true, FromAddress='andre.patel@pearsonvue.example', FromName='Andre Patel',
    ToAddress='support@pearson.example', Subject='Candidates blocked at check-in due to middle initial mismatch',
    TextBody='Several candidates are failing ID verification because registration name omits middle initial. Need approved exception process to avoid cancellations.',
    MessageDate=t0.addDays(1)));
em.add(new EmailMessage(ParentId=c2Id, Status='3', Incoming=false, FromAddress='support@pearson.example', FromName='Pearson Support',
    ToAddress='andre.patel@pearsonvue.example', Subject='RE: Candidates blocked at check-in due to middle initial mismatch',
    TextBody='Use Supervisor Override where ID, DOB, and photo match; log reason code Minor Name Variation. We also rolled back matching strictness and sent updated SOP.',
    MessageDate=t0.addDays(1).addHours(1)));
em.add(new EmailMessage(ParentId=c2Id, Status='0', Incoming=true, FromAddress='andre.patel@pearsonvue.example', FromName='Andre Patel',
    ToAddress='support@pearson.example', Subject='RE: Candidates blocked at check-in due to middle initial mismatch',
    TextBody='SOP received. Team processed today appointments without incident.',
    MessageDate=t0.addDays(1).addHours(2)));

// Case 3 emails
em.add(new EmailMessage(ParentId=c3Id, Status='0', Incoming=true, FromAddress='elena.brooks@pearsonk12.example', FromName='Elena Brooks',
    ToAddress='support@pearson.example', Subject='Offline chapters disappear on iPad restart',
    TextBody='Students download chapters at school, but content disappears after app restart when offline. Need workaround before next week.',
    MessageDate=t0.addDays(2)));
em.add(new EmailMessage(ParentId=c3Id, Status='3', Incoming=false, FromAddress='support@pearson.example', FromName='Pearson Support',
    ToAddress='elena.brooks@pearsonk12.example', Subject='RE: Offline chapters disappear on iPad restart',
    TextBody='Please exempt Pearson eText from MDM data offload and keep Offline Mode Lock enabled. App hotfix 6.14.2 is now available and resolves this.',
    MessageDate=t0.addDays(2).addHours(2)));
em.add(new EmailMessage(ParentId=c3Id, Status='0', Incoming=true, FromAddress='elena.brooks@pearsonk12.example', FromName='Elena Brooks',
    ToAddress='support@pearson.example', Subject='RE: Offline chapters disappear on iPad restart',
    TextBody='Hotfix and MDM change fixed it in pilot classrooms. We will roll out district-wide.',
    MessageDate=t0.addDays(2).addHours(4)));

// Case 4 emails
em.add(new EmailMessage(ParentId=c4Id, Status='0', Incoming=true, FromAddress='jordan.ng@pearsonplus.example', FromName='Jordan Ng',
    ToAddress='support@pearson.example', Subject='Paid Pearson+ users still blocked by paywall',
    TextBody='Customers complete payment but still see premium content locked for up to 45 minutes. Please share support flow and technical fix details.',
    MessageDate=t0.addDays(3)));
em.add(new EmailMessage(ParentId=c4Id, Status='3', Incoming=false, FromAddress='support@pearson.example', FromName='Pearson Support',
    ToAddress='jordan.ng@pearsonplus.example', Subject='RE: Paid Pearson+ users still blocked by paywall',
    TextBody='Root cause is stale cache deny-state after failover. Agents should run entitlement refresh, then ask user to re-login. Patch now invalidates deny-state on payment webhook.',
    MessageDate=t0.addDays(3).addHours(1)));
em.add(new EmailMessage(ParentId=c4Id, Status='0', Incoming=true, FromAddress='jordan.ng@pearsonplus.example', FromName='Jordan Ng',
    ToAddress='support@pearson.example', Subject='RE: Paid Pearson+ users still blocked by paywall',
    TextBody='Great — unlock latency is now under 2 minutes in monitoring. Closing this.',
    MessageDate=t0.addDays(3).addHours(3)));

// Case 5 emails
em.add(new EmailMessage(ParentId=c5Id, Status='0', Incoming=true, FromAddress='rina.chen@pearsonlti.example', FromName='Rina Chen',
    ToAddress='support@pearson.example', Subject='Duplicate grade columns from deep-linking in Blackboard',
    TextBody='Instructors see duplicate columns when re-linking existing Pearson activities. Need prevention steps and cleanup guidance.',
    MessageDate=t0.addDays(4)));
em.add(new EmailMessage(ParentId=c5Id, Status='3', Incoming=false, FromAddress='support@pearson.example', FromName='Pearson Support',
    ToAddress='rina.chen@pearsonlti.example', Subject='RE: Duplicate grade columns from deep-linking in Blackboard',
    TextBody='Until patch is everywhere, select Attach to existing grade column during deep-linking. Tool v2.9.3 now uses deterministic lineItemId and includes cleanup script.',
    MessageDate=t0.addDays(4).addHours(2)));
em.add(new EmailMessage(ParentId=c5Id, Status='0', Incoming=true, FromAddress='rina.chen@pearsonlti.example', FromName='Rina Chen',
    ToAddress='support@pearson.example', Subject='RE: Duplicate grade columns from deep-linking in Blackboard',
    TextBody='Confirmed this resolves new links and cleanup script worked for impacted courses.',
    MessageDate=t0.addDays(4).addHours(4)));

insert em;

// 7) Set cases to Working (avoid org-specific closed-case flow errors).
List<Case> updates = [SELECT Id, Status FROM Case WHERE Id IN :pearsonCases];
for (Case c : updates) {
    c.Status = 'Working';
}
update updates;

// 8) Output summary.
List<Case> created = [
    SELECT Id, CaseNumber, Subject, Status, Account.Name,
        (SELECT Id FROM CaseComments),
        (SELECT Id FROM EmailMessages)
    FROM Case
    WHERE Id IN :pearsonCases
    ORDER BY CaseNumber
];
System.debug('=== PEARSON SEED RESULT ===');
for (Case c : created) {
    System.debug(
        'Case ' + c.CaseNumber +
        ' [' + c.Status + ']' +
        ' Account=' + c.Account.Name +
        ' Comments=' + c.CaseComments.size() +
        ' Emails=' + c.EmailMessages.size() +
        ' Subject=' + c.Subject
    );
}
