# Privacy Policy — Dopamine Do

_Last updated: 2026-05-19_

## TL;DR

Dopamine Do does not collect, transmit, or sell your personal data. Everything you create — tasks, settings, custom hype lines, win sounds — lives only on your device. There are no accounts, no analytics, no ads, and no third-party trackers.

---

## What data the app handles

The app stores the following **on your device only**, using Android's `SharedPreferences`:

- **Tasks** you create: title, scheduled time, duration, recurrence, completion status.
- **Settings**: custom hype lines, picked win-sound file path, Quick Nudge voice toggle.
- **Active session state**: the in-progress Action Chamber timer, persisted so it survives an app kill.

This data is **not** transmitted to any server controlled by us or anyone else. Uninstalling the app removes all of it.

## Permissions and why we ask

- **`POST_NOTIFICATIONS`** — to fire the alarm when a task is due.
- **`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`** — so the alarm fires at the precise time you scheduled, not when Android feels like it.
- **`USE_FULL_SCREEN_INTENT`** — so the alarm takes over the screen even when the device is locked (matches the in-app Takeover behavior).
- **`RECEIVE_BOOT_COMPLETED`** — so scheduled alarms survive a phone reboot.
- **`VIBRATE`, `WAKE_LOCK`** — so the alarm can vibrate and wake the device.
- **`RECORD_AUDIO`** (only when you tap the microphone in the new-task sheet) — used by the on-device speech-to-text engine to transcribe your spoken task title. Audio is processed locally by the platform's speech recognizer and not transmitted by this app.
- **`READ_EXTERNAL_STORAGE` / file picker access** (only when you tap "PICK SOUND" in settings) — to let you choose an audio file from your device as your custom win sound. We only store the file path, not the file's contents.
- **`INTERNET`** — used only to stream the optional background lofi music from a public radio stream. No app telemetry, analytics, or account data leaves the device.

## Network traffic

The only outbound network request the app makes is to a public lofi audio stream while a Quick Nudge or Action Chamber session is running. We do not see, log, or store anything about what you're doing — the request goes directly from your device to the third-party stream provider.

## Children's privacy

The app is not directed at children under 13. We do not knowingly collect data from anyone (since we collect no data at all), but please don't use it on behalf of someone under 13.

## Changes to this policy

If this ever changes (e.g., we add accounts, analytics, or anything else that handles your data), the change will be reflected here and announced in the app before it takes effect.

## Contact

For questions or concerns: **qa@xuno.co**
