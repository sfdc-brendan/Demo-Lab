---
name: sf-afcc-media-management
description: Manage audio media for native Salesforce Voice in Agentforce Contact Center. Use when uploading .mp3/.wav files, organizing the media library, creating and assigning custom and default media labels for IVR prompts, welcome messages, hold music, and recording announcements, and cleaning up unused media.
disable-model-invocation: true
---
# AFCC Media Management

## Use This Skill When

- You need to upload and centrally manage audio files for voice experiences (IVR prompts, welcome messages, hold music, recording announcements).
- You need to create media labels that can be selected in Omni-Channel flows / Play Prompt.
- You need to update, replace, or delete media files or labels.
- You are migrating an existing org's media setup to the new Media Management page.

## Prerequisites

- Permission set: **Agentforce Contact Center Admin (Salesforce Voice)**.
- Editions: Agentforce Contact Center with Salesforce Voice — Enterprise, Unlimited, or Developer.
- Files must be **.mp3** or **.wav**, up to **5MB** each.

## Core Workflow

1. **Add a media file**
   - Setup > Quick Find `Voice` > **Media Management** > **Media Library** tab > **Add Media File**.
   - Upload via **Browse**, **drag & drop**, or **URL** (public .mp3/.wav — Salesforce downloads and stores it).
   - Agree to consent, then enter metadata: **Media File Label** (required; unique; max 100 chars; letters/numbers/spaces/hyphens/underscores only; no `/ \ # % ?`; case-insensitive so `holdmusic` == `HoldMusic`) and optional **Language** for filtering. Save.
2. **Add a custom media label**
   - Media Management > **Media Labels** tab > **New Media Label** in the **Custom Media Labels** section.
   - Enter a unique **Media Label** name describing the audio's use, select a **Media File** from the dropdown, Save. The label is now selectable in flows.
3. **Edit a custom media label**
   - Media Labels tab > Custom Media Labels > select the label > update the assigned **Media File** > Save.
4. **Edit a default media label**
   - Media Management > **Default Media Labels** section > **Edit** next to the label > select a different media file > Save.
5. **Delete a custom media file**
   - Media Library tab > find the file > **Delete** > confirm. If the file is in use, the system lists the labels referencing it (remove those first).
6. **Delete a custom media label**
   - Media Labels tab > Custom Media Labels > find the label > **Delete**. If referenced by an active IVR flow, deletion is blocked and references are listed — remove from those flows first, then delete and confirm.

## Migration Notes (existing orgs)

Retry setup on the Media Management page to migrate data. During migration the system:
- Moves the custom **Queue Music** label to Default Media Labels (if it existed).
- Shows existing **Music on Hold** and **Recording Announcement** associations under Custom Media Labels.
- Renames a user file (adds a suffix) if its name collides with a new default (e.g., **Default Hold Music**).
- Prefers a **Custom Hold Music** file over the default Hold Music (Music on Hold) when a custom label exists.
- Links default files to default labels when none is linked; retains files tied to default **Hold Music** / **Call Recording Message** labels.
- Adds Music on Hold / Recording Announcement labels under Custom Media Labels only when a file is associated in IVR.
- Uses the **Default Queue Music** file for queue music unless a same-named label is explicitly configured.

## Guardrails

- Enforce the naming rules and 5MB / .mp3 / .wav limits up front to avoid upload rejections.
- Labels are **case-insensitive** — avoid near-duplicate names.
- A custom label referenced by an **active IVR flow cannot be deleted** — remove references first.
- A media file **in use by any label cannot be deleted** — reassign or remove associations first.

## Deliverables

- An organized media library with correctly named, compliant audio files.
- Custom and default media labels mapped to files and available in Omni-Channel flows.
- A clean-up plan honoring reference constraints.

## Additional Resources

- Consuming media in IVR: `sf-afcc-ivr-flow`. Callback prompts: `sf-afcc-callbacks`.
- Source docs: Manage Media — https://help.salesforce.com/s/articleView?id=service.afcc_sv_manage_media.htm&type=5 ; Add Media Files — https://help.salesforce.com/s/articleView?id=service.afcc_sv_add_media_files.htm&type=5
