/**
 * @description Coaching Intelligence v2 - Case channel transcript assembler. A Case has no platform
 *              transcript provider (unlike Voice/Chat), so this invocable builds an "Agent:/End User:"
 *              formatted transcript from the Case subject/description, its email thread, and case
 *              comments. The result is passed to the Coaching_Case_v2 prompt template.
 */
public with sharing class CaseTranscriptProvider {
    public class Request {
        @InvocableVariable(label='Case Id' required=true)
        public Id caseId;
    }

    public class Result {
        @InvocableVariable(label='Transcript')
        public String transcript;
    }

    @InvocableMethod(label='Build Case Transcript' description='Assembles an Agent/End User transcript for a Case from its description, emails, and comments.')
    public static List<Result> build(List<Request> requests) {
        Set<Id> caseIds = new Set<Id>();
        for (Request req : requests) {
            if (req.caseId != null) {
                caseIds.add(req.caseId);
            }
        }

        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, Subject, Description FROM Case WHERE Id IN :caseIds]
        );

        Map<Id, List<EmailMessage>> emailsByCase = new Map<Id, List<EmailMessage>>();
        for (EmailMessage em : [
            SELECT ParentId, Incoming, TextBody, MessageDate
            FROM EmailMessage
            WHERE ParentId IN :caseIds
            ORDER BY MessageDate ASC NULLS FIRST
        ]) {
            if (!emailsByCase.containsKey(em.ParentId)) {
                emailsByCase.put(em.ParentId, new List<EmailMessage>());
            }
            emailsByCase.get(em.ParentId).add(em);
        }

        Map<Id, List<CaseComment>> commentsByCase = new Map<Id, List<CaseComment>>();
        for (CaseComment cc : [
            SELECT ParentId, CommentBody, CreatedDate
            FROM CaseComment
            WHERE ParentId IN :caseIds
            ORDER BY CreatedDate ASC
        ]) {
            if (!commentsByCase.containsKey(cc.ParentId)) {
                commentsByCase.put(cc.ParentId, new List<CaseComment>());
            }
            commentsByCase.get(cc.ParentId).add(cc);
        }

        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.transcript = assemble(
                caseMap.get(req.caseId),
                emailsByCase.get(req.caseId),
                commentsByCase.get(req.caseId)
            );
            results.add(res);
        }
        return results;
    }

    @TestVisible
    private static String assemble(Case theCase, List<EmailMessage> emails, List<CaseComment> comments) {
        List<String> lines = new List<String>();
        if (theCase != null) {
            if (String.isNotBlank(theCase.Subject)) {
                lines.add('Subject: ' + theCase.Subject);
            }
            if (String.isNotBlank(theCase.Description)) {
                lines.add('End User: ' + theCase.Description.trim());
            }
        }
        if (emails != null) {
            for (EmailMessage em : emails) {
                if (String.isBlank(em.TextBody)) {
                    continue;
                }
                String speaker = (em.Incoming == true) ? 'End User' : 'Agent';
                lines.add(speaker + ': ' + em.TextBody.trim());
            }
        }
        if (comments != null) {
            for (CaseComment cc : comments) {
                if (String.isNotBlank(cc.CommentBody)) {
                    lines.add('Agent: ' + cc.CommentBody.trim());
                }
            }
        }
        return String.join(lines, '\n');
    }
}
