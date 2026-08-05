// Removes the troubleshooting library from Knowledge so the loader can
// be run against a clean slate. Only touches articles tagged KB-###; the demo
// org's existing article set is left alone.
//
// Online articles must be archived before they can be deleted, and Salesforce does
// not allow archiving and deleting in the same transaction. Run this script twice:
// the first pass archives, the second pass deletes.
//
// Deletion goes through KbManagement.PublishingService rather than a DML delete:
// Apex rejects `delete` against KnowledgeArticle outright, at compile time.

List<Knowledge__kav> articles = [
  SELECT Id, KnowledgeArticleId, PublishStatus, External_ID__c
  FROM Knowledge__kav
  WHERE External_ID__c LIKE 'KB-%'
];

Integer archived = 0;
Integer deleted = 0;

for (Knowledge__kav article : articles) {
  if (article.PublishStatus == 'Online') {
    KbManagement.PublishingService.archiveOnlineArticle(
      article.KnowledgeArticleId,
      null
    );
    archived++;
  } else if (article.PublishStatus == 'Archived') {
    KbManagement.PublishingService.deleteArchivedArticle(
      article.KnowledgeArticleId
    );
    deleted++;
  } else {
    KbManagement.PublishingService.deleteDraftArticle(
      article.KnowledgeArticleId
    );
    deleted++;
  }
}

System.debug('CLEANUP>>> archived ' + archived + ', deleted ' + deleted);
if (archived > 0) {
  System.debug(
    'CLEANUP>>> run this script again to delete the archived articles'
  );
}
