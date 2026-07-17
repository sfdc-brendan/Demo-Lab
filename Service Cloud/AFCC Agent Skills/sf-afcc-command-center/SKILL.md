---
name: sf-afcc-command-center
description: Configure Command Center for Service (supervisor experience) in Agentforce Contact Center. Use when setting up Supervisor Configurations, choosing visible tabs and visible Agentforce agents for monitoring/listen-in, and installing the Command Center Service reports and dashboards (including the Voice Calls report-type conflict workaround).
disable-model-invocation: true
---
# AFCC Command Center (Supervisor)

## Use This Skill When

- You need supervisors to monitor queues, reps, and Agentforce Voice sessions (wallboard, calls in queue, flag raise, whisper, listen-in).
- You need to swap demo-data tabs for tabs that use real org data.
- You need to control which Agentforce agents are visible for monitoring.
- You need the Command Center Service reports and dashboards to install and display correctly.

## Prerequisites

- Supervisor permission set assigned (**Agentforce Contact Center Supervisor (Salesforce Voice)**).
- For Agentforce Voice session monitoring, the Agentforce Voice agent must be configured (`sf-afcc-agentforce-voice-agent`).

## Core Workflow

1. **Configure visible tabs**
   - Setup > **Supervisor Configurations** > create a new configuration or edit the existing one.
   - Under **Define Visible Tabs**, add/remove until Selected Tabs match your target (e.g., Wallboard, Queues, Agentforce sessions, rep monitoring). Note: SDO tabs marked with `*` contain demo data — swap for real-data tabs where needed.
2. **Set visible Agentforce agents**
   - In the same configuration, under **Select Visible Agentforce Agents**, choose which agents display for monitoring/listen-in.
3. **Install Service reports & dashboards**
   - Open the **Command Center Reports** tab. If reports error, run the install from Setup > **Service Cloud Reports**.
4. **Resolve the Voice Calls report-type conflict**
   - A report type `SDO_Service_VoiceCalls` labeled **Voice Calls** conflicts with an out-of-the-box report type of the same name.
   - Setup > **Report Types** > rename the existing org report type from "Voice Calls" to something unique (e.g., "Voice Calls SDO"), then **re-run** the installation from Service Cloud Reports.
5. **Fix Rep/IVR metrics reports**
   - Ensure **Skills-Based Routing** is enabled under Omni-Channel settings, or the **Rep Metrics** report won't install (it's on by default in the SDO).

## Guardrails

- Command Center reports "likely won't display correctly by default" — expect to apply the Voice Calls report-type rename and re-run install.
- Agentforce Voice session monitoring and rep monitoring/whisper tabs must be explicitly added in Supervisor Configurations — they aren't all present by default.
- For Quality Management (WEM) metrics report issues, consult the "Agentforce Contact Center - WEM | SDO Setup Guide."

## Deliverables

- A Supervisor Configuration with the right visible tabs and Agentforce agents for the demo story.
- Installed, correctly displaying Command Center Service reports and dashboards.
- Documented workarounds applied (report-type rename, skills-based routing).

## Additional Resources

- Related: `sf-afcc-agentforce-voice-agent`, `sf-afcc-agentforce-for-service`, `sf-afcc-troubleshooting`.
- Pair with `sf-service-omnichannel-routing` for routing/capacity design.
