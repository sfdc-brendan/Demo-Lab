/**
 * Queueable that runs incident evaluation (GenAI + fallback) in a context that allows callouts.
 * The flow invokes CaseIncidentHandler.evaluateCaseForIncident(), which enqueues this job.
 * Running in Queueable avoids "Failed to generate Einstein LLM generations response" (INTERNAL_ERROR)
 * and allows callouts required by the Models API (createGenerations).
 */
public with sharing class CaseIncidentQueueable implements Queueable, Database.AllowsCallouts {

    private final Id caseId;

    public CaseIncidentQueueable(Id caseId) {
        this.caseId = caseId;
    }

    public void execute(QueueableContext context) {
        CaseIncidentHandler.evaluateCaseForIncidentInternal(this.caseId);
    }
}
