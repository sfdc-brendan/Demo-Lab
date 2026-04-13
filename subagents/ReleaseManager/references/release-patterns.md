# Salesforce Release Management Patterns

Proven patterns for branching, sandbox strategy, CI/CD pipelines, conflict resolution, and release operations in Salesforce projects.

---

## Branching Strategies for Salesforce

### Why Salesforce Branching Is Different

Salesforce metadata doesn't merge the way application code does. XML files are auto-generated, ordering changes between retrievals, and declarative components (Flows, page layouts, profiles) produce large XML diffs that resist clean three-way merges. The branching strategy must account for this.

### Trunk-Based Development

```
main (production truth)
  ├── feature/US-001  (short-lived, < 1 week)
  ├── feature/US-002  (short-lived, < 1 week)
  └── hotfix/BUG-099  (hours, merged same day)
```

**How it works:** Developers branch from `main`, make small changes, and merge back quickly. No long-lived branches.

**Pros:** Low merge conflict frequency, simple model, forces small incremental changes.

**Cons:** Requires high discipline, feature flags for incomplete work, harder for large teams without coordination.

**Best for:** Small teams (2–5 devs), high deployment frequency, mature DevOps practices.

### Feature Branch with Integration

```
main (production truth)
  └── develop (integration branch)
        ├── feature/US-001  (1–2 sprints)
        ├── feature/US-002  (1–2 sprints)
        └── bugfix/BUG-015  (< 1 sprint)
```

**How it works:** Features branch from `develop`, merge into `develop` for integration testing, then `develop` merges to `main` for production release.

**Pros:** Integration testing before production, supports parallel work, familiar to most teams.

**Cons:** Merge conflicts accumulate on `develop`, `develop` can drift from `main`, requires regular sync.

**Best for:** Medium teams (5–15 devs), bi-weekly or monthly releases.

### Release Branch

```
main (production truth)
  └── develop (active development)
        ├── feature/US-001
        └── feature/US-002
  └── release/v2.3 (frozen for QA + deploy)
  └── release/v2.2 (previous — archived)
```

**How it works:** When a release is ready, a `release/vX.Y` branch is cut from `develop`. Bug fixes go into the release branch. After deployment, the release branch merges back to `main` and `develop`.

**Pros:** Decouples ongoing development from release stabilization, clear release artifacts.

**Cons:** More branches to manage, merge-back discipline required, can delay integration of fixes.

**Best for:** Large teams (15+ devs), quarterly or monthly major releases, compliance-heavy environments.

### Salesforce-Specific Branch Rules

- **Never commit Profile XML directly** — profiles are org-wide and unmergeable. Use permission sets instead and deploy profiles via a separate, single-owner process.
- **Retrieve before branching** — always start from a fresh `sf project retrieve` to avoid stale metadata.
- **Use `.forceignore`** — exclude volatile metadata types that change frequently and don't belong in source control (e.g., `*.profile-meta.xml` in most cases).
- **Small, focused commits** — one logical change per commit. Avoid "retrieve everything and commit" patterns.

---

## Sandbox Strategy Patterns

### Standard Promotion Path

```
Developer Sandbox (per dev)
    ↓
Developer Pro / Integration Sandbox (team merge)
    ↓
Partial Copy / QA Sandbox (automated testing)
    ↓
Partial Copy / UAT Sandbox (business validation)
    ↓
Full Copy / Staging Sandbox (pre-production)
    ↓
Production
```

### When to Use Each Sandbox Type

| Sandbox Type | Use When | Avoid When |
|---|---|---|
| **Developer** | Individual dev work, quick experiments, proof of concepts | Need realistic data, integration testing |
| **Developer Pro** | API development, integration testing, need more storage | Need production data patterns |
| **Partial Copy** | QA testing, UAT, training, need representative data | Need full production data volume |
| **Full Copy** | Performance testing, staging, data migration dry-runs, final pre-prod validation | Cost-sensitive, don't need full data |

### Refresh Cadence Patterns

| Pattern | Refresh Trigger | Post-Refresh Actions |
|---|---|---|
| **Sprint-aligned** | Refresh dev sandboxes at sprint start | Deploy current develop branch, seed test data |
| **Release-aligned** | Refresh QA/UAT at release cycle start | Deploy release candidate, load test scenarios |
| **On-demand** | Developer requests fresh environment | Deploy their feature branch |
| **Calendar-based** | Full copy refresh monthly (29-day limit) | Full pipeline redeploy, integration reconfig |

### Data Strategy by Environment

| Environment | Data Approach | PII Handling |
|---|---|---|
| Developer | Apex test data factory — no prod data | N/A |
| Integration | Minimal test data via scripts | N/A |
| QA | Partial copy + post-refresh anonymization | Mask email, phone, SSN |
| UAT | Partial copy with realistic scenarios | Mask PII, preserve relationships |
| Staging | Full copy | Full anonymization required for sensitive orgs |

---

## CI/CD with Salesforce CLI

### Core Deployment Commands

```bash
# Validate without deploying (dry run against target org)
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org production \
  --dry-run \
  --test-level RunSpecifiedTests \
  --tests MyTest1 MyTest2

# Deploy to target org
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org production \
  --test-level RunLocalTests

# Quick deploy (after successful validation)
sf project deploy quick \
  --job-id <validation-deploy-id> \
  --target-org production

# Check deployment status
sf project deploy report --job-id <deploy-id>

# Cancel a running deployment
sf project deploy cancel --job-id <deploy-id>
```

### Test Levels

| Flag | What Runs | When to Use |
|---|---|---|
| `NoTestRun` | No tests | Non-production orgs only, metadata-only changes |
| `RunSpecifiedTests` | Named test classes | PR validation, targeted deployments |
| `RunLocalTests` | All non-managed-package tests | Production deployments, full validation |
| `RunAllTestsInOrg` | Everything including managed package tests | Rarely — only if managed package tests are relevant |

### Pipeline YAML Pattern (GitHub Actions)

```yaml
name: Salesforce CI/CD
on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      - name: Authenticate
        run: sf org login jwt --client-id ${{ secrets.SF_CLIENT_ID }} --jwt-key-file server.key --username ${{ secrets.SF_USERNAME }} --set-default
      - name: Validate deployment
        run: sf project deploy start --manifest manifest/package.xml --dry-run --test-level RunSpecifiedTests --tests ${{ env.TEST_CLASSES }}

  deploy-qa:
    needs: validate
    if: github.event_name == 'push' && github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      - name: Authenticate to QA
        run: sf org login jwt --client-id ${{ secrets.SF_QA_CLIENT_ID }} --jwt-key-file server.key --username ${{ secrets.SF_QA_USERNAME }} --set-default
      - name: Deploy to QA
        run: sf project deploy start --manifest manifest/package.xml --test-level RunLocalTests
```

### Validation Deploy + Quick Deploy Pattern

The most reliable pattern for production deployments:

1. **Validate** — run a dry-run deploy against production with `--dry-run` and `--test-level RunLocalTests`
2. **Wait** — validation results are cached for 10 days
3. **Quick deploy** — when ready, execute the validated deployment instantly with `sf project deploy quick`

This separates the "does it work?" check from the "deploy it now" action, allowing validation days before the release window.

---

## Metadata Conflict Resolution

### Common Conflict Types

| Conflict Type | Cause | Resolution Strategy |
|---|---|---|
| **XML attribute ordering** | Different retrieve order across environments | Use `sf project retrieve` consistently, normalize XML in pre-commit hook |
| **Profile / Permission Set overlap** | Multiple devs modifying the same profile | Use permission sets per feature, avoid profile changes in branches |
| **Flow version conflicts** | Two developers editing the same Flow | Designate Flow ownership — one dev per Flow per sprint |
| **Page layout conflicts** | Multiple devs adding fields to the same layout | Coordinate layout changes in sprint planning, merge manually |
| **Custom label conflicts** | Same label added by different features | Use feature-namespaced label names |

### Prevention Strategies

1. **Assign metadata ownership** — each component has one owner per sprint
2. **Small, frequent merges** — merge to integration branch daily, not at sprint end
3. **Pre-merge retrieve** — always `sf project retrieve` before merging to catch drift
4. **Automated conflict detection** — CI step that flags known conflict-prone metadata types

---

## Destructive Changes Management

### What Are Destructive Changes?

Removing metadata from an org: deleting fields, objects, Apex classes, Flows, etc. These require special handling because `sf project deploy` only adds or updates — it doesn't remove.

### Destructive Changes Manifest

```xml
<!-- destructiveChangesPost.xml — processed AFTER main deployment -->
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>MyOldClass</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>Account.Deprecated_Field__c</members>
        <name>CustomField</name>
    </types>
    <version>62.0</version>
</Package>
```

```bash
# Deploy with destructive changes
sf project deploy start \
  --manifest manifest/package.xml \
  --post-destructive-changes manifest/destructiveChangesPost.xml \
  --target-org production \
  --test-level RunLocalTests
```

### Destructive Changes Safety Rules

1. **Always post-destructive** — delete after deploying replacement code, not before
2. **Never delete fields with data** without a data migration plan
3. **Rollback plan required** — field deletion is irreversible if data existed. Document the rollback as "recreate and restore."
4. **Separate destructive changes from regular deployments** when possible
5. **Require explicit approval** — destructive changes need Release Manager + Tech Lead sign-off

---

## Multi-Package Deployment Ordering

When deploying multiple packages or manifests, order matters:

### Dependency-Based Ordering

```
1. Custom Objects & Fields (schema foundation)
2. Apex Classes (non-trigger, utilities, services)
3. Apex Triggers
4. Flows (depend on objects, fields, and sometimes Apex)
5. LWC Components (depend on Apex controllers, objects)
6. Page Layouts & Record Types
7. Permission Sets & Permission Set Groups
8. Custom Metadata / Custom Settings
9. Destructive Changes (post-deployment cleanup)
```

### Handling Cross-Package Dependencies

- **Shared objects/fields**: Deploy the shared schema package first
- **Apex dependencies**: Use interfaces or late-binding patterns to reduce deploy-order coupling
- **Managed packages**: Deploy managed packages before custom metadata that references them

---

## Release Cadence Patterns

### Bi-Weekly Sprint Release

```
Week 1: Sprint starts, development in feature branches
Week 2: Feature freeze (Wed), QA + UAT (Thu-Fri), deploy (Fri PM or Mon AM)

Cadence: Every 2 weeks
Deploy day: Friday afternoon or Monday morning
Code freeze: 2 days before deploy
```

**Best for:** Agile teams with steady velocity, low-risk incremental changes.

### Monthly Release

```
Weeks 1-2: Development across sprints
Week 3: Code freeze, integration testing, QA
Week 4: UAT (Mon-Wed), go/no-go (Thu), deploy (Fri)

Cadence: Once per month
Deploy day: Last Friday of the month
Code freeze: 1 week before deploy
```

**Best for:** Teams with compliance gates, mixed declarative/code changes, multiple workstreams merging.

### Quarterly Major Release

```
Month 1-2: Development across multiple sprints
Month 3, Week 1-2: Code freeze, integration testing, regression
Month 3, Week 3: UAT, performance testing, go/no-go
Month 3, Week 4: Staged deployment (partial rollout → full rollout)

Cadence: Every 3 months
Deploy day: Coordinated with Salesforce release calendar
Code freeze: 2 weeks before deploy
```

**Best for:** Large orgs, ISV packages, complex multi-team releases, changes that require extensive testing.

### Aligning with Salesforce Release Calendar

Salesforce pushes three major releases per year (Spring, Summer, Winter). Plan your release cadence to:
- **Avoid deploying during Salesforce release weekends**
- **Test in preview sandboxes** before Salesforce releases hit production
- **Review release notes** for deprecations, behavior changes, new limits
- **Schedule a post-SF-release validation** to catch compatibility issues

---

## Hotfix Process

### Emergency Deployment Path

```
Bug reported in production
    ↓
Severity assessment (P1 = critical, P2 = high, P3 = medium)
    ↓
[P1 only] Hotfix branch from main
    ↓
Fix developed + unit tests written
    ↓
Abbreviated code review (1 reviewer, expedited)
    ↓
Validation deploy to production (RunSpecifiedTests)
    ↓
Quick deploy to production
    ↓
Post-deployment smoke test
    ↓
Backmerge hotfix to develop branch
    ↓
Post-incident review within 48 hours
```

### Hotfix vs. Regular Release

| Aspect | Regular Release | Hotfix |
|---|---|---|
| Branch source | `develop` | `main` |
| Code review | Full review (2 reviewers) | Expedited (1 reviewer) |
| Testing | Full pipeline (RunLocalTests) | Targeted (RunSpecifiedTests) |
| UAT | Full business validation | Affected area only |
| Approval | Standard release board | Release Manager + Tech Lead |
| Deploy method | Scheduled window | Immediate |
| Backmerge | N/A | Required — hotfix → develop |

### Hotfix Eligibility Criteria

A hotfix is warranted when:
- Production business process is **blocked** (users cannot complete critical tasks)
- Data integrity issue is **actively causing damage** (wrong values being written)
- Security vulnerability is **actively exploitable**
- Integration failure is **blocking downstream systems**

A hotfix is NOT warranted when:
- The issue is cosmetic or low-impact
- A workaround exists and is acceptable for the next release cycle
- The fix requires changes to multiple interconnected components (too risky for hotfix)

---

## Org Comparison Techniques

### CLI-Based Comparison

```bash
# Retrieve metadata from production
sf project retrieve start --manifest manifest/package.xml --target-org production --output-dir compare/prod

# Retrieve metadata from QA
sf project retrieve start --manifest manifest/package.xml --target-org qa --output-dir compare/qa

# Diff the two directories
diff -rq compare/prod compare/qa

# Detailed diff of specific components
diff compare/prod/force-app/main/default/classes compare/qa/force-app/main/default/classes
```

### What to Compare

| Comparison | Purpose | Frequency |
|---|---|---|
| Source control vs. production | Detect manual changes in prod (metadata drift) | Weekly |
| QA vs. production | Verify QA environment fidelity | Before each release |
| Staging vs. production | Final pre-deploy validation | Before each deploy |
| Post-deploy production vs. expected | Confirm deployment applied correctly | After each deploy |

### Metadata Coverage Audit

Not all metadata types are in source control. Audit coverage regularly:

```bash
# List all metadata types in the org
sf org list metadata-types --target-org production

# Compare against your package.xml
# Identify types present in the org but missing from source control
```

Common gaps: reports, dashboards, email templates, list views, custom labels added via UI.

---

## Change Set vs. CLI vs. DevOps Center

| Capability | Change Sets | Salesforce CLI | DevOps Center |
|---|---|---|---|
| **Source control** | None | Git-based | Git-based (built-in) |
| **Automation** | None | Full CI/CD pipeline | Limited (UI-driven) |
| **Rollback** | Manual | Automated via git | Partial |
| **Conflict resolution** | Manual in UI | Git merge tools | Built-in UI |
| **Test execution** | Basic | Full control (test levels, specific tests) | Managed |
| **Destructive changes** | Not supported | Supported (destructive manifest) | Limited |
| **Multi-developer** | Difficult (serial) | Native (branching) | Supported |
| **Audit trail** | Upload/deploy log | Git history + deploy logs | Built-in tracking |
| **Learning curve** | Low | Medium–High | Medium |
| **Best for** | Quick admin changes, small teams | Mature teams, CI/CD, complex releases | Teams transitioning from change sets |

### Migration Path

```
Change Sets (starting point)
    ↓ Add source control
DevOps Center (transitional)
    ↓ Add CI/CD automation
Salesforce CLI + GitHub Actions / GitLab CI (target state)
```

### When Change Sets Are Still Acceptable

- Solo admin making configuration changes
- Emergency fix when CI/CD pipeline is down
- One-off metadata push that doesn't warrant a pipeline run

Even then, document the change set in the team's change log and backfill into source control.
