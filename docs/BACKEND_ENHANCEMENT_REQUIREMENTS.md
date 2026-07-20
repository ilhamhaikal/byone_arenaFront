# Backend Enhancement Requirements — Byone Arena

> **Tanggal**: 2026-07-20 (updated setelah backend fix)  
> **Audience**: Backend Developer (Go)  
> **Status**: ✅ Bug FK fixed — 🟡 Field baru & response enhancement pending

---

## 1. 🐛 Bug Fix — ✅ RESOLVED

### 1.1 Rental Harian — FK Constraint Error

**Endpoint**: `POST /api/v1/daily-rentals`

**Status**: ✅ **SUDAH DIPERBAIKI** — Backend tidak lagi insert ke tabel `payments` saat membuat rental harian.

**Request body yang digunakan frontend**:
```json
{
  "consoleId": "uuid",
  "customerId": "uuid | null",
  "startDate": "2026-07-20",
  "endDate": "2026-07-23",
  "dailyPrice": 15000,
  "deposit": 50000,
  "notes": "opsional"
}
```

---

## 2. 🆕 Field Baru pada Console — 🟡 PENDING

### 2.1 `dailyPrice` — Harga Sewa Harian

**Deskripsi**: Harga sewa per hari untuk rental harian (console dibawa pulang). Berbeda dengan `pricePerHour` yang digunakan untuk sewa per jam di tempat.

**Schema**:
```sql
ALTER TABLE consoles ADD COLUMN daily_price DECIMAL(10,2) DEFAULT 0;
```

**Contoh nilai**: `15000` (Rp 15.000/hari)

**Endpoint yang perlu diupdate**:
| Endpoint | Perubahan |
|---|---|
| `GET /consoles` | Tambah field `dailyPrice` di response |
| `GET /consoles/{id}` | Tambah field `dailyPrice` di response |
| `POST /consoles` | Terima field `dailyPrice` di request body |
| `PUT /consoles/{id}` | Terima field `dailyPrice` di request body |
| `GET /consoles/overview` | Tambah field `dailyPrice` di response (untuk client display) |

### 2.2 `lastSeenAt` — Heartbeat Tracking

**Deskripsi**: Timestamp terakhir TV Android mengirim heartbeat. Digunakan untuk indikator Online/Offline di admin panel.

**Schema**:
```sql
ALTER TABLE consoles ADD COLUMN last_seen_at TIMESTAMP NULL;
```

**Endpoint yang perlu diupdate**:
| Endpoint | Perubahan |
|---|---|
| `GET /consoles` | Tambah field `lastSeenAt` (nullable) |
| `GET /consoles/overview` | Tambah field `lastSeenAt` (nullable) |
| `POST /consoles/{id}/heartbeat` | 🆕 Endpoint baru untuk TV heartbeat |

### 2.3 Endpoint Heartbeat (Baru)

```
POST /api/v1/consoles/{id}/heartbeat
```

**Auth**: Device token (bukan JWT, untuk TV embedded)

**Response**:
```json
{ "ok": true }
```

**Server action**: Update `consoles.last_seen_at = NOW()`

---

## 3. 📦 Booking — Perbaikan Response

### 3.1 Booking Response Perlu Mengembalikan Object

**Endpoint**: `POST /api/v1/bookings`

**Masalah**: Response saat ini mengembalikan `data: {}` (generic object). Frontend perlu data booking yang lengkap untuk ditampilkan di list.

**Response yang diharapkan**:
```json
{
  "success": true,
  "message": "Booking berhasil dibuat",
  "data": {
    "id": "uuid",
    "consoleId": "uuid",
    "customerId": "uuid | null",
    "bookingDate": "2026-07-21",
    "startHour": 10,
    "startMinute": 0,
    "durationMinutes": 60,
    "status": "pending",
    "notes": "opsional",
    "createdAt": "2026-07-20T...",
    "updatedAt": "2026-07-20T...",
    "console": {
      "name": "PS5 #1",
      "consoleType": "PS5"
    },
    "customer": {
      "name": "Budi"
    }
  }
}
```

**Endpoint yang perlu update response serupa**:
- `PATCH /bookings/{id}/status` — harus mengembalikan data booking yang sudah diupdate
- `GET /bookings` — sudah OK, mengembalikan array

### 3.2 Booking Status Endpoint

**Endpoint**: `PATCH /api/v1/bookings/{id}/status?status=xxx`

**Status yang didukung**: `confirmed`, `cancelled`, `completed`

**Validasi**:
- `pending` → `confirmed` atau `cancelled`
- `confirmed` → `completed` atau `cancelled`
- `cancelled` / `completed` → tidak bisa diubah lagi

---

## 4. 📦 Rental Harian — Perbaikan Response

### 4.1 Response Body

**Endpoint**: `POST /api/v1/daily-rentals` dan `POST /daily-rentals/{id}/return`

**Masalah**: Response mengembalikan `data: {}` (generic). Frontend perlu data rental lengkap.

**Response yang diharapkan** (sama seperti GET /daily-rentals):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "consoleId": "uuid",
    "customerId": "uuid | null",
    "startDate": "2026-07-20",
    "endDate": "2026-07-23",
    "totalDays": 3,
    "dailyPrice": 15000,
    "depositAmount": 50000,
    "totalAmount": 45000,
    "status": "active",
    "notes": "opsional",
    "returnedAt": null,
    "createdAt": "...",
    "updatedAt": "...",
    "console": {
      "name": "PS5 #1",
      "consoleType": "PS5"
    },
    "customer": {
      "name": "Budi"
    }
  }
}
```

### 4.2 Auto-set Status Overdue

**Deskripsi**: Rental dengan status `active` yang sudah melewati `endDate` seharusnya otomatis berstatus `overdue`.

**Implementasi**: Background job / cron setiap jam:
```sql
UPDATE daily_rentals
SET status = 'overdue', updated_at = NOW()
WHERE status = 'active' AND end_date < CURRENT_DATE;
```

---

## 5. 📊 Ringkasan Semua Endpoint Frontend

### Yang SUDAH digunakan frontend:
| Endpoint | Method | Status |
|---|---|---|
| `/auth/login` | POST | ✅ OK |
| `/auth/register` | POST | ✅ OK |
| `/consoles` | GET/POST | ✅ OK |
| `/consoles/available` | GET | ✅ OK |
| `/consoles/overview` | GET | ✅ OK |
| `/consoles/{id}` | GET/PUT/DELETE | ✅ OK |
| `/consoles/{id}/price` | GET | ✅ OK |
| `/consoles/{id}/sleep` | POST | ✅ OK |
| `/consoles/{id}/wake` | POST | ✅ OK |
| `/customers` | GET/POST | ✅ OK |
| `/customers/{id}` | GET/PUT/DELETE | ✅ OK |
| `/sessions` | GET | ✅ OK |
| `/sessions/active` | GET | ✅ OK |
| `/sessions/start` | POST | ✅ OK |
| `/sessions/{id}` | GET | ✅ OK |
| `/sessions/{id}/end` | PATCH | ✅ OK |
| `/sessions/{id}/cancel` | PATCH | ✅ OK |
| `/sessions/{id}/extend` | POST | ✅ OK |
| `/dashboard/summary` | GET | ✅ OK |
| `/discounts` | GET/POST | ✅ OK |
| `/discounts/active` | GET | ✅ OK |
| `/discounts/{id}` | GET/PUT/DELETE | ✅ OK |
| `/discounts/{id}/toggle` | PATCH | ✅ OK |
| `/food-orders` | GET/POST | ✅ OK |
| `/food-orders/{id}` | GET/DELETE | ✅ OK |
| `/food-orders/{id}/cancel` | PATCH | ✅ OK |
| `/food-orders/{id}/status` | PATCH | ✅ OK |
| `/menus` | GET/POST | ✅ OK |
| `/menus/{id}` | GET/PUT/DELETE | ✅ OK |
| `/menus/{id}/toggle` | PATCH | ✅ OK |
| `/menus/available` | GET | ✅ OK |
| `/notifications` | GET/POST | ✅ OK |
| `/notifications/{id}` | PUT/DELETE | ✅ OK |
| `/notifications/{id}/toggle` | PATCH | ✅ OK |
| `/notifications/loop/start` | POST | ✅ OK |
| `/notifications/loop/stop` | POST | ✅ OK |
| `/notifications/loop/status` | GET | ✅ OK |
| `/payments` | POST | ✅ OK |
| `/payments/{id}` | GET | ✅ OK |
| `/payments/{id}/confirm` | POST | ✅ OK |
| `/payments/{id}/refund` | PATCH | ✅ OK |
| `/reports/summary` | GET | ✅ OK |
| `/shifts` | GET/POST | ✅ OK |
| `/shifts/{id}` | GET/PUT/DELETE | ✅ OK |
| `/vouchers` | GET/POST | ✅ OK |
| `/vouchers/code/{code}` | GET | ✅ OK |
| `/vouchers/{id}` | GET/PUT/DELETE | ✅ OK |
| `/vouchers/{id}/toggle` | PATCH | ✅ OK |

### Yang BARU (perlu response body lengkap):
| Endpoint | Method | Status |
|---|---|---|
| `/bookings` | GET/POST | ✅ OK (GET), 🔧 response POST perlu data lengkap |
| `/bookings/{id}/status` | PATCH | 🔧 response perlu data booking terupdate |
| `/daily-rentals` | GET/POST | ✅ OK (GET), 🐛 POST bug FK + 🔧 response |
| `/daily-rentals/{id}/return` | POST | 🔧 response perlu data rental terupdate |

### Yang BELUM diimplementasi backend (opsional):
| Endpoint | Deskripsi |
|---|---|
| `POST /consoles/{id}/heartbeat` | Heartbeat dari TV Android |
| `GET /consoles/{id}/tv-status` | Polling status TV (LOCK/UNLOCK) |

---

## 6. 📝 Prioritas (Updated)

| # | Item | Severity | Status |
|---|---|---|---|
| 1 | 🐛 Bug FK `payments_session_id_fkey` | **CRITICAL** | ✅ FIXED |
| 2 | 🔧 Response `POST /bookings` + `POST /daily-rentals` | **HIGH** | 🟡 PENDING |
| 3 | 🔧 Response `PATCH /bookings/{id}/status` | **HIGH** | 🟡 PENDING |
| 4 | 🔧 Response `POST /daily-rentals/{id}/return` | **HIGH** | 🟡 PENDING |
| 5 | 🆕 Field `dailyPrice` di Console | **MEDIUM** | 🟡 PENDING |
| 6 | 🆕 Field `lastSeenAt` + heartbeat endpoint | **LOW** | 🟡 PENDING |
| 7 | 🆕 Endpoint `GET/PUT /api/v1/settings/membership` | **HIGH** | ✅ DONE (2026-07-20) |
| 8 | 🆕 Endpoint `POST /api/v1/customers/{id}/membership` | **HIGH** | ✅ DONE (2026-07-20) |

---

## 7. 📊 Status Frontend vs Backend

| Fitur Frontend | Backend Endpoint | Status |
|---|---|---|
| Dashboard | Semua endpoint existing | ✅ OK |
| Rental (sesi) | `/sessions/*` | ✅ OK |
| Konsol | `/consoles/*` | ✅ OK |
| Booking | `/bookings/*` | ⚠️ Response POST/PATCH belum mengembalikan data lengkap |
| Rental Harian | `/daily-rentals/*` | ✅ OK (bug FK fixed), ⚠️ Response POST/return belum data lengkap |
| Pricing Tiers | Console `pricingTiers` field | ✅ OK |
| Membership | Customer membership fields | ✅ OK — Flow baru: `POST /customers/{id}/membership` |

---

## 8. 🆕 Membership Price Settings Endpoint — ✅ IMPLEMENTED (2026-07-20)

### 8.1 Latar Belakang

Membership di Byone Arena adalah **LIFETIME** — semua member setara, tidak ada tier (VIP/Gold/Silver), tidak ada tanggal kadaluarsa. Yang perlu di-setting hanya **harga membership**. Frontend saat ini mencatat harga membership per-customer (`membershipPrice`), tapi idealnya backend menyediakan endpoint khusus untuk setting harga membership secara global.

### 8.2 Endpoint yang Dibutuhkan

#### Get Membership Settings

```
GET /api/v1/settings/membership
```

**Auth**: Bearer (admin, superadmin)

**Response**:
```json
{
  "success": true,
  "data": {
    "price": 50000,
    "updatedAt": "2026-07-21T10:00:00Z"
  }
}
```

#### Update Membership Settings

```
PUT /api/v1/settings/membership
```

**Auth**: Bearer (admin, superadmin)  

**Request Body**:
```json
{
  "price": 50000
}
```

**Response**:
```json
{
  "success": true,
  "message": "Harga membership berhasil diperbarui",
  "data": {
    "price": 50000,
    "updatedAt": "2026-07-21T10:05:00Z"
  }
}
```

### 8.3 Schema (tabel baru)

```sql
CREATE TABLE settings (
  key   VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO settings (key, value) VALUES ('membership', '{"price": 0}');
```

### 8.4 Flow Frontend

1. Frontend memanggil `GET /api/v1/settings/membership` untuk mendapatkan harga membership saat ini
2. Admin bisa mengubah harga melalui `PUT /api/v1/settings/membership`
3. Saat frontend membuat/mengupdate customer dengan member aktif, frontend otomatis menggunakan harga dari settings ini
4. Frontend TIDAK lagi menampilkan input harga di form member — harga diambil dari endpoint settings

### 8.5 Prioritas

| # | Item | Severity | Status |
|---|---|---|---|
| 7 | 🆕 Endpoint `GET/PUT /api/v1/settings/membership` | **HIGH** | ✅ DONE |
| 8 | 🆕 Endpoint `POST /api/v1/customers/{id}/membership` | **HIGH** | ✅ DONE |

---

## 9. 📦 Flow Membership — Implementasi Frontend

### Flow Baru

1. **Admin set harga global**: `PUT /api/v1/settings/membership` → `{"membershipPrice": 50000}`
2. **Frontend baca harga**: `GET /api/v1/settings/membership` → tampilkan di halaman membership
3. **Admin jual member**: `POST /api/v1/customers/{id}/membership` → `{}` (body kosong, harga otomatis dari settings)

### File Frontend Terkait

| File | Keterangan |
|---|---|
| `models/membership_settings_model.dart` | Model untuk response GET/PUT settings |
| `services/membership_settings_service.dart` | Service GET/PUT /settings/membership |
| `providers/membership_settings_provider.dart` | State management harga membership |
| `services/customer_service.dart` | Tambah method `sellMembership()` |
| `providers/customer_provider.dart` | Tambah method `sellMembership()` |
| `screens/membership/member_form_dialog.dart` | Tombol "Jual Membership" di form edit |
| `screens/membership/membership_screen.dart` | Banner harga global + "Jual Member" di menu card |

---

> **Note**: Setelah endpoint settings tersedia, frontend akan diupdate untuk consume harga dari endpoint tersebut alih-alih input manual per-customer.
