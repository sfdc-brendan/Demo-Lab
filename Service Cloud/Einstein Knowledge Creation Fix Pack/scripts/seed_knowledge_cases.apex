/*
 * Seed 3 closed Cases with rich, AI-friendly content for Einstein Knowledge Creation.
 *
 * Each case has: full Description (problem), 4 Case Comments (diagnosis/resolution dialogue),
 * and 3 Email Messages (customer + agent thread). Subjects are tagged "[KC-DEMO]" so the
 * script is idempotent: re-running deletes the prior demo cases first.
 */

// ---- 0. Idempotency: wipe any prior KC-DEMO cases ----------------------------------------
List<Case> existing = [SELECT Id FROM Case WHERE Subject LIKE '[KC-DEMO]%'];
if (!existing.isEmpty()) {
    System.debug('Removing ' + existing.size() + ' existing demo case(s)');
    delete existing;
}

// ---- 1. Resolve / create Accounts and Contacts -------------------------------------------
Map<String, Account> acctsByName = new Map<String, Account>();
for (Account a : [SELECT Id, Name FROM Account
                  WHERE Name IN ('CircuitForge Customer Account',
                                 'MetroWave Communications',
                                 'NovaMart Retail')]) {
    acctsByName.put(a.Name, a);
}

List<Account> toInsert = new List<Account>();
if (!acctsByName.containsKey('MetroWave Communications')) {
    toInsert.add(new Account(Name='MetroWave Communications', Industry='Communications'));
}
if (!acctsByName.containsKey('NovaMart Retail')) {
    toInsert.add(new Account(Name='NovaMart Retail', Industry='Retail'));
}
if (!toInsert.isEmpty()) {
    insert toInsert;
    for (Account a : toInsert) acctsByName.put(a.Name, a);
}

Account circuitforge = acctsByName.get('CircuitForge Customer Account');
Account metrowave    = acctsByName.get('MetroWave Communications');
Account novamart     = acctsByName.get('NovaMart Retail');

// One contact per account (created if missing)
Map<Id, Contact> contactByAcct = new Map<Id, Contact>();
for (Contact c : [SELECT Id, AccountId FROM Contact
                  WHERE AccountId IN :acctsByName.values() ORDER BY CreatedDate LIMIT 50]) {
    if (!contactByAcct.containsKey(c.AccountId)) contactByAcct.put(c.AccountId, c);
}
List<Contact> newContacts = new List<Contact>();
if (!contactByAcct.containsKey(circuitforge.Id)) {
    newContacts.add(new Contact(FirstName='Priya', LastName='Ramaswamy', Email='priya.ramaswamy@circuitforge.example',
        Phone='+1-415-555-0142', AccountId=circuitforge.Id, Title='Operations Lead'));
}
if (!contactByAcct.containsKey(metrowave.Id)) {
    newContacts.add(new Contact(FirstName='Marcus', LastName='Bell', Email='marcus.bell@metrowave.example',
        Phone='+1-212-555-0188', AccountId=metrowave.Id, Title='Subscriber'));
}
if (!contactByAcct.containsKey(novamart.Id)) {
    newContacts.add(new Contact(FirstName='Avery', LastName='Tan', Email='avery.tan@novamart.example',
        Phone='+1-646-555-0199', AccountId=novamart.Id, Title='Loyalty Member'));
}
if (!newContacts.isEmpty()) {
    insert newContacts;
    for (Contact c : newContacts) contactByAcct.put(c.AccountId, c);
}

// ---- 2. Pick the SDO_Service_Case record type so the SDO - Case layout can apply --------
Id serviceCaseRtId;
for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType
                      WHERE SobjectType='Case' AND DeveloperName='SDO_Service_Case' LIMIT 1]) {
    serviceCaseRtId = rt.Id;
}

// ---- 3. Build the 3 case scenarios -------------------------------------------------------
// Each scenario is a tuple: subject, description, list of comments, list of emails.
// Designed so Einstein can extract: Question, Resolution, Issue, Root Cause, Summary,
// Environment, Process Steps, Troubleshooting Steps, Workaround, Answer, Problem.

List<Case> casesToInsert = new List<Case>();

// --- Scenario A: CircuitForge Robotics - firmware rollback --------------------------------
Case caseA = new Case(
    AccountId      = circuitforge.Id,
    ContactId      = contactByAcct.get(circuitforge.Id).Id,
    RecordTypeId   = serviceCaseRtId,
    Subject        = '[KC-DEMO] Warehouse robots dropping navigation markers after firmware 4.2.1 update',
    Type           = 'Problem',
    Origin         = 'Email',
    Priority       = 'High',
    Status         = 'New',
    Description    =
        'Customer reports two ForgeBot-X4 warehouse robots (serials FB-X4-2241 and FB-X4-2247) ' +
        'began intermittently dropping ArUco navigation markers from their localization pipeline ' +
        'roughly 30 minutes after the firmware 4.2.1 over-the-air update was applied. The robots ' +
        'fall back to wheel odometry, drift ~40cm over a 10m run, and eventually halt with error ' +
        'code NAV_MARKER_LOST. Other robots on firmware 4.1.7 in the same facility are unaffected. ' +
        'Environment: ForgeBot-X4 fleet, firmware 4.2.1, FleetOps Console v3.6, Wi-Fi 6 mesh ' +
        '(Aruba), warehouse 4 in Memphis TN. Customer needs robots back online before the 6am ' +
        'pick shift.'
);
casesToInsert.add(caseA);

// --- Scenario B: MetroWave Communications - international roaming overcharge --------------
Case caseB = new Case(
    AccountId      = metrowave.Id,
    ContactId      = contactByAcct.get(metrowave.Id).Id,
    RecordTypeId   = serviceCaseRtId,
    Subject        = '[KC-DEMO] Unexpected international roaming charges on Italy trip - $487 over plan',
    Type           = 'Question',
    Origin         = 'Phone',
    Priority       = 'Medium',
    Status         = 'New',
    Description    =
        'Subscriber on the MetroWave Unlimited Global plan returned from a 9-day trip to Italy ' +
        'and was billed $487 in international roaming data charges despite the plan including ' +
        '"unlimited data in 140+ countries." Subscriber reports the device (iPhone 15 Pro, line ' +
        '+1-212-555-0188) was set to LTE/5G Auto and connected to TIM and Vodafone IT towers. ' +
        'Charges appear on the 2026-05 bill cycle as line items "DATA-INTL-RT" at $0.012/MB. ' +
        'Subscriber is requesting a credit and an explanation of why the inclusive roaming did ' +
        'not apply.'
);
casesToInsert.add(caseB);

// --- Scenario C: NovaMart Retail - loyalty points not crediting on online order ----------
Case caseC = new Case(
    AccountId      = novamart.Id,
    ContactId      = contactByAcct.get(novamart.Id).Id,
    RecordTypeId   = serviceCaseRtId,
    Subject        = '[KC-DEMO] NovaRewards points not credited for online order #NM-884201',
    Type           = 'Problem',
    Origin         = 'Web',
    Priority       = 'Low',
    Status         = 'New',
    Description    =
        'NovaRewards member (member #NR-77204, Gold tier) placed online order NM-884201 on ' +
        '2026-05-12 for $214.36. Order shipped and delivered 2026-05-15. The expected 428 ' +
        'NovaRewards points (2 points per dollar at Gold tier) never posted to the account. ' +
        'Member checked the rewards page in the NovaMart mobile app on iOS 18.4 and saw the ' +
        'order listed but with "Points: pending" still showing 6 days post-delivery. Member is ' +
        'planning a redemption and needs the points credited.'
);
casesToInsert.add(caseC);

insert casesToInsert;
System.debug('Inserted cases: ' + casesToInsert);

Id caseAId = caseA.Id;
Id caseBId = caseB.Id;
Id caseCId = caseC.Id;

// ---- 4. Case Comments (diagnosis & resolution dialogue) ----------------------------------
List<CaseComment> comments = new List<CaseComment>();

// Scenario A comments
comments.add(new CaseComment(ParentId=caseAId, IsPublished=true, CommentBody=
    'Initial triage: Pulled diagnostic logs from FB-X4-2241 via FleetOps Console. ' +
    'Confirmed marker detection rate dropped from 18 Hz to under 2 Hz starting at 14:31 UTC, ' +
    '~28 minutes after the 4.2.1 OTA completion timestamp. CPU and camera exposure metrics are ' +
    'normal. Marker library version reports 4.2.1, but checksum on /opt/forge/markers/aruco.bin ' +
    'does not match the 4.2.1 release manifest.'));

comments.add(new CaseComment(ParentId=caseAId, IsPublished=true, CommentBody=
    'Reproduced in lab on a spare ForgeBot-X4 by applying firmware 4.2.1 to a unit running ' +
    '4.1.7. Marker drop occurs in 100% of attempts when the unit was previously on 4.1.7. ' +
    'Units flashed clean to 4.2.1 do not exhibit the issue. Root cause identified: the 4.2.1 ' +
    'OTA delta-package skips re-deployment of the ArUco marker dictionary, leaving stale 4.1.7 ' +
    'binary on disk. The new 4.2.1 perception module expects the updated dictionary format and ' +
    'silently degrades to wheel odometry when checksum validation fails.'));

comments.add(new CaseComment(ParentId=caseAId, IsPublished=true, CommentBody=
    'Workaround for customer (immediate, before 6am pick shift): On each affected robot, SSH ' +
    'in as forge-admin and run `forge-fleet repair-markers --force-redeploy`. This pulls the ' +
    'correct 4.2.1 dictionary from the FleetOps Console package store and validates checksum. ' +
    'Takes ~90 seconds per robot, no reboot required. Confirmed working on FB-X4-2241 at ' +
    '04:12 UTC; marker detection back to 18 Hz, drift eliminated.'));

comments.add(new CaseComment(ParentId=caseAId, IsPublished=true, CommentBody=
    'Permanent resolution: Engineering will publish firmware 4.2.2 next Tuesday with corrected ' +
    'OTA delta-package logic that always re-deploys the marker dictionary. Customer should plan ' +
    'a rolling 4.2.2 update during their next maintenance window. Case closed - workaround in ' +
    'place, all 2 affected robots back online and operating at spec.'));

// Scenario B comments
comments.add(new CaseComment(ParentId=caseBId, IsPublished=true, CommentBody=
    'Pulled subscriber CDRs (Call Detail Records) for the 9-day window. Confirmed 4.7 GB of ' +
    'data usage across TIM and Vodafone IT during the trip. Plan entitlement check shows the ' +
    'subscriber IS on Unlimited Global - that part is correct.'));

comments.add(new CaseComment(ParentId=caseBId, IsPublished=true, CommentBody=
    'Root cause located. Subscriber added the line on 2026-04-28, which was 6 days before ' +
    'departure. The Unlimited Global rider has a 14-day "seasoning" period before international ' +
    'inclusive data activates - a fraud-prevention safeguard. During the seasoning window, ' +
    'roaming data is billed pay-per-use at $0.012/MB. This is documented in the rider terms but ' +
    'is not surfaced in the activation flow. The $487 charge is technically correct per the ' +
    'rider, but the disclosure is poor.'));

comments.add(new CaseComment(ParentId=caseBId, IsPublished=true, CommentBody=
    'Resolution applied: Issued one-time goodwill credit of $487 (full charge waived) under ' +
    'reason code GW-DISCLOSURE. Added a 30-day "international ready" flag to the line so any ' +
    'further roaming this billing cycle is covered. Filed product feedback ticket PRD-44211 ' +
    'requesting that the seasoning period be disclosed in the activation flow. Subscriber ' +
    'notified via outbound call - confirmed satisfaction.'));

comments.add(new CaseComment(ParentId=caseBId, IsPublished=true, CommentBody=
    'Follow-up note for the knowledge base: agents handling similar cases should verify (a) the ' +
    'subscriber is on Unlimited Global, (b) the line tenure is under 14 days at trip start, and ' +
    '(c) charges are coded DATA-INTL-RT. If all three conditions match, this is the seasoning ' +
    'edge case and a goodwill credit is appropriate. Manager pre-approval required only above ' +
    '$500.'));

// Scenario C comments
comments.add(new CaseComment(ParentId=caseCId, IsPublished=true, CommentBody=
    'Verified order NM-884201 in OMS: status Delivered, total $214.36, member NR-77204 attached ' +
    'to the order at checkout. Order qualifies for points - no exclusion codes set.'));

comments.add(new CaseComment(ParentId=caseCId, IsPublished=true, CommentBody=
    'Checked the loyalty points-accrual job logs. The nightly batch ran successfully on 2026-05-15 ' +
    'and 2026-05-16, but order NM-884201 was skipped both nights. Found the cause: the order was ' +
    'placed using a guest-checkout flow that captured the loyalty number in a free-text comments ' +
    'field instead of the structured loyalty_member_id field. The accrual job only reads the ' +
    'structured field, so the order looked anonymous to the points engine.'));

comments.add(new CaseComment(ParentId=caseCId, IsPublished=true, CommentBody=
    'Resolution: Manually credited 428 NovaRewards points to member NR-77204 with audit reason ' +
    '"missed-accrual / guest-checkout edge case / case ref [KC-DEMO]". Points posted instantly; ' +
    'member confirmed visible in the app within 2 minutes. Also re-attached order NM-884201 to ' +
    'the structured loyalty_member_id field to keep historical reporting clean.'));

comments.add(new CaseComment(ParentId=caseCId, IsPublished=true, CommentBody=
    'For the knowledge base: this is a recurring edge case for any order placed via the legacy ' +
    'guest-checkout path between 2026-04 and 2026-05. Engineering rolled out fix MOB-9912 on ' +
    '2026-05-19 that auto-promotes loyalty numbers from the comments field to the structured ' +
    'field. Orders placed before that date may need manual point credits. Process: verify order ' +
    'in OMS, confirm member tier, calculate points (2 per $ Gold, 1 per $ Silver), credit via ' +
    'Loyalty Console > Manual Adjustment > "Missed Accrual."'));

insert comments;
System.debug('Inserted ' + comments.size() + ' case comments');

// ---- 5. Email Messages -------------------------------------------------------------------
List<EmailMessage> emails = new List<EmailMessage>();
DateTime baseTs = DateTime.now().addDays(-7);

// Scenario A emails (customer ↔ agent)
emails.add(new EmailMessage(
    ParentId=caseAId, Status='0', Incoming=true,
    FromAddress='priya.ramaswamy@circuitforge.example', FromName='Priya Ramaswamy',
    ToAddress='support@circuitforge-support.example',
    Subject='URGENT: 2 warehouse robots offline after firmware update - need help before 6am shift',
    TextBody='Hi support team,\n\nWe just rolled firmware 4.2.1 to our Memphis warehouse fleet ' +
        'and 2 of our ForgeBot-X4 units (FB-X4-2241 and FB-X4-2247) are now drifting and halting ' +
        'with NAV_MARKER_LOST errors. Pick shift starts at 6am Eastern - we need these back online ' +
        'or we are going to be in trouble. Diagnostic logs attached.\n\nThanks,\nPriya',
    MessageDate=baseTs));

emails.add(new EmailMessage(
    ParentId=caseAId, Status='3', Incoming=false,
    FromAddress='cf-support@example.com', FromName='CircuitForge Support',
    ToAddress='priya.ramaswamy@circuitforge.example',
    Subject='RE: URGENT: 2 warehouse robots offline after firmware update',
    TextBody='Hi Priya,\n\nI have triaged the logs and reproduced the issue in our lab. The 4.2.1 ' +
        'OTA delta has a bug that leaves the previous marker dictionary on disk, which the new ' +
        'perception module rejects. Workaround: SSH to each affected robot and run\n\n' +
        '    forge-fleet repair-markers --force-redeploy\n\n' +
        'It takes about 90 seconds per robot and does not require a reboot. I am standing by if ' +
        'you want to screen-share while you run it.\n\nA permanent fix (firmware 4.2.2) ships next ' +
        'Tuesday.\n\nBest,\nAlex Chen, CircuitForge Support',
    MessageDate=baseTs.addHours(1)));

emails.add(new EmailMessage(
    ParentId=caseAId, Status='0', Incoming=true,
    FromAddress='priya.ramaswamy@circuitforge.example', FromName='Priya Ramaswamy',
    ToAddress='cf-support@example.com',
    Subject='RE: URGENT: 2 warehouse robots offline after firmware update',
    TextBody='Alex - that worked. Both robots are back at 18 Hz marker detection and drift is ' +
        'gone. We will plan the 4.2.2 rollout for next maintenance window. Thank you for the fast ' +
        'response - pick shift will start on time.\n\nPlease close the case.\n\nPriya',
    MessageDate=baseTs.addHours(2)));

// Scenario B emails
emails.add(new EmailMessage(
    ParentId=caseBId, Status='0', Incoming=true,
    FromAddress='marcus.bell@metrowave.example', FromName='Marcus Bell',
    ToAddress='care@metrowave.example',
    Subject='Why am I being charged for roaming - I am on Unlimited Global?',
    TextBody='Hello,\n\nI just got home from a trip to Italy and my bill shows $487 in roaming ' +
        'data charges. I am on the Unlimited Global plan which I thought included unlimited data ' +
        'in Italy. My phone (iPhone 15 Pro) was set to LTE/5G Auto the whole time and I was ' +
        'connected to TIM and Vodafone IT.\n\nCan you explain why I am being charged and credit ' +
        'these back?\n\nThanks,\nMarcus Bell',
    MessageDate=baseTs.addDays(1)));

emails.add(new EmailMessage(
    ParentId=caseBId, Status='3', Incoming=false,
    FromAddress='care@metrowave.example', FromName='MetroWave Customer Care',
    ToAddress='marcus.bell@metrowave.example',
    Subject='RE: Why am I being charged for roaming',
    TextBody='Hi Marcus,\n\nThank you for reaching out. I have looked into your account and I see ' +
        'what happened. The Unlimited Global rider has a 14-day "seasoning" period before its ' +
        'inclusive international data kicks in - a fraud-prevention measure. Your line was added ' +
        'on April 28 and your trip began May 4, so you were 6 days into the seasoning window when ' +
        'roaming started.\n\nThis is a poor disclosure on our end. I have credited the full ' +
        '$487 back to your account (credit will appear within 2 billing cycles) and added an ' +
        '"international ready" flag to your line for the next 30 days so any further roaming is ' +
        'covered. I have also filed feedback to product so we surface this in the activation ' +
        'flow.\n\nApologies for the surprise.\n\nBest,\nJordan Patel, MetroWave Care',
    MessageDate=baseTs.addDays(1).addHours(3)));

emails.add(new EmailMessage(
    ParentId=caseBId, Status='0', Incoming=true,
    FromAddress='marcus.bell@metrowave.example', FromName='Marcus Bell',
    ToAddress='care@metrowave.example',
    Subject='RE: Why am I being charged for roaming',
    TextBody='Jordan - thanks for the explanation and the credit. Appreciate the quick turnaround.\n\nMarcus',
    MessageDate=baseTs.addDays(1).addHours(4)));

// Scenario C emails
emails.add(new EmailMessage(
    ParentId=caseCId, Status='0', Incoming=true,
    FromAddress='avery.tan@novamart.example', FromName='Avery Tan',
    ToAddress='rewards@novamart.example',
    Subject='Missing NovaRewards points for order NM-884201',
    TextBody='Hi,\n\nI placed order NM-884201 on May 12 for $214.36 and it was delivered on the ' +
        '15th, but the 428 points I should have earned (Gold tier, 2 pts/$) have not posted. The ' +
        'order shows up in the rewards section of the app but it says "Points: pending" still. ' +
        'It has been 6 days. Can you credit them? I am trying to redeem.\n\nMember #NR-77204\n\nThanks,\nAvery',
    MessageDate=baseTs.addDays(2)));

emails.add(new EmailMessage(
    ParentId=caseCId, Status='3', Incoming=false,
    FromAddress='rewards@novamart.example', FromName='NovaMart Rewards Team',
    ToAddress='avery.tan@novamart.example',
    Subject='RE: Missing NovaRewards points for order NM-884201',
    TextBody='Hi Avery,\n\nI found the issue. Your order was placed through the guest-checkout ' +
        'flow which captured your loyalty number in a free-text comments field instead of the ' +
        'structured loyalty field our points engine reads. So the engine treated the order as ' +
        'anonymous and skipped accrual.\n\nI have manually credited 428 points to your account ' +
        'and you should see them in the app right now. I have also re-attached the order properly ' +
        'so your reporting stays clean. Engineering rolled out a fix on May 19 that auto-promotes ' +
        'loyalty numbers from comments going forward.\n\nApologies for the friction. Enjoy the ' +
        'redemption!\n\nSam Rivera, NovaRewards Team',
    MessageDate=baseTs.addDays(2).addHours(2)));

emails.add(new EmailMessage(
    ParentId=caseCId, Status='0', Incoming=true,
    FromAddress='avery.tan@novamart.example', FromName='Avery Tan',
    ToAddress='rewards@novamart.example',
    Subject='RE: Missing NovaRewards points for order NM-884201',
    TextBody='Sam - points just showed up in the app, all good. Thanks for the fast fix.\n\nAvery',
    MessageDate=baseTs.addDays(2).addHours(3)));

insert emails;
System.debug('Inserted ' + emails.size() + ' email messages');

// ---- 6. Move cases to "Working" (skipping Closed because a closed-case Flow in this org
//         requires messagingEndUserIds and would block the seed). The Draft Knowledge Article
//         button works on any Case status, so this is purely cosmetic. ----
List<Case> toUpdate = [SELECT Id, Status FROM Case WHERE Id IN :casesToInsert];
for (Case c : toUpdate) {
    c.Status = 'Working';
}
update toUpdate;

// ---- 7. Output summary -------------------------------------------------------------------
List<Case> finalCases = [SELECT Id, CaseNumber, Subject, Status, Account.Name,
                                (SELECT Id FROM CaseComments),
                                (SELECT Id FROM EmailMessages)
                         FROM Case WHERE Id IN :casesToInsert ORDER BY CaseNumber];
System.debug('=== SEED RESULT ===');
for (Case c : finalCases) {
    System.debug(String.format('  Case {0} [{1}]  Account={2}  comments={3}  emails={4}  Subject={5}',
        new String[]{ c.CaseNumber, c.Status, c.Account.Name,
                      String.valueOf(c.CaseComments.size()),
                      String.valueOf(c.EmailMessages.size()),
                      c.Subject }));
}
