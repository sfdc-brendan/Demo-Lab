# Release Manager Deliverables Guide

Detailed templates for the seven core Release Manager deliverable types. Each template is designed for reuse across projects, release cadences, and team sizes.

---

## Release Plan Template

```markdown
# Release Plan: [Release Name / Version]
**Release Date:** [Target date]
**Release Manager:** [Name]
**Status:** [Planning / Approved / In Progress / Deployed / Rolled Back]
**Last Updated:** [Date]

## 1. Release Scope
### Sprint-to-Release Mapping
| Sprint | Dates | Work Items Included |
|---|---|---|
| Sprint [N] | [Start – End] | [US-001, US-002, BUG-015] |
| Sprint [N+1] | [Start – End] | [US-003, US-004] |

### Components in This Release
| Component | Type | Owner | Status | Risk |
|---|---|---|---|---|
| [Component name] | [Metadata / Apex / LWC / Flow / Data] | [Developer] | [Dev Complete / In QA / Ready] | [High / Medium / Low] |

### Out of Scope (Deferred to Next Release)
- [Item 1 — reason for deferral]
- [Item 2 — reason for deferral]

## 2. Deployment Sequence
| Order | Package / Component | Target Org | Method | Dependencies |
|---|---|---|---|---|
| 1 | [Custom objects & fields] | Production | sf project deploy | None |
| 2 | [Apex classes & triggers] | Production | sf project deploy | Step 1 |
| 3 | [Flows] | Production | sf project deploy | Steps 1, 2 |
| 4 | [LWC components] | Production | sf project deploy | Steps 1, 2 |
| 5 | [Permission sets] | Production | sf project deploy | Steps 1–4 |
| 6 | [Data migration / updates] | Production | sf data import | Steps 1–5 |

## 3. Dependencies
| Dependency | Owner | Status | Impact if Not Ready |
|---|---|---|---|
| [External API endpoint live] | [Integration team] | [Confirmed / Pending] | [Feature X non-functional] |
| [Data migration script tested] | [Data team] | [Confirmed / Pending] | [Deployment blocked] |

## 4. Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [Metadata conflict in production] | Medium | High | Run validation deploy 24 hours before release |
| [Integration endpoint downtime] | Low | High | Feature flag to disable integration |
| [Test coverage regression] | Low | Medium | Enforce 85% gate in pipeline |

## 5. Go / No-Go Criteria
All must be TRUE to proceed:
- [ ] All components pass validation deploy against production
- [ ] Apex test coverage ≥ [X]% (org-wide) with 0 failures
- [ ] UAT sign-off received from [stakeholder]
- [ ] Rollback procedure reviewed and approved
- [ ] Release notes drafted and reviewed
- [ ] All dependencies confirmed ready
- [ ] Change management communications sent
- [ ] Deployment window confirmed with stakeholders

## 6. Communication Plan
| When | What | Audience | Channel |
|---|---|---|---|
| [T-5 days] | Release preview — what's coming | All stakeholders | Email / Slack |
| [T-1 day] | Go/no-go decision | Release board | Meeting |
| [T-0 start] | Deployment starting | IT / Admin team | Slack |
| [T-0 end] | Deployment complete + validation | All stakeholders | Email / Slack |
| [T+1 day] | Release notes published | All users | Intranet / Email |

## 7. Rollback Plan Summary
- **Rollback window:** [X hours after deployment]
- **Rollback trigger:** [Criteria — see full Rollback Procedure]
- **Rollback method:** [Redeploy previous version / destructive changes / data restore]
- **Rollback owner:** [Release Manager + Dev lead]
```

---

## Environment Strategy Template

```markdown
# Environment Strategy: [Project / Org Name]
**Author:** [Release Manager]
**Version:** [X.X]
**Last Updated:** [Date]

## 1. Sandbox Inventory
| Sandbox Name | Type | Purpose | Owner | Last Refresh | Refresh Cadence |
|---|---|---|---|---|---|
| [DEV-01] | Developer | Individual dev work | [Dev name] | [Date] | On demand |
| [DEV-02] | Developer | Individual dev work | [Dev name] | [Date] | On demand |
| [INT] | Developer Pro | Integration testing | [Team lead] | [Date] | Per sprint |
| [QA] | Partial Copy | QA / regression testing | [QA lead] | [Date] | Per release |
| [STAGING] | Full Copy | Pre-production validation | [Release Manager] | [Date] | Per release |
| [UAT] | Partial Copy | Business acceptance testing | [BA] | [Date] | Per release |

## 2. Promotion Path
```
Developer Sandbox → Integration Sandbox → QA Sandbox → UAT Sandbox → Staging (Full) → Production
       ↑                    ↑                 ↑             ↑              ↑
   Individual          Team merge       Automated      Business       Final
   dev work            + conflict        test suite     sign-off     validation
                       resolution
```

## 3. Sandbox Type Selection Guide
| Sandbox Type | Storage | Data | Refresh Limit | Best For |
|---|---|---|---|---|
| Developer | 200 MB | Metadata only | Per day | Individual dev, quick experiments |
| Developer Pro | 1 GB | Metadata only | Per day | Integration testing, API dev |
| Partial Copy | 5 GB | Metadata + sample data | 5/day | QA, UAT, training |
| Full Copy | Matches prod | Full production copy | 29-day interval | Staging, performance testing, data migration |

## 4. Refresh Cadence
| Sandbox | Refresh Trigger | Data Seeding | Post-Refresh Steps |
|---|---|---|---|
| Developer | On demand / sprint start | None — metadata only | Deploy feature branch |
| Integration | Sprint start | Test data factory script | Deploy integration branch |
| QA | Release cycle start | Partial copy + anonymization | Deploy release candidate |
| UAT | Before UAT cycle | Partial copy + test scenarios | Deploy release candidate |
| Staging | Before go/no-go | Full copy (production clone) | Deploy release candidate |

## 5. Data Seeding Approach
- **Developer sandboxes:** Apex test data factory classes generate required data
- **QA / UAT:** Partial copy template + post-refresh data anonymization script
- **Staging:** Full production copy with PII masking for regulated fields
- **Synthetic data:** Used when production data is too sensitive or insufficient for test scenarios

## 6. Environment-Specific Configurations
| Configuration | Dev | QA | UAT | Staging | Prod |
|---|---|---|---|---|---|
| External API endpoints | Mock / sandbox | Sandbox | Sandbox | Production (read-only) | Production |
| Email deliverability | System email only | System email only | Restricted | All email | All email |
| Named Credentials | Dev endpoint | QA endpoint | UAT endpoint | Prod endpoint | Prod endpoint |
| Feature flags | All enabled | Per release | Per release | Matches prod | Controlled |
| Debug logging | Verbose | Standard | Standard | Standard | Minimal |

## 7. Org Topology Diagram
[Delegate to sf-diagram-mermaid for visual representation]
```

---

## CI/CD Pipeline Design Template

```markdown
# CI/CD Pipeline Design: [Project / Team Name]
**Author:** [Release Manager]
**Version:** [X.X]
**Last Updated:** [Date]

## 1. Source Control Strategy
### Repository Structure
- **Repository:** [GitHub / GitLab / Bitbucket URL]
- **Default branch:** `main` (represents production state)
- **Branch naming:** `feature/[ticket-id]-short-description`, `bugfix/[ticket-id]-description`, `hotfix/[ticket-id]-description`

### Branching Strategy
[Select one: trunk-based, feature-branch, or release-branch. Document the chosen model.]

**Feature Branch Model:**
```
main (production)
  └── develop (integration)
        ├── feature/US-001-case-routing
        ├── feature/US-002-escalation-flow
        └── bugfix/BUG-015-assignment-rule
```

### Merge Rules
- Feature → develop: Requires PR review + validation deploy pass
- Develop → main: Requires QA sign-off + release approval
- Hotfix → main: Requires abbreviated review + expedited approval (then backmerge to develop)

## 2. Pipeline Stages
| Stage | Trigger | Environment | Actions | Quality Gate |
|---|---|---|---|---|
| **Validate** | PR opened / updated | Scratch org or Dev sandbox | `sf project deploy --dry-run`, lint, PMD | Must pass validation |
| **Build & Test** | PR approved | QA sandbox | Deploy + run specified tests | 85% coverage, 0 failures |
| **Integration Test** | Merge to develop | Integration sandbox | Full deploy + regression suite | All tests pass |
| **UAT Deploy** | Release candidate tagged | UAT sandbox | Deploy release package | BA sign-off |
| **Pre-Production** | Go/no-go approved | Staging (full copy) | Validation deploy to production | Validation success |
| **Production** | Manual approval | Production | Quick deploy (from validated) | Smoke tests pass |

## 3. Quality Gates
| Gate | Criteria | Enforcement |
|---|---|---|
| **Code Review** | ≥ 1 approved reviewer, no unresolved comments | GitHub branch protection |
| **Static Analysis** | 0 critical PMD violations, 0 high-severity issues | Pipeline blocks on failure |
| **Test Coverage** | ≥ 85% Apex coverage, 0 test failures | Pipeline blocks on failure |
| **Validation Deploy** | Successful deployment check against target org | Pipeline blocks on failure |
| **Security Review** | No hardcoded credentials, no SOQL injection patterns | Pipeline blocks on failure |
| **UAT Sign-off** | Business stakeholder approval recorded | Manual gate |
| **Release Approval** | Release Manager + Tech Lead sign-off | Manual gate |

## 4. Automated Test Requirements
| Stage | Test Level | `sf project deploy` Flag | Rationale |
|---|---|---|---|
| Validate (PR) | RunSpecifiedTests | `--test-level RunSpecifiedTests` | Fast feedback, relevant tests only |
| Build & Test | RunSpecifiedTests | `--test-level RunSpecifiedTests` | Broader coverage, specified in manifest |
| Integration | RunLocalTests | `--test-level RunLocalTests` | Full local test suite |
| Pre-Production | RunLocalTests | `--test-level RunLocalTests` | Production-equivalent validation |
| Production | RunSpecifiedTests | Quick deploy from validated | Fastest safe path |

## 5. Notification Strategy
| Event | Channel | Recipients |
|---|---|---|
| Pipeline started | Slack #deployments | Dev team |
| Validation failed | Slack #deployments + email | PR author, Release Manager |
| Tests failed | Slack #deployments + email | PR author, test authors |
| QA deploy complete | Slack #qa | QA team |
| Production deploy complete | Slack #releases + email | All stakeholders |
| Rollback initiated | Slack #incidents + email | All stakeholders, leadership |

## 6. Pipeline Configuration
[Include pipeline YAML skeleton for the team's CI/CD platform — GitHub Actions, GitLab CI, Bitbucket Pipelines, or Jenkins]
```

---

## Deployment Checklist Template

```markdown
# Deployment Checklist: [Release Name / Version]
**Release Date:** [Date]
**Deployment Window:** [Start time – End time, timezone]
**Release Manager:** [Name]
**On-Call Developer:** [Name]

## Pre-Deployment (T-minus)
- [ ] Validation deploy to production completed and passed
- [ ] Quick deploy ID recorded: [ID]
- [ ] All go/no-go criteria met (see Release Plan)
- [ ] Rollback procedure reviewed with on-call developer
- [ ] Stakeholder notification sent (deployment starting)
- [ ] Feature flags set to pre-deployment state
- [ ] Change request / approval ticket approved: [Ticket ID]
- [ ] Backup of production metadata retrieved (`sf project retrieve`)
- [ ] External integration partners notified (if applicable)
- [ ] Monitoring dashboards open and baselined

## Deployment Steps
| Step | Action | Command / Procedure | Expected Result | Status |
|---|---|---|---|---|
| 1 | Deploy metadata package | `sf project deploy start --manifest manifest/package.xml --test-level RunSpecifiedTests` or quick deploy | Deployment success | [ ] |
| 2 | Verify deployment status | `sf project deploy report` | All components deployed | [ ] |
| 3 | Run post-deploy Apex script (if any) | `sf apex run --file scripts/post-deploy.apex` | Script completes | [ ] |
| 4 | Execute data updates (if any) | `sf data import tree --files data/[file].json` | Records created/updated | [ ] |
| 5 | Update permission sets (if separate) | `sf project deploy start --manifest manifest/permissions.xml` | Permissions applied | [ ] |
| 6 | Activate Flows (if deployed inactive) | Manual activation in Setup | Flows active | [ ] |
| 7 | Toggle feature flags | Update custom metadata / custom settings | Features enabled | [ ] |

## Post-Deployment Validation
- [ ] Smoke test: [Critical path 1 — e.g., create a Case, verify assignment]
- [ ] Smoke test: [Critical path 2 — e.g., run a report, verify data]
- [ ] Smoke test: [Critical path 3 — e.g., test integration endpoint]
- [ ] Verify no new error logs in Event Monitoring
- [ ] Confirm automated jobs still running (scheduled Apex, batch jobs)
- [ ] Verify integration endpoints responding
- [ ] Check Apex exception emails (none unexpected)

## Stakeholder Notification
- [ ] Deployment completion email sent
- [ ] Release notes published / linked
- [ ] Known issues documented and communicated
- [ ] Support team briefed on changes

## Monitoring Period
- **Duration:** [X hours / X days]
- **What to watch:** Error rates, page load times, integration failures, user-reported issues
- **Escalation trigger:** [Define thresholds — e.g., error rate > 1%, critical path broken]
- **Rollback decision deadline:** [Time by which we commit to "stable" or "rollback"]
```

---

## Rollback Procedure Template

```markdown
# Rollback Procedure: [Release Name / Version]
**Prepared By:** [Release Manager]
**Date:** [Date]
**Associated Release Plan:** [Link to release plan]

## 1. Rollback Triggers
Initiate rollback if ANY of the following occur:
- [ ] Critical business process broken (case creation, opportunity close, order submission)
- [ ] Data integrity issue detected (wrong values, missing records, duplicate creation)
- [ ] Integration failure affecting downstream systems
- [ ] Performance degradation > [X]% on critical pages
- [ ] Error rate exceeds [X]% of transactions
- [ ] Security vulnerability identified in deployed code
- [ ] Release Manager or Tech Lead calls rollback within the decision window

## 2. Rollback Classification
| Deployment Type | Rollback Method | Complexity | Time Estimate |
|---|---|---|---|
| Metadata-only | Redeploy previous version from source control | Low | 15–30 min |
| Metadata + config (Custom Settings, Custom Metadata) | Redeploy + data restore for settings | Medium | 30–60 min |
| Metadata + data changes | Redeploy + data rollback script | High | 1–2 hours |
| Destructive changes (field/object deletion) | Cannot auto-rollback — requires manual recreation | Critical | 2–4 hours |

## 3. Rollback Steps — Metadata Only
1. Switch to the pre-release branch/tag: `git checkout [pre-release-tag]`
2. Deploy previous version: `sf project deploy start --manifest manifest/package.xml --target-org production`
3. Verify deployment: `sf project deploy report`
4. Run smoke tests against previous functionality
5. Deactivate any new Flows that were activated during deployment
6. Revert permission set changes if applicable
7. Confirm rollback successful with stakeholders

## 4. Rollback Steps — Metadata + Data
1. Execute metadata rollback (Steps 1–7 above)
2. Run data rollback script: `sf apex run --file scripts/rollback-data.apex`
3. Verify data integrity: run validation queries
4. Confirm record counts and values match pre-deployment state

## 5. Rollback Steps — Destructive Changes
**WARNING:** Destructive changes (deleted fields, objects, record types) may not be fully reversible.
1. Recreate deleted metadata components from source control definitions
2. Restore field values from backup data export (if available)
3. Rebuild relationships and dependencies manually
4. Run full regression test suite after recreation
5. Document any data loss or irrecoverable changes

## 6. Post-Rollback Validation
- [ ] All smoke tests pass on previous functionality
- [ ] No new error logs generated
- [ ] Integration endpoints functioning
- [ ] Users can perform critical business processes
- [ ] Automated jobs running normally

## 7. Post-Rollback Communication
| When | What | Audience | Channel |
|---|---|---|---|
| Immediately | Rollback initiated — service may be intermittent | All users | Slack / Email |
| After rollback | Rollback complete — system restored to previous state | All stakeholders | Email |
| Within 24 hours | Root cause analysis and re-release plan | Release board | Meeting |

## 8. Re-Deployment Strategy
After rollback:
1. Conduct root cause analysis within [X] hours
2. Fix the issue in a development environment
3. Test the fix through the full pipeline (no shortcuts)
4. Schedule re-deployment with the standard release process
5. Update risk assessment in the Release Plan
```

---

## Change Management Plan Template

```markdown
# Change Management Plan: [Release / Feature Name]
**Author:** [Release Manager]
**Version:** [X.X]
**Last Updated:** [Date]

## 1. Change Summary
**What's changing:** [Brief description of the change]
**Why it's changing:** [Business driver]
**Who's affected:** [User groups, count estimates]
**When:** [Release date]

## 2. Stakeholder Analysis
| Stakeholder Group | Impact Level | Change Description | Sentiment | Champion |
|---|---|---|---|---|
| [Sales reps] | High | New lead assignment process | [Supportive / Neutral / Resistant] | [Name] |
| [Service agents] | Medium | Updated case page layout | [Supportive / Neutral / Resistant] | [Name] |
| [Managers] | Low | New dashboard for visibility | [Supportive / Neutral / Resistant] | [Name] |
| [Admins] | Medium | New configuration to maintain | [Supportive / Neutral / Resistant] | [Name] |

## 3. Communication Plan
| Timing | Message | Audience | Channel | Owner |
|---|---|---|---|---|
| T-30 days | Change is coming — why and what to expect | All affected | Email + town hall | PM |
| T-14 days | Preview of new features — what you'll see | End users | Training preview video | BA |
| T-7 days | Final details — what changes on release day | All affected | Email | Release Manager |
| T-0 | It's live — here's what you need to do | All affected | Slack + email | Release Manager |
| T+7 days | How's it going — feedback collection | End users | Survey | BA |
| T+30 days | Adoption check — metrics review | Leadership | Report | PM |

## 4. Training Plan
| Audience | Format | Duration | Content | Delivery Date | Owner |
|---|---|---|---|---|---|
| [Sales reps] | Live walkthrough + recording | 30 min | New lead process, updated screens | [Date] | BA |
| [Service agents] | Self-paced guide + office hours | 20 min read + drop-in | Updated case layout, new fields | [Date] | BA |
| [Managers] | Dashboard walkthrough | 15 min | New reports, how to interpret | [Date] | BA |
| [Admins] | Technical briefing | 45 min | Configuration changes, maintenance | [Date] | Release Manager |

### Training Materials Required
- [ ] Step-by-step user guide (delegate to BA)
- [ ] Quick reference card (delegate to BA)
- [ ] Recorded walkthrough video
- [ ] FAQ document
- [ ] Admin technical guide

## 5. Adoption Metrics
| Metric | Target | Measurement Method | Review Cadence |
|---|---|---|---|
| Feature usage rate | [X]% of target users within 30 days | Salesforce reports / Event Monitoring | Weekly |
| Support ticket volume | < [X] related tickets per week | Service Cloud report | Weekly |
| User satisfaction | ≥ [X] on 5-point scale | Post-launch survey | T+14, T+30 |
| Process compliance | [X]% using new process vs. workarounds | Report on record field population | Weekly |

## 6. Resistance Management
| Anticipated Objection | Response | Action |
|---|---|---|
| "The old way was faster" | Acknowledge learning curve — share efficiency data after ramp | Provide quick reference card, monitor adoption |
| "I wasn't told about this" | Review communication cadence — ensure all channels covered | Add stakeholder to distribution, personal outreach |
| "It doesn't work for my use case" | Capture as feedback — assess scope gap vs. training gap | Log as backlog item if genuine gap |

## 7. Hypercare Support Model
- **Duration:** [2 weeks / 1 month after release]
- **Support channels:** [Slack channel, email alias, office hours]
- **Staffing:** [Who's on point — BA, Admin, Dev, Release Manager]
- **Escalation path:** [User → Support channel → Admin → Dev → Release Manager]
- **Daily check-in:** [Time, channel] for first [X] days
- **Exit criteria:** Support ticket volume below [X] per day for [X] consecutive days
```

---

## Release Notes Template

```markdown
# Release Notes: [Release Name / Version]
**Release Date:** [Date]
**Version:** [vX.Y.Z]
**Environment:** [Production / Sandbox name]
**Release Manager:** [Name]

## Summary
[2-3 sentence summary of what this release delivers and why it matters to users.]

## New Features
| Feature | Description | User Impact | Cloud |
|---|---|---|---|
| [Feature name] | [What it does — user-facing description] | [What changes for the user] | [Sales / Service / etc.] |
| [Feature name] | [What it does] | [What changes] | [Cloud] |

### [Feature Name] — Details
**What:** [Expanded description]
**Why:** [Business driver]
**How to use:** [Brief instructions or link to guide]
**Who:** [Which user roles benefit]

## Enhancements
| Enhancement | Description | Affected Area |
|---|---|---|
| [Enhancement name] | [What improved and how] | [Object / Page / Process] |

## Bug Fixes
| ID | Description | Impact | Reported By |
|---|---|---|---|
| [BUG-001] | [What was broken and how it's fixed] | [Who was affected] | [Source] |

## Known Issues
| ID | Description | Workaround | Target Fix |
|---|---|---|---|
| [KNOWN-001] | [What's still broken] | [How to work around it] | [Next release / TBD] |

## Action Required
### For Admins
- [ ] [Action item — e.g., assign new permission set to user group X]
- [ ] [Action item — e.g., update page layout for profile Y]

### For End Users
- [ ] [Action item — e.g., review new fields on Case record]
- [ ] [Action item — e.g., bookmark new dashboard]

## Technical Details (Admin / Developer Reference)
- **Metadata components deployed:** [Count — X Apex classes, Y Flows, Z LWCs]
- **Test coverage:** [Org-wide coverage after deployment]
- **Deployment method:** [sf project deploy / Change Set / DevOps Center]
- **Deployment duration:** [X minutes]
```
