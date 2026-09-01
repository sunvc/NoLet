# Scripting

BravoPapa supports extending notification behavior with JavaScript scripts. Scripts run in the app's built-in sandboxed JavaScript runtime and can use standard APIs such as `fetch`, `crypto`, `storage`, `setTimeout`, and `console`. There are four script types by purpose.

When creating a script on the app's **Scripts** screen, choose its type:

| Type | Triggered when | Runs in | Entry argument | Return value |
|------|----------------|---------|----------------|--------------|
| **Voice (tts)** | The push's `call` is text to be spoken | Notification Service Extension (background) | Notification field object | Audio bytes (Uint8Array) |
| **Processor** | The push carries a `script` field | Notification Service Extension (background) | Notification field object | Ignored (side effects) |
| **Action** | The user taps a notification button bound to a script | Notification Content Extension (interactive UI) | Notification fields + `actionmode` | Success/failure toast |
| **Plugin** | The push carries a `plugin` field | Notification Service Extension (background, first in the pipeline) | Notification snapshot `note` | Take over / continue |

> The plugin type is the most powerful (it can change notification content, attachments, sound, archiving, decryption, etc.) and has its own full document: [Notification Plugins](/en/plugin). This page covers the basics shared by all types, plus the voice/processor/action types.

---

## Script Basics

#### Entry Convention

The **last expression of the script must be a function**; the app invokes it. Use `async function` for asynchronous logic:

```js
async function (params) {
  // params is the argument object passed in
  const res = await fetch("https://example.com/api", {
    method: "POST",
    body: JSON.stringify(params)
  });
  return await res.text();
}
```

When you tap **Test/Validate** in the script editor, the app runs the script once with each type's sample arguments (voice passes `{call:"Hello World!"}`, processor passes `{title,subtitle,body}`, action passes `{actionmode:"custom"}`).

#### Runtime APIs (available to all types)

| API | Description |
|---|---|
| `fetch(url, init)` | HTTP(S) request, returns a `Response` (`text()`/`json()`/`arrayBuffer()`); http/https only |
| `crypto.getRandomValues` / `crypto.randomUUID()` | Random bytes / UUID |
| `crypto._hmacSha256Base64(keyB64, msg)` | HMAC-SHA256 signature (key and return value are base64) |
| `storage.get/set/remove(key)` | Persistent per-script key-value store that survives launches (strings/numbers/booleans/objects/bytes) |
| `setTimeout` / `setInterval` / `clearTimeout` | Timers |
| `btoa` / `atob` / `TextEncoder` / `TextDecoder` | Base64 and UTF-8 encoding |
| `URL` / `URLSearchParams` | URL parsing and construction |
| `structuredClone(v)` | Deep copy (JSON-based) |
| `console.log/info/warn/error` | Log output, visible in the app logs |

> Plugin-specific methods (`setContent`/`attach`/`setAvatar`/`setSound`/`archive`/`decrypt`) are **only available in plugin mode**; calling them in the other three types throws an "undefined" error.

#### Storage Isolation

`storage` is isolated per script file — different scripts cannot see each other's data, while the same script keeps its data across notifications and launches. It's useful for caching tokens, counters, deduplication state, etc.

---

## Voice Script (tts)

When the push's `call` field is a piece of **text** (not an http link), the app calls the voice script to synthesize audio and plays it as the notification sound (up to about 30 seconds).

- Trigger: `call` is non-URL text. (When `call` is an http link the audio is downloaded directly; when `call: true` the long ringtone is played — neither runs the script.)
- Entry argument: the full notification field object; the text to speak is in the `call` field.
- **Return value**: the audio file bytes (`Uint8Array` / `ArrayBuffer`, e.g. MP3). The app writes them and converts to CAF for playback.

**Example: synthesize speech via an online TTS API**

```js
async function (p) {
  const text = p.call || "You have a new message";
  const res = await fetch("https://your-tts.example.com/synthesize", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ text: text, voice: "en-US" })
  });
  if (!res.ok) throw new Error("tts failed: " + res.status);
  // Return audio bytes (a system-recognizable format such as MP3)
  return new Uint8Array(await res.arrayBuffer());
}
```

Push example:

```json
{ "title": "Incoming call", "body": "Tap to view", "call": "Alex: want to grab dinner after work?" }
```

---

## Processor Script

When a push carries a `script` field (whose value is a script name), the app runs the processor script in the background. It does **not change how the notification is displayed** — it's for side effects: forwarding to a webhook, logging, integrating with your own services, counting, etc.

- Trigger: the `script` field = the processor script name (without `.js`).
- Entry argument: the full notification field object (`title`/`subtitle`/`body`/`group` and custom fields).
- Return value: ignored.

**Example: forward the notification to your own service**

```js
async function (p) {
  await fetch("https://your-server.example.com/hook", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      title: p.title, body: p.body, group: p.group,
      receivedAt: Date.now()
    })
  });
}
```

Push example:

```json
{ "title": "Server alert", "body": "CPU usage 92%", "script": "forward-alert" }
```

---

## Action Script

Runs when the user taps a **custom button bound to a script** on a notification (see [Custom Action Buttons](#custom-action-buttons) below). The script runs inside the notification pull-down UI, which suits "tap a button to call an API" scenarios: confirm receipt, one-tap clock-in, trigger device control, etc.

- Trigger: the user taps a custom button bound to the script.
- Entry argument: the full notification field object plus an extra `actionmode` field — the identifier of the button that was tapped. When one script is bound to multiple buttons, use it to tell which one the user tapped.
- Return value: completing normally shows "Success"; throwing (or a rejected Promise) shows the error message.

**Example: do different things depending on the button**

```js
async function (p) {
  const action = p.actionmode;          // the identifier of the tapped button
  const base = p.reply || "https://your-server.example.com/action";
  const res = await fetch(base + "?mode=" + encodeURIComponent(action), {
    method: "POST"
  });
  if (!res.ok) throw new Error("HTTP " + res.status);
  // Returning normally shows "Success"
}
```

---

## Notification Categories (Identifiers)

Which buttons appear on a notification is determined by its **category identifier**. The app has three built-in system categories plus 26 customizable categories.

#### System Categories (chosen automatically, no setup)

| Category identifier | Purpose | Built-in buttons |
|---|---|---|
| `myNotificationCategory` | Normal notification (default) | Copy, Mute group for 1 hour, Translate, Summarize |
| `markdown` | Markdown rich-text notification (`style: "markdown"`) | Copy, Mute group for 1 hour, Translate, Summarize |
| `reply` | Notification with a reply box (push has a `reply` field URL) | Text-input reply |

When a normal notification doesn't specify a category, the app picks one of the above automatically based on `style` / `reply`.

#### Custom Categories (alfa – zulu)

The app provides 26 custom category identifiers, taken from the NATO phonetic alphabet:

```
alfa  bravo  charlie  delta  echo  foxtrot  golf  hotel  india
juliett  kilo  lima  mike  november  oscar  papa  quebec
romeo  sierra  tango  uniform  victor  whiskey  xray  yankee  zulu
```

In the app under **Notification Settings → Categories**, configure buttons for one of these categories, then send the push with that **category identifier** set. The notification will show the buttons you configured.

Push example (make the notification use the `alfa` category's buttons):

```json
{ "title": "Door access", "body": "Someone is ringing the bell", "category": "alfa" }
```

> `category` corresponds to the APNs notification category. System categories (markdown/reply) are usually set automatically by the app based on content; to use custom buttons, pass one of alfa–zulu explicitly.

---

## Custom Action Buttons

Under **Notification Settings** in the app, add buttons to a custom category (alfa–zulu). There are two kinds of buttons:

#### Built-in Action Buttons

Choose a built-in action directly — no scripting required:

| Built-in action | Behavior |
|---|---|
| Copy | Copies the notification's `copy` field, or the body if absent |
| Mute group for 1 hour | Mutes the notification's group for 1 hour |
| Translate | Translates the notification body with AI |
| Summarize | Summarizes the notification body with AI |

#### Custom Buttons (can bind an action script)

Set the button title and icon. Its tap behavior:

- **Bound to an action script**: tapping runs that script in the notification UI (i.e. the [Action Script](#action-script) above); the script can tell which button was tapped via the `actionmode` argument.
- **Not bound to a script**: tapping just opens the app.

#### Setup Steps

1. Open the app's **Notification Settings → Categories** and pick a custom category (e.g. `alfa`).
2. Add a button: choose a built-in action, or create a custom button (set title and icon).
3. A custom button can optionally be bound to an **action** script.
4. Send pushes with `category` set to that category identifier (e.g. `alfa`); the notification shows these buttons.

#### Multiple Buttons in One Category Sharing One Script

Bind the same action script to multiple buttons in the same category and distinguish them with `actionmode`:

```js
async function (p) {
  switch (p.actionmode) {
    case "approve": await fetch("https://example.com/approve", { method: "POST" }); break;
    case "reject":  await fetch("https://example.com/reject",  { method: "POST" }); break;
  }
}
```

---

## Limits & Notes

- The Notification Service Extension (voice/processor/plugin) has a limited runtime (around a few dozen seconds, system-dependent); network requests should finish quickly. On timeout the system delivers the original notification.
- The action script runs in the Notification Content Extension and relies on the user opening the notification UI; a "Running script…" indicator is shown while it executes.
- `fetch` only allows `http`/`https`, and headers such as `host` and `content-length` are forbidden.
- The voice script must return bytes of a system-recognizable audio format (e.g. MP3), with a duration of up to about 30 seconds.
- The plugin runtime is created fresh per notification (script edits take effect immediately); the voice-script runtime is reused, so edits may require a restart to take effect.
- Script errors are written to the app logs; use `console.log` to help debugging.
