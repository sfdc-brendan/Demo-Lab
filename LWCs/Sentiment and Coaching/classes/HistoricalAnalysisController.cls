/**
 * @description Supports historical analysis of Voice Calls and Messaging Sessions.
 *              Finds records (up to 2 weeks old) that have no analysis and sets
 *              Request_Historical_Analysis__c so record-triggered flows can process them.
 * @author SentimentCoaching
 */
public with sharing class HistoricalAnalysisController {
    private static final Integer MAX_DAYS_BACK = 14;

    public class CandidateRecord {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String objectType;

        public CandidateRecord(String id, String name, DateTime createdDate, String objectType) {
            this.id = id;
            this.name = name;
            this.createdDate = createdDate;
            this.objectType = objectType;
        }
    }

    public class GetCandidatesResult {
        @AuraEnabled public List<CandidateRecord> records;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public String message;

        public GetCandidatesResult(List<CandidateRecord> records, Integer totalCount, String message) {
            this.records = records;
            this.totalCount = totalCount;
            this.message = message;
        }
    }

    /**
     * Find Voice Calls and/or Messaging Sessions from the last N days (max 14) that have no analysis yet.
     * @param objectType 'VoiceCall', 'MessagingSession', or 'Both'
     * @param daysBack   Number of days to look back (capped at 14).
     */
    @AuraEnabled(cacheable=false)
    public static GetCandidatesResult getCandidates(String objectType, Integer daysBack) {
        if (daysBack == null || daysBack < 1) {
            daysBack = MAX_DAYS_BACK;
        }
        daysBack = Math.min(daysBack, MAX_DAYS_BACK);

        List<CandidateRecord> all = new List<CandidateRecord>();
        String msg = '';

        if (objectType == 'VoiceCall' || objectType == 'Both') {
            List<CandidateRecord> vc = getVoiceCallCandidates(daysBack);
            all.addAll(vc);
            if (objectType == 'Both' && vc.size() > 0) {
                msg += vc.size() + ' Voice Call(s). ';
            }
        }
        if (objectType == 'MessagingSession' || objectType == 'Both') {
            List<CandidateRecord> ms = getMessagingSessionCandidates(daysBack);
            all.addAll(ms);
            if (objectType == 'Both' && ms.size() > 0) {
                msg += ms.size() + ' Messaging Session(s). ';
            }
        }

        if (all.isEmpty()) {
            msg = 'No records found in the last ' + daysBack + ' days that need analysis.';
        } else {
            msg = 'Found ' + all.size() + ' record(s) to analyze (last ' + daysBack + ' days). ' + msg;
        }

        return new GetCandidatesResult(all, all.size(), msg);
    }

    private static List<CandidateRecord> getVoiceCallCandidates(Integer daysBack) {
        Date cutoff = Date.today().addDays(-daysBack);
        List<VoiceCall> listVC = [
            SELECT Id, CreatedDate, Call_Sentiment__c, Agent_Performance_Evaluation__c
            FROM VoiceCall
            WHERE CallDisposition = 'completed'
              AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 500
        ];
        List<CandidateRecord> results = new List<CandidateRecord>();
        for (VoiceCall vc : listVC) {
            if (String.isBlank(vc.Call_Sentiment__c) || String.isBlank(vc.Agent_Performance_Evaluation__c)) {
                results.add(new CandidateRecord(vc.Id, vc.Id, vc.CreatedDate, 'VoiceCall'));
            }
        }
        return results;
    }

    private static List<CandidateRecord> getMessagingSessionCandidates(Integer daysBack) {
        Date cutoff = Date.today().addDays(-daysBack);
        List<MessagingSession> listMS = [
            SELECT Id, CreatedDate, ChatSentiment__c, AgentPerformanceEvaluation__c
            FROM MessagingSession
            WHERE Status = 'Ended'
              AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 500
        ];
        List<CandidateRecord> results = new List<CandidateRecord>();
        for (MessagingSession ms : listMS) {
            if (String.isBlank(ms.ChatSentiment__c) || String.isBlank(ms.AgentPerformanceEvaluation__c)) {
                results.add(new CandidateRecord(ms.Id, ms.Id, ms.CreatedDate, 'MessagingSession'));
            }
        }
        return results;
    }

    /**
     * Set Request_Historical_Analysis__c = true on the given records so record-triggered flows run.
     * Batches of 200 to stay within DML limits. Flows run asynchronously after the update.
     */
    @AuraEnabled
    public static String runHistoricalAnalysis(List<String> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return 'No records selected.';
        }

        Set<String> ids = new Set<String>(recordIds);
        List<SObject> toUpdate = new List<SObject>();

        List<VoiceCall> voiceCalls = [
            SELECT Id FROM VoiceCall
            WHERE Id IN :ids
        ];
        for (VoiceCall vc : voiceCalls) {
            vc.Request_Historical_Analysis__c = true;
            toUpdate.add(vc);
        }

        Set<String> vcIdStrs = new Set<String>();
        for (VoiceCall vc : voiceCalls) {
            vcIdStrs.add(vc.Id);
        }
        Set<String> msIds = new Set<String>(ids);
        msIds.removeAll(vcIdStrs);

        if (!msIds.isEmpty()) {
            List<MessagingSession> sessions = [
                SELECT Id FROM MessagingSession
                WHERE Id IN :msIds
            ];
            for (MessagingSession ms : sessions) {
                ms.Request_Historical_Analysis__c = true;
                toUpdate.add(ms);
            }
        }

        if (toUpdate.isEmpty()) {
            return 'No valid Voice Call or Messaging Session IDs found.';
        }

        update toUpdate;
        return 'Queued ' + toUpdate.size() + ' record(s) for analysis. Results will appear after the background flows complete—use Refresh on the record page if needed.';
    }
}
