# Notification Plugins

A notification plugin is a JavaScript script that **fully takes over** how a single notification is processed inside the Notification Service Extension.

Normal pushes are handled by the app's built-in pipeline (decrypt → archive → badge → sound → attachment/avatar). When a push carries a `plugin` parameter, the app runs your plugin script at the very start of the pipeline. The script decides how the notification is displayed, whether it is archived, what sound it uses, and what attachments it gets — it can call native capabilities equivalent to the built-in pipeline, then terminate the built-in flow.

> Plugins run in a sandboxed JavaScript runtime with standard APIs such as `fetch`, `crypto`, `storage`, `setTimeout`, and `console`, plus the plugin-specific native methods listed below.

#### Use Cases

- Custom decryption / field rewriting, without being limited to the built-in encryption format
- Decide the title, group, interruption level, or badge based on message content
- Conditionally download an image attachment, generate a map snapshot, or set the sender avatar
- Custom sounds (download audio or synthesize speech via the TTS script)
- Decide yourself whether a message is archived and how the unread count changes

#### Install & Trigger

1. Create a new script on the app's **Scripts** screen, set its **type to "Plugin"**, edit and save.
2. Send a push with a `plugin` parameter whose value is the script name (without `.js`):

```json
{
  "plugin": "my-plugin",
  "title": "Title the plugin will rewrite",
  "body": "Any custom field",
  "mydata": "..."
}
```

On receiving the push, the app looks up a script named `my-plugin` of type "Plugin" and runs it. If the script is not found or throws, it falls back to the built-in pipeline.

#### Script Entry Point

The last expression of the script must be an `async function` that receives one argument, `note` — a read-only snapshot of the current notification:

```js
async function (note) {
  // note fields:
  // note.id        notification identifier (targetContentIdentifier)
  // note.title     title
  // note.subtitle  subtitle
  // note.body      body
  // note.group     group (threadIdentifier)
  // note.category  category identifier
  // note.badge     badge number
  // note.level     interruption level: passive / active / timesensitive / critical
  // note.userInfo  the full custom payload object
}
```

> `note` is the **snapshot of the original notification when the plugin starts**. Calling `setContent` and similar methods inside the script does not change it. To make decisions based on modified content, keep track of it in your own variables.

#### Take Over / Continue

The script decides what happens next via its return value:

- **Return nothing / `undefined`**: the plugin has taken over; the **built-in pipeline does not run**. Archiving, badge, sound, and attachments must all be done by the script itself.
- **Return `{ continue: true }`**: let the pipeline continue on the **plugin-modified** notification (the script's changes are kept).
- **Return `{ continue: "original" }`**: let the pipeline continue but **discard all plugin changes**, running on the **original notification**. Useful when the script only performs side effects (reporting, telemetry) and should not affect the notification itself.
- **The script throws**: the error is logged and the built-in pipeline resumes (changes made before the error are kept).

```js
async function (note) {
  // Only report, don't touch the notification: continue with the original content
  await fetch("https://example.com/track", {
    method: "POST",
    body: JSON.stringify(note.userInfo)
  });
  return { continue: "original" };
}
```

```js
async function (note) {
  // Rewrite the title, then let the built-in pipeline run on the modified content
  await setContent({ title: "Rewritten title" });
  return { continue: true };
}
```

> Note: `continue: "original"` only rolls back **notification content** (title, body, attachments, avatar, sound, etc.). Side effects the script already performed are **not undone** — a message already archived via `archive()`, writes to `storage`, and network requests made by `fetch` all remain in effect.

---

## Native Methods

All plugin methods are global async functions that return a Promise; call them with `await`.

### setContent(patch)

Modify the notification content. Only include the fields you want to change in the `patch` object; omitted fields stay unchanged.

| Field | Type | Description |
|---|---|---|
| `title` | string | Title |
| `subtitle` | string | Subtitle |
| `body` | string | Body |
| `group` | string | Group (thread identifier) |
| `category` | string | Notification category identifier |
| `id` | string | Notification identifier (used for dedup / archiving) |
| `level` | string | Interruption level: `passive` / `active` / `timesensitive` / `critical` |
| `badge` | number | Badge number; `<= 0` clears it and syncs the shared unread count |

```js
await setContent({ title: "New title", body: "New body", level: "timesensitive", badge: 5 });
```

### attach(options)

Download an image or generate a map snapshot and attach it to the notification. Returns `true` on success.

- Image attachment: `{ type: "image", url: "https://..." }`
- Map snapshot: `{ type: "map", location: "latitude,longitude" }` (also accepts Chinese comma/colon separators)

```js
if (note.userInfo.image) {
  await attach({ type: "image", url: note.userInfo.image });
}
await attach({ type: "map", location: "39.90,116.40" });
```

### setAvatar(urlOrIconName)

Set the notification's sender avatar (implemented via an Intents donation). The argument can be an image URL or a configured in-app icon name. Returns `true` on success.

```js
await setAvatar(note.userInfo.icon || "https://example.com/a.png");
```

### setSound(spec)

Set the notification sound; returns `true` on success. Three forms:

- Built-in sound name: `setSound("typewriter")` (the `.caf` extension is added automatically)
- Download and convert a remote audio file: `setSound({ url: "https://example.com/a.mp3" })`
- Synthesize speech via the TTS script: `setSound({ tts: "Text to speak" })`

```js
await setSound("alarm");
await setSound({ tts: note.body });
```

> When the interruption level is `critical`, the sound is treated as a critical alert sound (affected by the volume parameter).

### archive(message)

Write the message into the cross-process inbox for the main app to store and display. Returns `true` if it is a **new message** (the shared unread count is automatically incremented), or `false` if a message with the same id already exists (deduplicated).

Common fields of the `message` object: `id`, `title`, `subtitle`, `body`, `group`, `url`, `ttl`, `style`, `other`.
Missing fields are filled in automatically: `id` (the notification id or a random one), `createDate` (current time), `read` (false), and `group` (the current notification group).

```js
const isNew = await archive({
  title: note.title,
  body: note.body,
  group: note.group,
  ttl: 3600,           // expiration in seconds; -1 means never expires
  other: { custom: "x" }
});
```

> In take-over mode the built-in pipeline **does not archive automatically**. If you want the message to appear in the app's list, you must call `archive()` explicitly.

### decrypt(ciphertext, cipherNumber?)

Decrypt ciphertext using the encryption key configured in the app, returning the plaintext field object (lowercased keys). `cipherNumber` is the key-list index, defaulting to `0`.

```js
const info = note.userInfo;
if (info.ciphertext) {
  const m = await decrypt(info.ciphertext, info.ciphernumber || 0);
  await setContent({ title: m.title, body: m.body, group: m.group });
}
```

---

## Built-in Runtime APIs

The plugin runtime also provides these standard capabilities (shared with the TTS and action scripts):

| API | Description |
|---|---|
| `fetch(url, init)` | Make an HTTP(S) request, returns a `Response`; supports `method`/`headers`/`body`/`signal` (AbortController) |
| `crypto.getRandomValues` / `crypto.randomUUID()` | Random bytes / UUID |
| `crypto._hmacSha256Base64(keyB64, msg)` | HMAC-SHA256 signature (key and return value are base64) |
| `storage.get/set/remove(key)` | Persistent per-script key-value store that survives launches (strings/numbers/booleans/objects/bytes) |
| `setTimeout` / `setInterval` / `clearTimeout` | Timers |
| `btoa` / `atob` / `TextEncoder` / `TextDecoder` | Base64 and UTF-8 encoding |
| `URL` / `URLSearchParams` | URL parsing and construction |
| `structuredClone` | Deep copy (JSON-based) |
| `console.log/info/warn/error` | Log output (visible in the app logs) |

---

## Full Examples

**Take-over plugin: custom decryption + attachment + avatar + archiving:**

```js
async function (note) {
  const info = note.userInfo;

  // 1. Custom decryption
  let m = { title: note.title, body: note.body, group: note.group };
  if (info.ciphertext) {
    try { m = await decrypt(info.ciphertext, info.ciphernumber || 0); }
    catch (e) { console.error("decrypt failed", e); }
  }

  // 2. Rewrite notification content
  await setContent({
    title: m.title,
    body: m.body,
    group: m.group || "Default",
    level: info.pinned ? "timesensitive" : "active",
    badge: info.badge
  });

  // 3. Attachments and avatar
  if (info.image) await attach({ type: "image", url: info.image });
  if (info.location) await attach({ type: "map", location: info.location });
  if (info.icon) await setAvatar(info.icon);

  // 4. Sound
  if (info.call) {
    await setSound({ tts: m.body });         // call-style speech announcement
  } else if (info.sound) {
    await setSound(info.sound);
  }

  // 5. Archive (otherwise the message won't appear in the app list)
  await archive({
    title: m.title, subtitle: m.subtitle, body: m.body,
    group: m.group, url: info.url, ttl: info.ttl,
    other: info
  });
}
```

**Call a remote API to decide the notification content:**

```js
async function (note) {
  const res = await fetch("https://example.com/api/notify", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(note.userInfo)
  });
  if (!res.ok) return { continue: true };     // fall back to the built-in pipeline on failure
  const rule = await res.json();
  if (rule.mute) {
    await setContent({ level: "passive" });
  }
  if (rule.title) await setContent({ title: rule.title });
}
```

---

## Limits & Notes

- The Notification Service Extension has a limited runtime (around a few dozen seconds, system-dependent); on timeout the system delivers the original content. Plugins should finish quickly — keep network requests to a few seconds.
- Script execution has a timeout guard; a long-running synchronous infinite loop cannot be interrupted, so avoid writing unbounded synchronous loops.
- `fetch` only allows `http`/`https`; headers such as `host` and `content-length` are forbidden.
- A fresh runtime is created for each notification, so editing the script takes effect on the next notification.
- `storage` is isolated per script file; different plugins do not interfere with each other.
