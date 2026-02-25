# Unified Phone Controls (LWC)

Lightning Web Component for **Service Cloud Voice** that shows call controls and timers on **Voice Call** record pages. Agents get mute, hold, transfer, end call, and real-time call/hold timers while on a live call.

---

## How It Works

### Purpose

The component appears **only during an active call** on a Voice Call record. It:

- **Shows call info** from the Voice Call record (phone number, direction).
- **Connects to Service Cloud Voice** via the [Service Cloud Voice Toolkit API](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-service-cloud-voice-toolkit-api.html).
- **Drives call actions**: hold/resume, mute/unmute, transfer, end call, and flag.
- **Tracks time**: total call duration (HH:MM:SS) and total hold time (MM:SS) with color cues (green → yellow → red for hold).
- **Supports two layouts**: full panel (docked) or a floating, draggable mini-bar.

### When the UI Shows

The controls are visible only when **all** of these are true:

1. The page has a **Voice Call record** (e.g. record page with `recordId`).
2. **Service Cloud Voice** is active and the Toolkit API is available.
3. Call status is an **active** state: **Connected**, **On Hold**, or **Incoming** (and not **Ended** or **No Call**).

So: no call or call ended → component hides; call connected or on hold → component shows.

### Flow (High Level)

1. **Load**  
   Component loads on the Voice Call record page, gets the record via Lightning Data Service, and starts polling for the Toolkit API (every 2 seconds).

2. **Connect**  
   When `lightning-service-cloud-voice-toolkit-api` is available, the component registers event listeners for: `callstarted`, `callconnected`, `callended`, `hangup`, `hold`, `resume`, `mute`, `unmute`. Polling stops.

3. **Call lifecycle**  
   - **callstarted** → status "Incoming"; controls may show.  
   - **callconnected** → status "Connected"; call duration timer starts.  
   - **hold** / **resume** → hold timer starts/stops and accumulates; multiple hold sessions are tracked.  
   - **callended** / **hangup** → timers stop, state resets, controls hide.

4. **User actions**  
   Buttons call the Toolkit API (`hold()`, `resume()`, `mute()`, `unmute()`, `endCall()`, etc.). The **toolkit events** (e.g. `mute` / `unmute`) are what update the component's state and UI, so the UI stays in sync with the real call state.

### Key Files

| File | Role |
|------|------|
| `unifiedPhoneControls.js` | Logic: Toolkit wiring, events, timers, state, public API. |
| `unifiedPhoneControls.html` | Markup: Toolkit API (hidden), docked panel, floating mini-bar, debug panel. |
| `unifiedPhoneControls.css` | Layout and styling: container queries, toolbar themes, timers, mini-bar. |
| `unifiedPhoneControls.js-meta.xml` | Metadata: API 58, record page target, VoiceCall object, capabilities, configurable properties. |

### Capabilities

- **Required**: `lightning__ServiceCloudVoiceToolkitApi` (declared in `js-meta.xml`).
- **Target**: `lightning__RecordPage` only.
- **Object**: **VoiceCall** (component is intended for Voice Call record pages).
- **API version**: 58.0 (Toolkit requires 52.0+).

For deeper detail (state, timers, events, handlers, visibility logic), see **DOCUMENTATION.md** and **QUICK_REFERENCE.md** in the component source (if included in this package).

---

## Prerequisites

- **Salesforce org** with **Service Cloud Voice** enabled and configured.
- **Lightning Experience** (Toolkit API is not supported in Classic).
- **Voice Call record** (so the component has a `recordId` on a Voice Call record page).

---

## How to Deploy to a Salesforce Org

### From the Demo-Lab repo

If this package contains the LWC under `force-app/main/default/lwc/unifiedPhoneControls/`, from the **Demo-Lab repo root**:

```bash
sf project deploy start --source-dir "Service Cloud/Unified Phone Controls" --target-org MyOrg
```

Validate first (recommended):

```bash
sf project deploy start --dry-run --source-dir "Service Cloud/Unified Phone Controls" --target-org MyOrg
```

### From a Salesforce project that contains this LWC

If the component lives under `force-app/main/default/lwc/unifiedPhoneControls/`:

```bash
sf project deploy start --source-dir force-app/main/default/lwc --metadata LightningComponentBundle:unifiedPhoneControls --target-org MyOrg
```

### From an unpackaged layout

If the component is under `.../lwc/unifiedPhoneControls/`, from the directory that **contains** the `lwc` folder:

```bash
sf project deploy start --source-dir lwc --metadata LightningComponentBundle:unifiedPhoneControls --target-org MyOrg
```

### VS Code

Right-click the **unifiedPhoneControls** folder (or the `lwc` folder that contains it) and choose **Deploy Source to Org**.

### Change set or Metadata API

Add the **LightningComponentBundle** `unifiedPhoneControls` (all four files: `.js`, `.html`, `.css`, `.js-meta.xml`) to a change set or Metadata API package and deploy.

---

## After Deployment: Add to the Voice Call Page

1. Go to **Setup → Object Manager → Voice Call** (or the app that uses Voice Call).
2. Open the **Lightning Record Page** used when viewing a Voice Call (or create one).
3. In the page editor, drag **Unified Phone Controls** onto the page.
4. Set **recordId** to the page context (usually automatic on a record page).
5. Optionally set:
   - **Debug Mode**: on for troubleshooting.
   - **Toolbar Style**: modern, classic, minimal, or custom.
   - **Toolbar Background Color**: when style is "custom".
6. Save and activate the page; assign it to the right app/profile as needed.

The component will only show when a user is on a Voice Call record and has an **active** call (connected or on hold).

---

## Configuration (App Builder / meta)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **recordId** | String | (from page) | Voice Call record ID (required; usually from record page). |
| **debugMode** | Boolean | false | Shows debug panel and event log. |
| **toolbarStyle** | String | `modern` | `modern`, `classic`, `minimal`, or `custom`. |
| **toolbarBackgroundColor** | String | `rgba(0,0,0,0.85)` | Toolbar background when style is `custom`. |

---

## Troubleshooting

- **Component never appears**  
  Ensure: (1) page is a **Voice Call** record page, (2) Service Cloud Voice is on, (3) user is in an **active** call (e.g. Connected or On Hold). Turn on **Debug Mode** and check the debug panel for "Telephony Connected" and call status.

- **Buttons do nothing**  
  Check that the Toolkit API is available (debug panel) and that no script errors appear in the browser console. Confirm Service Cloud Voice is enabled and the user has an active call.

- **Timers stay at 00:00**  
  Call duration starts on **callconnected**; hold time starts on **hold**. If those events don't fire (e.g. wrong page or no telephony), timers won't run. Use Debug Mode to see event messages.

---

## References

- [Service Cloud Voice Toolkit API](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-service-cloud-voice-toolkit-api.html)
- [Service Cloud Voice setup](https://help.salesforce.com/s/articleView?id=sf.voice_setup.htm)
- [LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
