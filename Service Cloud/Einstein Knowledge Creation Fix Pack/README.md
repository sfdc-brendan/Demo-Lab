# Demo Org Fix Pack: Einstein Knowledge Creation

This pack applies the setup fixes needed to make Einstein Knowledge Creation reliably draft articles in demo orgs, then optionally seeds realistic support cases.

## What This Pack Fixes

- Adds long-text field `Knowledge__kav.Chat_Answer_Detailed__c` (32,768 chars).
- Grants FLS via permission set `Knowledge_AI_Drafting_FLS`.
- Updates Knowledge layouts so mapped fields are present on all common article layouts:
  - `Knowledge__kav-Knowledge Layout`
  - `Knowledge__kav-SDO - KCS Layout`
  - `Knowledge__kav-SDO - Knowledge Author`
- Updates `Case-Case Layout` to include `GenerateKnowledge` in the action list.

## Prereqs

- Salesforce CLI (`sf`) installed.
- Authenticated target org alias/username.
- Run from this folder (`demo-org-fix-pack`).

## 1) Deploy Metadata Fixes

```bash
sf project deploy start --target-org <ORG_ALIAS>
```

## 2) Assign Post-Deploy Permission Set to Running User

```bash
sf apex run --target-org <ORG_ALIAS> --file scripts/post_deploy_assign_permset.apex
```

## 3) One Manual Setup Step (Required)

In **Setup -> Einstein Knowledge Creation -> Map Responses to Knowledge Fields**:

- Ensure the `Answer` response maps to **Chat Answer (Detailed)** (`Chat_Answer_Detailed__c`)

Suggested mapping set:

- `Question -> FAQ_Question__c`
- `Resolution -> KCSArticle_Resolution__c`
- `Answer -> Chat_Answer_Detailed__c`
- `Summary -> Summary`
- `Issue -> KCSArticle_Issue__c`

## 4) Optional: Seed Demo Cases

General support demos:

```bash
sf apex run --target-org <ORG_ALIAS> --file scripts/seed_knowledge_cases.apex
```

Pearson-focused demos:

```bash
sf apex run --target-org <ORG_ALIAS> --file scripts/seed_pearson_cases.apex
```

## Notes

- Seed scripts are idempotent by subject prefix:
  - `[KC-DEMO]`
  - `[KC-DEMO-PEARSON]`
- Scripts set cases to `Working` (not `Closed`) to avoid org-specific closed-case flow blockers.
- If drafting still fails after deploy, refresh your browser tab and re-test with article type **KCSArticle**.
