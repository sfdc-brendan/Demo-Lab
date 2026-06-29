@isTest
private class CaseTranscriptProviderTest {
    @isTest
    static void assembleBuildsLabeledTranscript() {
        Case c = new Case(Subject = 'Login issue', Description = 'I cannot log in to my account.');

        List<EmailMessage> emails = new List<EmailMessage>{
            new EmailMessage(Incoming = true, TextBody = 'It still does not work.'),
            new EmailMessage(Incoming = false, TextBody = 'Please try resetting your password.'),
            new EmailMessage(Incoming = false, TextBody = '   ') // blank body is skipped
        };
        List<CaseComment> comments = new List<CaseComment>{
            new CaseComment(CommentBody = 'Verified identity and reset password.')
        };

        String transcript = CaseTranscriptProvider.assemble(c, emails, comments);

        System.Assert.isTrue(transcript.contains('Subject: Login issue'), 'Includes subject');
        System.Assert.isTrue(transcript.contains('End User: I cannot log in'), 'Includes description as End User');
        System.Assert.isTrue(transcript.contains('End User: It still does not work.'), 'Inbound email is End User');
        System.Assert.isTrue(transcript.contains('Agent: Please try resetting'), 'Outbound email is Agent');
        System.Assert.isTrue(transcript.contains('Agent: Verified identity'), 'Comment is Agent');
        System.Assert.isFalse(transcript.contains('Agent:    '), 'Blank email body skipped');
    }

    @isTest
    static void assembleHandlesNulls() {
        System.Assert.areEqual('', CaseTranscriptProvider.assemble(null, null, null));
    }

    @isTest
    static void buildReturnsResultPerRequest() {
        // Fabricated case id matches no records; exercises the SOQL/grouping paths without
        // requiring a Case insert (blocked by org create automation in test context).
        CaseTranscriptProvider.Request req = new CaseTranscriptProvider.Request();
        req.caseId = Id.valueOf(Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000');

        Test.startTest();
        List<CaseTranscriptProvider.Result> results = CaseTranscriptProvider.build(
            new List<CaseTranscriptProvider.Request>{ req }
        );
        Test.stopTest();

        System.Assert.areEqual(1, results.size());
        System.Assert.areEqual('', results[0].transcript, 'No data for fabricated id -> empty transcript');
    }
}
