---
name: sf-service-self-service-config
description: Experience Cloud and self-service Service Cloud configuration planning. Use when designing deployable site, knowledge, topic, audience, and embedded service configuration bundles.
disable-model-invocation: true
---
# Service Cloud Self-Service Config APIs

## Use This Skill When

- You are configuring Experience Cloud sites and self-service channels for Service Cloud.
- You need to package `Network`, `ExperienceBundle`, branding, navigation, topics, or audience strategy.
- You need deployment sequencing for embedded service, bot, and community metadata.

## Core Workflow

1. **Define channel architecture**
   - Map business journeys to site, bot, and embedded channel entry points.
2. **Bundle deployable metadata**
   - Plan package groups for `Network`, `ExperienceBundle`, `NetworkBranding`, `NavigationMenu`, and related types.
   - Add content model dependencies such as `ManagedTopics`, `TopicsForObjects`, and `DataCategoryGroup`.
3. **Sequence activation dependencies**
   - Configure org settings first, then site shell, then experience assets, then channel integrations.
4. **Plan embedded and bot layers**
   - Include `EmbeddedServiceConfig`, `EmbeddedServiceBranding`, `EmbeddedServiceMenuSettings`, `MessagingChannel`, `Bot`, and `BotVersion` as needed.
5. **Validate discoverability and support flow**
   - Verify search, routing handoff, and escalation to case creation.

## Deliverables

- Self-service metadata bundle map by environment.
- Ordered deployment commands and dependency notes.
- Embedded and bot integration checklist.
- Launch readiness and post-deploy smoke tests.
