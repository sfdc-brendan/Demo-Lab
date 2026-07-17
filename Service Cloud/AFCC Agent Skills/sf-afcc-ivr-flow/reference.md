# AFCC IVR — Reference

Deep reference for `sf-afcc-ivr-flow`. Applies to **Salesforce Voice (Native Telephony)**. Admin permission set: **Agentforce Contact Center Admin (Salesforce Voice)**.

Sources (official Salesforce Help, fetched 2026-07-17):
- Set DTMF Values — https://help.salesforce.com/s/articleView?id=service.afcc_sv_set_dtmf.htm&type=5
- Voice Control Options — https://help.salesforce.com/s/articleView?id=service.afcc_sv_voice_controls.htm&type=5
- Languages and Voice Profiles — https://help.salesforce.com/s/articleView?id=service.afcc_sv_voice_profiles.htm&type=5

---

## DTMF Response Values — full workflows

DTMF response values control whether the Play Prompt **validates** the caller's input or simply **captures** it. The Play Prompt compares the caller's input against the configured Response Value to decide whether to proceed or retry.

### Single-digit menu
Example: "Press 1 for Billing, Press 2 for Sales."
- Set the DTMF Response Values to the supported digits (e.g., `1`, `2`).
- If the caller enters a configured value, the flow continues.
- If the caller enters any other value, the prompt repeats until valid input or the retry limit is reached.
- Use the DTMF output to branch the flow (Decision element).

### Multi-digit value
Example: caller provides a ten-digit account number.
- Pass a variable containing the expected value into the DTMF Response Value.
- The caller's input is compared against the expected value; on match the flow proceeds.
- If no match, turn on **Require Response Retry** to replay the prompt until valid input or the retry limit.
- The valid input value is accessible via the DTMF output.

### Collect input without validation
- Pass a flow variable with a **null or empty** value into the DTMF Response Value.
- No comparison is performed; the system accepts any DTMF input and forwards it via the DTMF output.

### Related response settings
- **Min / Max input value length** — corresponds to the DTMF values (single-digit input = 1/1).
- **Response delimiter** — lets the caller signal they've finished entering digits early.
- **Response timeout** — time allowed to enter input; on timeout the prompt replays.
- **Digit timeout** — max time between consecutive digits; after it lapses input is treated as complete.
- **Retry Count** + **Customize retry message** — number of retries and an optional message played before repeating the main prompt.

---

## Voice Control Options — SSML & text normalization

Supported SSML tags:

| Feature / SSML tag | English | Non-English | Notes |
|---|---|---|---|
| `<break>` | Yes | Yes | Accepts fractions |
| `<phoneme>` | Yes | No | Supports CMU/IPA |
| Text normalization | Yes | Yes | Dates, numbers, currency, acronyms |

- **`<break>`** — inserts a pause; `time` attribute in seconds, **max 3s**. Example: `Thank you for calling. <break time="1s"/> Please stay on the line.`
- **`<phoneme>`** — customizes pronunciation with a phonetic alphabet (CMU Pronouncing Dictionary or IPA; CMU recommended). Per-word only. Example: `<phoneme alphabet="cmu-arpabet" ph="M AE1 D IH0 S AH0 N"> Madison </phoneme>`

### Text normalization examples

| Input | Spoken as |
|---|---|
| €99 | Ninety nine euros |
| 12/08/2025 | Twelfth of August two thousand and twenty five |
| www.example.com/link/to/resource | double-u double-u double-u dot example dot com slash link slash to slash resource |
| 3.14 | Three point one four |
| 5 kg | Five Kilo Gram |
| 15th Jan | Fifteenth of January |
| 12:00 PM | Twelve PM |

---

## Languages and Voice Profiles (out-of-the-box)

Default profile per language is marked **(Default)**.

### English (United States) — `en-US`
| Voice Profile | Gender | Age | Tone/Style |
|---|---|---|---|
| Jerry | Male | Middle-aged | Semi-deep, friendly American |
| Jamahal | Male | Young adult | Energetic, vibrant |
| Finn | Male | Young adult | Higher pitch, friendly, brisk |
| Jeff | Male | Middle-aged | Deep, authoritative podcaster |
| Chris | Male | Middle-aged | Bassy, crisp, casual |
| Will | Male | Young adult | Casual, natural, nasal |
| Juniper **(Default)** | Female | Middle-aged | Husky-pitch, polished, authoritative |
| Cassidy | Female | Middle-aged | Huskier, confident |
| Skye | Female | Young adult | Higher-pitched, raspy, melodic |
| River | Female | Young adult | Gender-neutral, smooth |
| Laura | Female | Middle-aged | Higher pitch, slight nasal, sunny |
| Jennifer | Female | Young adult | Husky, Californian, conversational |

### Spanish (Mexico) — `es-MX`
| Voice Profile | Gender | Age | Tone/Style |
|---|---|---|---|
| José | Male | Middle-aged | Professional, semi-deep |
| Javier | Male | Young adult | Young, crisp, quicker-paced |
| Miguel | Male | Middle-aged | Deep, professional |
| Sofía **(Default)** | Female | Middle-aged | Friendly, medium-pitch |
| Camila | Female | Middle-aged | Natural, relaxed |
| Isabel | Female | Middle-aged | Professional, medium-paced, empathetic |

### Portuguese (Brazil) — `pt-BR`
| Voice Profile | Gender | Age | Tone/Style |
|---|---|---|---|
| Thiago | Male | Middle-aged | Bassy, crisp, expressive, precise |
| Pedro | Male | Young adult | Round, warm, conversational |
| Tatiane **(Default)** | Female | Middle-aged | Husky-pitch, expressive, measured |
| Mariana | Female | Young adult | Upbeat, friendly, professional |

### French (Canada) — `fr-CA`
| Voice Profile | Gender | Age | Tone/Style |
|---|---|---|---|
| Mathieu | Male | Middle-aged | Clear, smooth, calm, professional |
| Philippe | Male | Middle-aged | Slow, clear, polished, authoritative |
| Gabriel | Male | Middle-aged | Conversational, friendly, relaxed |
| Mélodie **(Default)** | Female | Middle-aged | Bright, clear, high register, breathy |
| Amélie | Female | Middle-aged | Calm, smooth, slow, reassuring |
| Gabrielle | Female | Middle-aged | Soft, clear Quebec accent, airy |
