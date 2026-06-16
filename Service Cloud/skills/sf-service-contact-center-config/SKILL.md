---
name: sf-service-contact-center-config
description: Contact center and digital channel configuration for Service Cloud. Use when planning Voice, Messaging, Embedded Service, CTI, and channel-object metadata deployment with CLI runbooks.
disable-model-invocation: true
---
# Service Cloud Contact Center Config APIs

## Use This Skill When

- You are setting up Service Cloud Voice, messaging channels, embedded service, or CTI integrations.
- You need a deploy plan for `CallCenter`, `ContactCenter`, `ConversationVendorInfo`, and messaging metadata.
- You need to align channel configuration with case linkage and routing behavior.

## Core Workflow

1. **Map channel footprint**
   - Identify voice, web messaging, SMS/WhatsApp, and social channel requirements.
2. **Package contact center metadata**
   - Group deploy units for `CallCenter`, `ContactCenter`, `MessagingChannel`, `ConversationChannelDefinition`, and `ChannelObjectLinkingRule`.
3. **Include embedded service surface**
   - Add `EmbeddedServiceConfig`, `EmbeddedServiceBranding`, and `EmbeddedServiceMenuSettings`.
4. **Map object extensibility**
   - Include object-level metadata updates for `VoiceCall` and `MessagingSession` where custom fields are required.
5. **Validate operational readiness**
   - Confirm channel activation, object linking, routing path, and transcript/session visibility.

## Deliverables

- Contact center metadata deployment map.
- Channel-to-object linkage plan with dependencies.
- Ordered CLI command sequence and verification steps.
- Risk list for external vendor and channel activation dependencies.
