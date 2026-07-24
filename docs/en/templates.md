# 📨 Message Template Field Reference

NoLet messages use the `style` field to switch between different card templates. This document lists all available fields organized by template.

---

## Common Message Fields

All templates use the `Message` struct as their data source. Fields fall into two categories:

### User-configurable Fields (passed via Push API / SDK)

| Field | Type | Required | Description |
|------|------|------|------|
| `group` | `String` | ✅ | Group name / category label |
| `body` | `String` | ✅ | Message body text (supports HTML tags such as `<br/>`, `<b>`) |
| `title` | `String?` | - | Title |
| `subtitle` | `String?` | - | Subtitle |
| `icon` | `String?` | - | Avatar / icon URL |
| `url` | `String?` | - | External link URL |
| `image` | `String?` | - | Image attachment URL |
| `reply` | `String?` | - | Reply API URL (reply field is shown when present) |
| `ttl` | `Int` | - | Message Time To Live in seconds. `0` means permanent |
| `style` | `String?` | - | **Template selector**. See each template's section below |
| `other` | `String?` | - | JSON string for template-specific extension fields. See each template for supported keys |
| `location` | `String?` | - | Coordinates `"lat,lng"` or callback URL. See [📍 Location](#-location) below |

### System-generated Fields (no user input needed)

| Field | Type | Description |
|------|------|------|
| `id` | `String` | Unique message identifier. Auto-generated UUID |
| `createDate` | `Date` | Message receive / creation time. Set by the system |
| `read` | `Bool` | Read / unread status. Managed by the App |

> `body` is rendered as plain text in the App via the `.plainText` property. Templates use `body.plainText` for display.

---

## 📍 Location

The `location` field supports two entirely different modes: **Direct Coordinates** and **Callback Retrieval**. The server automatically determines which mode to use based on the value of `location`.

### Mode Detection

| `location` Value | Mode | Description |
|---------------|------|------|
| `"lat,lng"` coordinate string | **Direct Coordinates** | Coordinates are shown on the message card with a map snapshot |
| Valid URL (has scheme + host) | **Callback Retrieval** | Triggers an Apple Location Push, fetches the device's actual location, then POSTs it to the callback URL |

> The server decides by parsing as a URL: if both `Scheme` and `Host` can be extracted, it's Callback mode; otherwise it's Direct Coordinates mode.

---

### Mode 1: Direct Coordinates

Pass comma-separated latitude and longitude. The coordinates are sent with the message, a 🗺️ map button appears on the message card, and a map snapshot with a reverse-geocoded address is attached to the notification.

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

1. On push arrival, the notification service extension parses `"31.2304,121.4737"` → coordinates `(31.2304, 121.4737)`
2. Automatically reverse-geocodes and **appends the formatted address** (e.g. "Nanjing East Road, Huangpu, Shanghai") to the notification body
3. Generates a map snapshot image (with a pin marker) as a **notification attachment**
4. When the message is saved, `location` is stored in the `other` JSON field
5. The message card shows a 🗺️ map button at the bottom. Tapping it opens Apple Maps for navigation

#### Coordinate Format

| Rule | Description |
|------|------|
| Format | `latitude,longitude`, separated by a comma |
| Latitude range | `-90.0` ~ `90.0` |
| Longitude range | `-180.0` ~ `180.0` |
| Auto-correction | If lat/lng are swapped (longitude exceeds ±90), the App swaps them back automatically |

#### Supported Templates

| Template | Map Button |
|------|----------|
| `PlainMessageCard` | ✅ Shows 🗺️ map button at the bottom |
| `MarkdownMessageCard` | ❌ Not read |
| `TerminalMessageCard` | ❌ Not read |
| `GitHubMessageCard` | ❌ Not read |
| `PaymentMessageCard` | ❌ Not read |

---

### Mode 2: Callback Retrieval (Location Push)

Pass a callback URL. The server sends an **Apple Location Push** (silent push) to the device. The device fetches its current GPS location in the background and POSTs the coordinates back to your callback URL. **This mode does not show any notification on the device.**

#### Prerequisites

The device must have registered a Location Push Token via the App. On launch, the App automatically calls `startMonitoringLocationPushes` to obtain the token and uploads it to the server during registration (as the `location` field).

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

| Callback Field | Type | Description |
|----------|------|------|
| `title` | `String?` | The original `title` from the push request |
| `subTitle` | `String?` | The original `subtitle` from the push request |
| `body` | `String?` | The original `body` from the push request |
| `location` | `String` | The device's current GPS coordinates in `"lat,lng"` format |

> **Note**: The callback field is named `subTitle` (camelCase), which differs from the push API's `subtitle`.

#### Callback Retries

The device retries up to **3 times**. On network errors it will automatically retry until it succeeds or the retry limit is reached.

#### Apple Restrictions

Location Push is subject to Apple platform limitations:

| Restriction | Description |
|--------|------|
| Rate limit | At most **3 times per hour**; excess pushes are silently dropped by the system |
| Validity | Location Push is retained by APNs for **10 minutes** |
| User authorization | The device must have granted "Always Allow" location permission |
| Low Power Mode | May be delayed or denied in Low Power Mode |
| Silent | No notification is displayed — fully silent location retrieval |

---

### Mode Comparison

| | Direct Coordinates | Callback Retrieval |
|----|----------|----------|
| `location` value | `"31.2304,121.4737"` | `"https://your-server.com/callback"` |
| Server PushType | Standard push (`1`) | Location Push (`2`) |
| Shows notification | ✅ Yes | ❌ Silent |
| Device behavior | Shows map button + notification attachment | Background GPS → POST callback |
| Map button | ✅ | ❌ (no message card produced) |
| Use case | Telling the user a known location | Querying the device's actual current location |
| Requires Location Token | ❌ | ✅ (auto-registered by the App) |

---

## Template Overview

| style Value | Template | Description |
|----------|------|------|
| Not set / other | `PlainMessageCard` | Default card, suitable for general notifications |
| `markdown` | `MarkdownMessageCard` | Rich text card with Markdown rendering |
| `terminal` | `TerminalMessageCard` | Terminal / CLI style, suitable for ops & monitoring |
| `github` | `GitHubMessageCard` | GitHub event style, suitable for code / CI notifications |
| `pay` | `PaymentMessageCard` | Payment / billing notification card |

---

## 1. PlainMessageCard (Default)

**Trigger:** `style` not set or doesn't match any other template

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

### Fields Used

| Field | Usage | Required |
|------|------|------|
| `title` | Main title (**headline**, bold) | - |
| `subtitle` | Subtitle (subheadline, with letter spacing) | - |
| `body` | Body text, up to 5 lines | ✅ |
| `image` | Top banner image | - |
| `icon` | Bottom avatar | - |
| `group` | Bottom group name | ✅ |
| `url` | Shows 🔗 link button | - |
| `location` | Coordinates `"lat,lng"` shows 🗺️ map button. See [📍 Location](#-location) | - |

### Extension Fields (`other` JSON)

This template does not read the `other` JSON field.

### Code Examples

```swift
// id, createDate, read are auto-generated by the system
Message(
    group: "Work",
    title: "Weekly Report Updated",
    subtitle: "Q3 Week 1",
    body: "This week we completed the homepage redesign and search optimization. See the weekly report for details.",
    url: "https://wiki.example.com/weekly",
    ttl: 3600
    // style not set → uses default template
)
```

**Via Push API:**

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

## 2. MarkdownMessageCard

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

### Fields Used

| Field | Usage | Required |
|------|------|------|
| `title` | Title (supports search highlight) | - |
| `subtitle` | Subtitle (supports search highlight) | - |
| `body` | **Markdown** body content | ✅ |
| `image` | Inline image | - |
| `icon` | Bottom avatar | - |
| `group` | Bottom group name (controlled by `showGroup` config) | ✅ |
| `url` | Shows network icon button, opens in Safari on tap | - |

### No Extension Fields

This template does not read the `other` JSON field.

### Code Example

```swift
// id, createDate, read are auto-generated by the system
Message(
    group: "Docs",
    title: "NoLet User Guide",
    body: """
    # Quick Start
    ## Installation
    Search for **NoLet** in the App Store and download.
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

## 3. TerminalMessageCard

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

### Fields Used

| Field | Usage | Required |
|------|------|------|
| `title` | Terminal command (shown as `$ title`) | - |
| `subtitle` | Terminal output prefix (shown as `>> [subtitle]`) | - |
| `body` | Terminal output body (gray code background) | ✅ |
| `image` | Image | - |
| `icon` | Bottom avatar | - |
| `group` | Bottom group name | ✅ |
| `url` | Shows LINK button | - |

### Extension Fields (`other` JSON)

| Key | Type | Options | Description |
|-----|------|--------|------|
| `severity` | `String` | `"success"` (default green), `"warning"` (orange), `"error"` / `"alert"` / `"system"` (red) | Controls the `$` symbol color, TTL ring color, and card border color |

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

## 4. GitHubMessageCard

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
  ↑ Left bar color varies with severity
```

### Fields Used

| Field | Usage | Required |
|------|------|------|
| `title` | PR / Commit title | - |
| `subtitle` | Description / summary | - |
| `body` | Body content (code diff, logs etc.), shown on gray background | - |
| `group` | Group name, shown on the right side of the header | ✅ |
| `url` | Shows LINK button | - |

### Extension Fields (`other` JSON)

| Key | Type | Default | Description |
|-----|------|--------|------|
| `severity` | `String` | `"EVENT"` | Severity level, controls left bar and label color: `"INFO"` (blue), `"SUCCESS"` (green), `"WARN"` (orange), `"CRIT"` (red) |
| `header` | `String` | `"GITHUB"` | Top-left header text (e.g. `"GITHUB/REPO"`) |
| `branch` | `String` | `"main"` | Branch name, shown as a label (e.g. `"main <- jwt-auth"`) |
| `from` | `String` | - | Source URL. The host is extracted and displayed automatically |
| `footer` | `String` | - | Footer note (monospaced, e.g. `"SHA:abc123"`) |

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

## 5. PaymentMessageCard

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

### Fields Used

| Field | Usage | Required |
|------|------|------|
| `title` | Notification title (e.g. "Payment Confirmed", "Payment Received") | - |
| `subtitle` | **Amount**, shown in large text on the right (e.g. `"-$6,799.00"`). Color varies by platform | - |
| `body` | Merchant / transaction description | ✅ |
| `icon` | Platform icon URL (favicon recommended) | - |
| `group` | **Payment platform identifier**, determines brand color (see supported list below) | ✅ |
| `url` | "Open Link" button | - |
| `ttl` | Time to live. TTL progress bar counts down at the bottom | ✅ |

### Extension Fields (`other` JSON)

| Key | Type | Description |
|-----|------|------|
| `ticket` | `String` | Order number / ticket number, shown in the middle of the card |

### `group` Supported Payment Platforms

| Value | Platform | Brand Color |
|----|------|--------|
| `alipay` / `支付宝` | Alipay | Blue `#128EFA` |
| `wechat` / `wechat pay` / `微信支付` | WeChat Pay | Green `#07C160` |
| `paypal` | PayPal | Dark Blue `#003087` |
| `stripe` | Stripe | Purple-Blue `#635BFF` |
| `applepay` / `apple pay` | Apple Pay | System primary |
| `googlepay` / `google pay` | Google Pay | Blue `#4285F4` |
| `visa` | Visa | Dark Blue `#1A1F71` |
| `mastercard` / `master` | Mastercard | Orange `#FF5F00` |
| `amex` / `american express` | American Express | Blue `#016FD0` |
| `unionpay` / `银联` | China UnionPay | Teal `#00796B` |
| `linepay` / `line pay` | LINE Pay | Green `#06C755` |
| `klarna` | Klarna | Pink `#FFB3C7` |
| `paytm` | Paytm | Light Blue `#00BAF2` |
| `discover` | Discover | Orange `#E55C20` |
| `jcb` | JCB | Dark Blue `#00377B` |
| `samsungpay` / `samsung pay` | Samsung Pay | Blue `#1428A0` |
| `ideal` | iDEAL | Magenta `#CC0066` |
| `bancontact` | Bancontact | Black `#000000` |
| `giropay` | Giropay | Blue `#005A9B` |
| Other values | Custom | Purple fallback |

### Code Examples

```swift
// Alipay deduction notification (id, createDate, read are auto-generated)
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
    body: "QR code payment received",
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

In `TemplateHandler.swift`, `MessageCardView` automatically selects a template based on `message.style`:

```swift
switch message.style?.lowercased() {
case "markdown":  MarkdownMessageCard(...)
case "terminal":  TerminalMessageCard(...)
case "github":    GitHubMessageCard(...)
case "pay":       PaymentMessageCard(...)
default:          PlainMessageCard(...)
}
```

If `style` is not set or doesn't match any known template, `PlainMessageCard` is used as the default.

---

## Shared Interactions

All templates share the following interactions (injected uniformly by `MessageInteractiveModifier`):

| Interaction | Action |
|------|------|
| **Double-tap** | Full-screen message detail view |
| **Tap time** | Tap the relative timestamp on the card (e.g. "Just now", "5 min ago") to show an action menu: Copy Content, Share Screenshot, Share Image, Share Text, Reply, Smart Assistant, Delete |
| **TTL** | Message auto-disappears on expiry. A ring or bar countdown is shown on the card |
| **Reply** | If the `reply` field is set, a reply input field appears at the bottom |
| **Screenshot Share** | Card screenshots can be generated for sharing |
