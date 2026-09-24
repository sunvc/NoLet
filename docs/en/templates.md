# 📨 Message Template Field Reference

Nolet messages use the `style` field to switch between different card templates. This document lists all available fields, organized by template.

> **Platform tags:** `全平台` = supported on both Apple and HarmonyOS; `apple` = Apple only; `harmony` = HarmonyOS only. Every field below is tagged at the end with the platform it takes effect on.
>
> **Important difference:** the five card templates (`style`), the `other` extension field, `reply`, and `location` are all **Apple-side capabilities (platform tag `apple`)**. HarmonyOS does not distinguish templates; **all bodies are rendered uniformly as Markdown** in a generic card.

---

## Common Message Fields

All templates use the `Message` struct as their data source. Fields fall into two categories:

### User-configurable Fields (passed via Push API / SDK)

| Field | Type | Required | Description | Platform |
|------|------|------|------|----------|
| `group` | `String` | ✅ | Group name / category label | 全平台 |
| `body` | `String` | ✅ | Message body text (supports HTML tags such as `<br/>`, `<b>`) | 全平台 |
| `title` | `String?` | - | Title | 全平台 |
| `subtitle` | `String?` | - | Subtitle | apple |
| `icon` | `String?` | - | Avatar / icon URL | 全平台 |
| `url` | `String?` | - | External link URL | 全平台 |
| `image` | `String?` | - | Image attachment URL | 全平台 |
| `reply` | `String?` | - | Reply API URL (reply box is shown when present) | apple |
| `ttl` | `Int` | - | Message lifetime in seconds; `0` means do not archive / permanent, see each platform's conventions | 全平台 |
| `style` | `String?` | - | **Template selector**. See each template's section below | apple |
| `other` | `String?` | - | JSON string holding template-specific extension fields. See below for the keys supported by each template | apple |
| `location` | `String?` | - | Coordinates `"lat,lng"` or a callback URL. See [📍 Location](#-location) below | apple |

### System-generated Fields (no user input needed)

| Field | Type | Description | Platform |
|------|------|------|----------|
| `id` | `String` | Unique message identifier. Auto-generated UUID | 全平台 |
| `createDate` | `Date` | Message receive / creation time. Written by the system | 全平台 |
| `read` | `Bool` | Read / unread status. Managed by the App | 全平台 |

> `body` is converted to plain text in the App via the `.plainText` property, and templates display `body.plainText`. On HarmonyOS, Markdown markup and link URLs are likewise stripped from the notification body before display.

---

## 📍 Location

> This entire location feature (both direct coordinates and callback retrieval) is **supported on Apple only (platform tag `apple`)**. HarmonyOS does not parse the `location` field.

The `location` field supports two entirely different modes: **Direct Coordinates** and **Callback Retrieval**. The server automatically determines which mode to use based on the value of `location`.

### Mode Detection

| `location` Value | Mode | Description | Platform |
|---------------|------|------|----------|
| `"latitude,longitude"` coordinate string | **Direct Coordinates mode** | Coordinates are shown directly on the message card and a map snapshot is generated | apple |
| Valid URL (has scheme + host) | **Callback Retrieval mode** | Triggers an Apple Location Push; after obtaining the device's actual location, it POSTs to the callback URL | apple |

> The server decides by parsing the value as a URL: if both `Scheme` and `Host` can be extracted, it is Callback Retrieval mode; otherwise it is Direct Coordinates mode.

---

### Mode 1: Direct Coordinates

Pass comma-separated latitude and longitude. The coordinates are sent to the device along with the message, a 🗺️ map button appears on the message card, and a map snapshot together with a reverse-geocoded address is attached to the notification.

#### Push Examples

```json
{
    "group": "Work",
    "title": "Meeting Point",
    "subtitle": "Q3 Review",
    "body": "Please arrive on time",
    "location": "31.2304,121.4737"
}
```

```sh
# GET request
curl "https://wzs.app/your_key/Meeting Point/Q3 Review/Please arrive on time?location=31.2304,121.4737&group=Work"
```

#### Device-side Behavior

1. On push arrival, the notification service extension parses `"31.2304,121.4737"` -> coordinates `(31.2304, 121.4737)`
2. Automatically reverse-geocodes and **appends the formatted address** (e.g. "Nanjing East Road, Huangpu, Shanghai") to the end of the notification body
3. Generates a map snapshot image (with a pin marker) as a **notification attachment**
4. When the message is saved, `location` is stored in the `other` JSON field
5. The message card shows a 🗺️ map button at the bottom. Tapping it opens Apple Maps for navigation

#### Coordinate Format Requirements

| Rule | Description | Platform |
|------|------|----------|
| Format | `latitude,longitude`, separated by a comma | apple |
| Latitude range | `-90.0` ~ `90.0` | apple |
| Longitude range | `-180.0` ~ `180.0` | apple |
| Auto-correction | If latitude/longitude are reversed (longitude exceeds ±90), the App swaps the order automatically | apple |

#### Supported Templates

| Template | Map Button | Platform |
|------|----------|----------|
| `PlainMessageCard` | ✅ Shows a 🗺️ map button at the bottom | apple |
| `MarkdownMessageCard` | ❌ Not read | apple |
| `TerminalMessageCard` | ❌ Not read | apple |
| `GitHubMessageCard` | ❌ Not read | apple |
| `PaymentMessageCard` | ❌ Not read | apple |

---

### Mode 2: Callback Retrieval (Location Push)

Pass a callback URL. The server sends an **Apple Location Push** (a silent push) to the device. The device fetches its current GPS position in the background and POSTs the coordinates back to your callback URL. **This mode does not display any notification on the device.**

#### Prerequisites

The device must first register a Location Push Token through the App. On launch, the App automatically calls `startMonitoringLocationPushes` to obtain the token and uploads it to the server during registration (the `location` field).

#### Push Examples

```json
{
    "title": "Device Location Query",
    "subtitle": "iOS Device",
    "body": "Retrieve current device location",
    "location": "https://your-server.com/location-callback"
}
```

```sh
# GET request
curl "https://wzs.app/your_key?location=https://your-server.com/location-callback&title=Device Location Query&body=Retrieve current device location"
```

#### Callback Request

Once the device obtains its location, it sends a **POST** request to the callback URL specified in `location`:

```json
{
    "title": "Device Location Query",
    "subTitle": "iOS Device",
    "body": "Retrieve current device location",
    "location": "31.2304,121.4737"
}
```

| Callback Field | Type | Description | Platform |
|----------|------|------|----------|
| `title` | `String?` | The `title` from the original push request | apple |
| `subTitle` | `String?` | The `subtitle` from the original push request | apple |
| `body` | `String?` | The `body` from the original push request | apple |
| `location` | `String` | The device's current GPS coordinates, in `"latitude,longitude"` format | apple |

> **Note**: The callback field is named `subTitle` (camelCase), which differs from the push API's `subtitle`.

#### Callback Retries

The device retries up to **3 times**. On network errors it retries automatically until it succeeds or reaches the limit.

#### Apple Limitations

Location Push is subject to Apple platform restrictions:

| Limitation | Description | Platform |
|--------|------|----------|
| Rate limit | At most **3 times per hour**; requests beyond that are discarded by the system | apple |
| Validity | The Location Push is retained at APNs for **10 minutes** | apple |
| User authorization | The device must have granted "Always Allow" location permission | apple |
| Low Power Mode | May be delayed or denied in Low Power Mode | apple |
| Silent | No notification is shown at all — location is retrieved completely silently | apple |

---

### Mode Comparison

| | Direct Coordinates mode | Callback Retrieval mode |
|----|----------|----------|
| `location` value | `"31.2304,121.4737"` | `"https://your-server.com/callback"` |
| Server PushType | Standard push (`1`) | Location Push (`2`) |
| Shows a notification | ✅ Yes | ❌ Silent |
| Device behavior | Shows map button + notification attachment | Background GPS fetch -> POST callback |
| Map button | ✅ | ❌ (no message card is produced) |
| Use case | Telling the user a known location | Querying the device's actual current location |
| Requires Location Token | ❌ | ✅ (auto-registered by the App) |
| Platform | apple | apple |

---

---

## Template Overview

| style Value | Template | Description | Platform |
|----------|------|------|----------|
| Not set / other | `PlainMessageCard` | Default card, suitable for general notifications | apple |
| `markdown` | `MarkdownMessageCard` | Rich text card with Markdown rendering | apple |
| `terminal` | `TerminalMessageCard` | Terminal / command-line style, suitable for ops / monitoring | apple |
| `github` | `GitHubMessageCard` | GitHub event style, suitable for code / CI notifications | apple |
| `pay` | `PaymentMessageCard` | Payment / billing notification card | apple |

> HarmonyOS has no concept of the templates above: regardless of the `style` value, it always uses the generic card and renders `body` as Markdown.

---

## 1. PlainMessageCard (Default)

**Trigger:** `style` not set or not matching any other template

![Default card layout]

```
┌────────────────────────────┐
│  [Image] (optional)        │
│  ┌──────────────────────┐  │
│  │ Title         [Menu] │  │
│  │ Subtitle             │  │
│  │                      │  │
│  │ Body (up to 5 lines) │  │
│  │ ─────────────────── │  │
│  │ [Icon] Group [Link] [Map] │
│  └──────────────────────┘  │
└────────────────────────────┘
```

### Message Fields Used

| Field | Usage | Required | Platform |
|------|------|------|----------|
| `title` | Main title (**headline**, bold) | - | 全平台 |
| `subtitle` | Subtitle (subheadline, with letter spacing) | - | apple |
| `body` | Body content, up to 5 lines displayed | ✅ | 全平台 |
| `image` | Large image at the top | - | 全平台 |
| `icon` | Avatar at the bottom | - | 全平台 |
| `group` | Group name at the bottom | ✅ | 全平台 |
| `url` | Shows the 🔗 link button | - | 全平台 |
| `location` | Coordinates `"lat,lng"` show the 🗺️ map button. See [📍 Location](#-location) | - | apple |

### Extension Fields (`other` JSON)

This template does not read the `other` JSON.

### Code Examples

```swift
// id, createDate, read are auto-generated by the system; no need to pass them
Message(
    group: "Work",
    title: "Weekly Report Updated",
    subtitle: "Q3 Week 1",
    body: "This week we completed the homepage redesign and search optimization. See the weekly report for details.",
    url: "https://wiki.example.com/weekly",
    ttl: 3600
    // style not set -> uses the default template
)
```

**Sent via the Push API:**

```json
{
    "group": "Work",
    "title": "Weekly Report Updated",
    "subtitle": "Q3 Week 1",
    "body": "This week we completed the homepage redesign and search optimization. See the weekly report for details.",
    "url": "https://wiki.example.com/weekly",
    "ttl": 3600,
    "location": "31.2304,121.4737"
}
```

---

## 2. MarkdownMessageCard (Markdown Card)

**Trigger:** `style: "markdown"`

```
┌────────────────────────────────┐
│  Title [search highlight] [Menu] │
│  Subtitle                        │
│  - - - (dashed divider) - - -    │
│  [Image] (optional)             │
│                                │
│  Markdown-rendered body        │
│  (supports # ## ### etc.)      │
│                                │
│  ───────────────────────────── │
│  [Icon] Group          [🔗Link]│
│  ════════════════════════════  │
│  (colored status bar at bottom)│
└────────────────────────────────┘
```

### Message Fields Used

| Field | Usage | Required | Platform |
|------|------|------|----------|
| `title` | Title (supports search highlight) | - | 全平台 |
| `subtitle` | Subtitle (supports search highlight) | - | apple |
| `body` | Body content in **Markdown format** | ✅ | 全平台 |
| `image` | Inline image | - | 全平台 |
| `icon` | Avatar at the bottom | - | 全平台 |
| `group` | Group name at the bottom (controlled by the `showGroup` setting) | ✅ | 全平台 |
| `url` | Shows the network icon button; opens in Safari on tap | - | 全平台 |

### No Extension Fields

This template does not read the `other` JSON.

### Code Example

```swift
// id, createDate, read are auto-generated by the system
Message(
    group: "Docs",
    title: "Nolet User Guide",
    body: """
    # Quick Start
    ## Installation
    Search for **Nolet** in the App Store and download.
    ## Configuration
    1. Open the App
    2. Scan QR code to bind device
    3. Start receiving messages
    """,
    ttl: 86400,
    style: "markdown"
)
```

---

## 3. TerminalMessageCard (Terminal Card)

**Trigger:** `style: "terminal"`

```
┌────────────────────────────────┐
│  ● ● ●               [Menu]  ◯│
│  (window buttons)   (TTL ring) │
│                                │
│  $ command title               │
│  >> [subtitle]                 │
│    ┌──────────────────────┐    │
│    │ Terminal output body │    │
│    │ (gray background)    │    │
│    └──────────────────────┘    │
│  [Image] (optional)           │
│                                │
│  [Icon] Group          [LINK]  │
└────────────────────────────────┘
└─ Border color varies with severity ────┘
```

### Message Fields Used

| Field | Usage | Required | Platform |
|------|------|------|----------|
| `title` | Terminal command (displayed in the `$ title` format) | - | 全平台 |
| `subtitle` | Terminal output prefix (displayed as `>> [subtitle]`) | - | apple |
| `body` | Terminal output body (gray code background) | ✅ | 全平台 |
| `image` | Image | - | 全平台 |
| `icon` | Avatar at the bottom | - | 全平台 |
| `group` | Group name at the bottom | ✅ | 全平台 |
| `url` | Shows the LINK button | - | 全平台 |

### Extension Fields (`other` JSON)

| Key | Type | Allowed Values | Description | Platform |
|-----|------|--------|------|----------|
| `severity` | `String` | `"success"` (default green), `"warning"` (orange), `"error"` / `"alert"` / `"system"` (red) | Controls the terminal `$` symbol color, the TTL ring color, and the card border stroke color | apple |

### Code Example

```swift
// id, createDate, read are auto-generated by the system
Message(
    group: "Servers",
    title: "Production DB Disk Space Alarm",
    subtitle: "Warning: /dev/sda1 only 8.5% free",
    body: "Received Prometheus alert: Host [Pro-db-04] has 8.5G/100G remaining and has been trending upward for 15 minutes. Please address ASAP.",
    url: "https://grafana.example.com/alerts",
    ttl: 600,
    style: "terminal",
    other: """
        { "severity": "warning" }
        """
)
```

---

## 4. GitHubMessageCard (GitHub Event Card)

**Trigger:** `style: "github"`

```
┌──────────────────────────────────────┐
│ ▓ │ 📁 GITHUB/REPO • Group  [Menu][◯]│
│   │ [severity] [branch] [source host]│
│   │                                  │
│   │ Title (PR/MR title)              │
│   │ Subtitle (description)           │
│   │  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐    │
│   │  │ Body (code / logs etc.)  │    │
│   │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘    │
│   │ Footer note            [LINK]    │
└──────────────────────────────────────┘
  ↑ Left vertical bar color varies with severity
```

### Message Fields Used

| Field | Usage | Required | Platform |
|------|------|------|----------|
| `title` | PR / commit title | - | 全平台 |
| `subtitle` | Description / summary | - | apple |
| `body` | Body content (code diffs, logs, etc.), displayed on a gray background | - | 全平台 |
| `group` | Group name, shown to the right of the header | ✅ | 全平台 |
| `url` | Shows the LINK button | - | 全平台 |

### Extension Fields (`other` JSON)

| Key | Type | Default | Description | Platform |
|-----|------|--------|------|----------|
| `severity` | `String` | `"EVENT"` | Severity level; controls the left vertical bar and label colors: `"INFO"` (blue), `"SUCCESS"` (green), `"WARN"` (orange), `"CRIT"` (red) | apple |
| `header` | `String` | `"GITHUB"` | Top-left header text (e.g. `"GITHUB/REPO"`) | apple |
| `branch` | `String` | `"main"` | Branch name, shown as a label (e.g. `"main <- jwt-auth"`) | apple |
| `from` | `String` | - | Source URL; the host is extracted and displayed automatically | apple |
| `footer` | `String` | - | Footer note text (monospaced, e.g. `"SHA:abc123"`) | apple |

### Code Example

```swift
// id, createDate, read are auto-generated by the system
Message(
    group: "Host Notifications",
    title: "Merge pull request #157 from feature/jwt-auth",
    subtitle: "Implemented OAuth2-compliant JWT core security authentication",
    body: "Supports automatic token refresh and device whitelist validation.",
    url: "https://github.com/apple/swift",
    ttl: 600,
    style: "github",
    other: """
        {
            "header": "GITHUB/REPO",
            "severity": "SUCCESS",
            "branch": "main <- jwt-auth",
            "from": "https://api.github.com",
            "footer": "SHA:abc123def456"
        }
        """
)
```

---

## 5. PaymentMessageCard (Payment Card)

**Trigger:** `style: "pay"`

```
┌────────────────────────────────┐
│  [Icon] Title           [Menu] │
│                                │
│  Body description   Amt/Subtitle│
│  (merchant info)    (large amt) │
│                                │
│  Order No: XXXX (optional)     │
│                                │
│  ████████████████░░░░  ← TTL progress bar
└────────────────────────────────┘
```

### Message Fields Used

| Field | Usage | Required | Platform |
|------|------|------|----------|
| `title` | Notification title (e.g. "Payment Confirmed", "Payment Received") | - | 全平台 |
| `subtitle` | **Amount**, shown in large text on the right (e.g. `"-$6,799.00"`). Color varies by platform | - | apple |
| `body` | Merchant / transaction description | ✅ | 全平台 |
| `icon` | Platform icon URL (favicon recommended) | - | 全平台 |
| `group` | **Payment platform identifier**, determines the brand color (see supported list below) | ✅ | 全平台 |
| `url` | "Open Link" button | - | 全平台 |
| `ttl` | Lifetime; the TTL progress bar at the bottom counts down | ✅ | 全平台 |

### Extension Fields (`other` JSON)

| Key | Type | Description | Platform |
|-----|------|------|----------|
| `ticket` | `String` | Order number / ticket number, shown in the middle of the card | apple |

### Payment Platforms Supported by `group`

| Value | Platform | Brand Color | Platform tag |
|----|------|--------|----------|
| `alipay` / `支付宝` | Alipay | Blue `#128EFA` | apple |
| `wechat` / `wechat pay` / `微信支付` | WeChat Pay | Green `#07C160` | apple |
| `paypal` | PayPal | Dark blue `#003087` | apple |
| `stripe` | Stripe | Purple-blue `#635BFF` | apple |
| `applepay` / `apple pay` | Apple Pay | System primary | apple |
| `googlepay` / `google pay` | Google Pay | Blue `#4285F4` | apple |
| `visa` | Visa | Dark blue `#1A1F71` | apple |
| `mastercard` / `master` | Mastercard | Orange `#FF5F00` | apple |
| `amex` / `american express` | American Express | Blue `#016FD0` | apple |
| `unionpay` / `银联` | China UnionPay | Teal `#00796B` | apple |
| `linepay` / `line pay` | LINE Pay | Green `#06C755` | apple |
| `klarna` | Klarna | Pink `#FFB3C7` | apple |
| `paytm` | Paytm | Light blue `#00BAF2` | apple |
| `discover` | Discover | Orange `#E55C20` | apple |
| `jcb` | JCB | Dark blue `#00377B` | apple |
| `samsungpay` / `samsung pay` | Samsung Pay | Blue `#1428A0` | apple |
| `ideal` | iDEAL | Magenta `#CC0066` | apple |
| `bancontact` | Bancontact | Black `#000000` | apple |
| `giropay` | Giropay | Blue `#005A9B` | apple |
| Other values | Custom | Purple fallback | apple |

### Code Examples

```swift
// Alipay deduction notification (id, createDate, read are auto-generated by the system)
Message(
    group: "alipay",
    title: "Payment Confirmed",
    subtitle: "-$6,799.00",
    body: "You are making a purchase at [Apple Store]. Please confirm the charge.",
    icon: "https://favicon.wzs.app/alipay.com",
    ttl: 600,
    style: "pay"
)

// WeChat payment received notification (with order number)
Message(
    group: "wechat",
    title: "Payment Received",
    subtitle: "+$18.50",
    body: "QR code payment has arrived",
    icon: "https://favicon.wzs.app/wechat.com",
    ttl: 600,
    style: "pay",
    other: """
        { "ticket": "Order No: 2024072420001" }
        """
)
```

---

## Template Selection Mechanism

In `TemplateHandler.swift`, `MessageCardView` automatically selects a template based on the `message.style` field:

```swift
switch message.style?.lowercased() {
case "markdown":  MarkdownMessageCard(...)
case "terminal":  TerminalMessageCard(...)
case "github":    GitHubMessageCard(...)
case "pay":       PaymentMessageCard(...)
default:          PlainMessageCard(...)
}
```

If `style` is not set or its value does not match any known template, `PlainMessageCard` is used by default. Platform: apple (HarmonyOS has no such selection logic and renders Markdown uniformly).

---

## Shared Interactions

All templates share the following interactions (injected uniformly by `MessageInteractiveModifier`):

| Interaction | Action | Platform |
|------|------|----------|
| **Double-tap** | View message details full-screen | apple |
| **Tap time** | Tap the relative time on the card (e.g. "Just now", "5 minutes ago") to bring up an action menu: Copy Content, Share Screenshot, Share Image, Share Text, Reply, Smart Assistant, Delete | apple |
| **TTL** | The message disappears automatically when it expires; a ring or bar countdown is shown on the card | 全平台 (countdown widget differs in form) |
| **Reply** | If the `reply` field has a value, a reply input box appears at the bottom | apple |
| **Screenshot sharing** | A screenshot of the card can be generated for sharing | apple |

> The HarmonyOS generic card supports: truncating bodies longer than 5 lines with a "Show more" affordance, a breathing unread bar, tapping the url row to open the link, and overwrite-refresh by the same id.
