// Publishes every troubleshooting article that is sitting in Draft.
// The articles themselves are loaded as data by scripts/loadKnowledge.sh;
// only the transition to Online requires Apex.
//
// Safe to run repeatedly. Already-published articles are not in the query.

Integer published = 0;
List<String> failures = new List<String>();

for (Knowledge__kav draft : [
  SELECT KnowledgeArticleId, External_ID__c
  FROM Knowledge__kav
  WHERE External_ID__c LIKE 'KB-%' AND PublishStatus = 'Draft'
]) {
  try {
    KbManagement.PublishingService.publishArticle(
      draft.KnowledgeArticleId,
      true
    );
    published++;
  } catch (Exception e) {
    failures.add(draft.External_ID__c + ': ' + e.getMessage());
  }
}

System.debug('PUBLISH>>> published ' + published + ' article(s)');
for (String failure : failures) {
  System.debug('PUBLISH>>> FAILED ' + failure);
}
