# Backend TV Control System — Implementation Guide

> **Audience**: Backend Developer (Go)  
> **Purpose**: Document the required server-side features to support real-time Android TV locking/unlocking via the Byone Arena admin console.

---

## Background

Each console entity has a `consoleType` field. Consoles with `consoleType = "AndroidTV"` have an associated Android TV device identified by the `ipAddress` field.

The admin panel (Flutter) controls sessions:
- **Session Start** → TV should **unlock** (show game / allow input)
- **Session End / Cancel** → TV should **lock** (show screensaver, block input)

Currently, the backend transitions `console.status` between `available` ↔ `in_use` correctly, but there is **no mechanism to push commands to the physical TV device**.

---

## Required Features

### 1. TV Command Push (Recommended: HTTP polling from TV)

The simplest approach — the Android TV app polls the backend every few seconds for its current status.

#### Endpoint: `GET /api/v1/consoles/{id}/tv-status`

**Purpose**: The Android TV app calls this endpoint to determine whether to lock or unlock.

**Response**:
```json
{
  "consoleId": "uuid",
  "command": "LOCK" | "UNLOCK",
  "sessionId": "uuid | null"
}
```

**Logic**:
- If `console.status == "in_use"` → return `command: "UNLOCK"`
- If `console.status == "available"` OR `"maintenance"` → return `command: "LOCK"`

**Poll interval recommended**: every 5 seconds from the TV app.

**Auth**: Use a lightweight device token (stored on TV, issued once during setup) instead of JWT Bearer to avoid token expiry issues on embedded devices.

---

### 2. TV Heartbeat (Online Tracking)

#### Endpoint: `POST /api/v1/consoles/{id}/heartbeat`

**Purpose**: Android TV app calls this to indicate it is online and connected.

**Request body**: none (or `{}`)

**Response**:
```json
{ "ok": true }
```

**Server action**: Update `console.last_seen_at = NOW()` in the database.

**Use case in admin**: Display "Online" / "Offline" indicator on the console card based on `last_seen_at < NOW() - 30s`.

**Schema change required**:
```sql
ALTER TABLE consoles ADD COLUMN last_seen_at TIMESTAMP;
```

---

### 3. Manual Admin Lock/Unlock Override

#### Endpoint: `PATCH /api/v1/consoles/{id}/lock`

**Purpose**: Admin manually locks a TV (e.g., player is misbehaving, session not yet started).

**Auth**: JWT Bearer (admin role)

**Response**: `{ "ok": true }`

**Server action**: Set `console.status = "available"` (if currently `in_use`) or leave unchanged. The TV will pick up `LOCK` command on next poll.

---

#### Endpoint: `PATCH /api/v1/consoles/{id}/unlock`

**Purpose**: Admin manually unlocks a TV (e.g., demo mode, testing).

**Auth**: JWT Bearer (admin role)

**Response**: `{ "ok": true }`

**Server action**: Set an internal flag `console.manual_unlock = true`. The TV poll returns `UNLOCK` regardless of session status.

---

### 4. WebSocket Alternative (Advanced)

If sub-second response is needed (e.g., for anti-cheat or premium UX), implement a WebSocket endpoint instead of polling.

#### Endpoint: `ws://host/api/v1/consoles/{id}/ws`

**Flow**:
1. Android TV app opens WebSocket on boot using device token auth.
2. Server maintains a map of `consoleId → wsConnection`.
3. When session starts/ends, server pushes a message to the matching connection.

**Message format (server → TV)**:
```json
{ "command": "LOCK" | "UNLOCK", "sessionId": "uuid | null" }
```

**Message format (TV → server)**:
```json
{ "type": "heartbeat" }
```

**Reconnect**: TV app must implement exponential backoff reconnect (1s → 2s → 4s → max 30s).

> ⚠️ WebSocket requires careful resource management in Go (goroutine per connection). Polling is recommended first unless latency < 1s is required.

---

## Android TV App Requirements

The Android TV app (separate project) must implement:

1. **Boot registration**: On first launch, call `POST /api/v1/consoles/register-device` with `{ "ipAddress": "..." }` to link the device to a console record. Store the returned `consoleId` and `deviceToken` in local storage.

2. **Poll loop**: Every 5 seconds call `GET /api/v1/consoles/{consoleId}/tv-status` using `deviceToken` auth.

3. **LOCK behavior**: Display fullscreen screensaver. Block all input (remote, gamepad). Show "TERSEDIA — Hubungi Admin" message.

4. **UNLOCK behavior**: Hide screensaver. Enable input. Optionally show session timer (remaining minutes from `endScheduledAt`).

5. **Heartbeat**: Every 15 seconds call `POST /api/v1/consoles/{consoleId}/heartbeat`.

---

## Console Entity Schema (Current)

```go
type Console struct {
    ID           uuid.UUID  `json:"id"`
    Name         string     `json:"name"`
    ConsoleType  string     `json:"consoleType"` // PS3, PS4, PS5, AndroidTV
    Status       string     `json:"status"`      // available, in_use, maintenance
    PricePerHour float64    `json:"pricePerHour"`
    IPAddress    *string    `json:"ipAddress"`   // for AndroidTV only
    Description  *string    `json:"description"`
    CreatedAt    time.Time  `json:"createdAt"`
    UpdatedAt    time.Time  `json:"updatedAt"`
}
```

**Proposed additions**:
```go
LastSeenAt    *time.Time `json:"lastSeenAt"`    // heartbeat tracking
ManualUnlock  bool       `json:"manualUnlock"`  // admin override flag
DeviceToken   *string    `json:"-"`             // TV auth, hidden from API response
```

---

## Session Lifecycle → TV Command Mapping

| Event | `console.status` after | TV command |
|---|---|---|
| Admin starts session (`POST /sessions/start`) | `in_use` | `UNLOCK` |
| Admin ends session (`POST /sessions/{id}/end`) | `available` | `LOCK` |
| Admin cancels session (`POST /sessions/{id}/cancel`) | `available` | `LOCK` |
| Admin sets maintenance (`PATCH /consoles/{id}`) | `maintenance` | `LOCK` |
| Manual unlock override | `available` (unchanged) | `UNLOCK` |
| Manual lock override | `in_use` (unchanged) | `LOCK` |

---

## Existing `GET /api/v1/consoles/overview` Endpoint

This endpoint is already implemented and returns all consoles with their active session info. The Flutter admin app polls this every 30 seconds to refresh the control panel.

**No changes needed** to this endpoint — it's already the source of truth for the admin UI.

---

## Recommended Implementation Order

1. ✅ Already done: `GET /consoles/overview` — admin sees all consoles
2. 🔲 Add `last_seen_at` column + `POST /consoles/{id}/heartbeat`
3. 🔲 Add `GET /consoles/{id}/tv-status` (polling endpoint for TV app)
4. 🔲 Add device token auth middleware for TV endpoints
5. 🔲 Build Android TV app with poll loop + LOCK/UNLOCK UI
6. 🔲 (Optional) Add `PATCH /consoles/{id}/lock` + `unlock` for admin override
7. 🔲 (Optional) Replace polling with WebSocket for < 1s latency
