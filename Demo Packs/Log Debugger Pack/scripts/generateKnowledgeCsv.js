#!/usr/bin/env node
/**
 * Builds the Bulk API import file for the troubleshooting library.
 *
 * Anonymous Apex caps at 32KB, and the article set is well past that, so the
 * articles are loaded as data rather than as a generated script. Publishing
 * still needs Apex, which scripts/apex/publishKnowledge.apex handles.
 *
 * Usage: node scripts/generateKnowledgeCsv.js [knowledgeRecordTypeId]
 *
 * The record type is optional. Orgs with no active Knowledge record type import
 * against the master one, in which case the column is left out entirely rather
 * than sent empty, which the Bulk API rejects.
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SOURCE = path.join(ROOT, "data", "knowledge-articles.json");
const TARGET = path.join(ROOT, "data", "knowledge-articles.csv");

const recordTypeId = process.argv[2] || "";

const COLUMNS = [
  ...(recordTypeId ? ["RecordTypeId"] : []),
  "Language",
  "External_ID__c",
  "Title",
  "UrlName",
  "Summary",
  "KCSArticle_Issue__c",
  "KCSArticle_Cause__c",
  "KCSArticle_Environment__c",
  "KCSArticle_Resolution__c"
];

function csvCell(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

const articles = JSON.parse(fs.readFileSync(SOURCE, "utf8"));

const lines = [COLUMNS.join(",")];
for (const article of articles) {
  lines.push(
    [
      ...(recordTypeId ? [recordTypeId] : []),
      "en_US",
      article.externalId,
      article.title,
      article.urlName,
      article.summary,
      article.issue,
      article.cause,
      article.environment,
      article.resolution
    ]
      .map(csvCell)
      .join(",")
  );
}

fs.writeFileSync(TARGET, lines.join("\n") + "\n");
console.log(
  `Wrote ${path.relative(ROOT, TARGET)} (${articles.length} articles)`
);
