---
name: sf-service-email-to-case
description: Email-to-Case design and hardening patterns for Service Cloud. Use when implementing email intake, threading, parsing, auto-response rules, assignment logic, and spam/noise controls.
disable-model-invocation: true
---
# Email-to-Case

## Use This Skill When

- Implementing or stabilizing Email-to-Case.
- Reducing duplicate cases and broken email threads.
- Improving triage from unstructured email content.

## Hardening Checklist

- Configure robust threading identifiers and reply behavior.
- Separate inbound domains for support vs notifications.
- Add spam and auto-reply suppression logic.
- Normalize sender intent with parsing patterns and fallback queueing.
- Enforce attachment handling and security policies.

## Outputs

- Intake flow map from mailbox to assigned case.
- Threading and duplicate-prevention policy.
- Triage automation candidates and guardrails.
