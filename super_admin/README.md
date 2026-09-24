# MADEALS Super Admin

Standalone Super Admin web system for the **MADEALS** Zimbabwe P2P marketplace.

- **Frontend:** HTML5, vanilla CSS (CSS variables), vanilla JS (ES6+) — no build tools, no frameworks
- **Backend:** PHP 8.x (PDO prepared statements, procedural with light OOP)
- **Database:** MySQL 8.x
- **Security:** `password_hash()` / `password_verify()`, hardened sessions, CSRF on every POST, PDO prepared statements everywhere, `htmlspecialchars` output escaping, HTTP-only cookies

> This directory is fully standalone. It does not touch the Flutter app (`lib/`, `pubspec.yaml`, `android/`, `ios/`, …). The Flutter app later syncs with the same MySQL database via `api/v1/`.

---

## 1. Requirements

- PHP 8.1+ (8.2 recommended) with PDO MySQL extension
- MySQL 8.x (or MariaDB 10.4+)
- Apache / Nginx / `php -S` local server

## 2. Setup

### 2.1 Create the database and import the schema

**Option A — MySQL CLI:**

```bash
mysql -u root -p < database/schema.sql
```

**Option B — phpMyAdmin:** create a database named `madeals_admin` (utf8mb4 / utf8mb4_unicode_ci), then import `database/schema.sql`.

The schema creates:

| Table             | Purpose                                      |
|-------------------|----------------------------------------------|
| `admin_users`     | Admin accounts (superadmin / moderator)      |
| `users`           | Marketplace end users + verification state   |
| `central_listings`| Central listings synced with the Flutter app |
| `audit_logs`      | Every moderation action with admin + IP      |

### 2.2 Configure

Edit `config/config.php` **or** set environment variables (env wins over defaults):

| Env variable            | Default             | Meaning                        |
|-------------------------|---------------------|--------------------------------|
| `MADEALS_DB_HOST`       | `127.0.0.1`         | MySQL host                     |
| `MADEALS_DB_PORT`       | `3306`              | MySQL port                     |
| `MADEALS_DB_NAME`       | `madeals_admin`     | Database name                  |
| `MADEALS_DB_USER`       | `root`              | MySQL user                     |
| `MADEALS_DB_PASS`       | *(empty)*           | MySQL password                 |
| `MADEALS_BASE_URL`      | `/super_admin`      | Public path to this folder     |
| `MADEALS_DISPLAY_ERRORS`| `1`                 | Set `0` in production          |
| `MADEALS_SECURE_COOKIES`| `0`                 | Set `1` behind HTTPS           |

Apache example (`.htaccess` or vhost):

```apache
SetEnv MADEALS_DB_PASSWORD your_secret
SetEnv MADEALS_SECURE_COOKIES 1
SetEnv MADEALS_DISPLAY_ERRORS 0
```

Nginx + PHP-FPM: pass them via `fastcgi_param` or the `env[]` directive.

### 2.3 Run

**Local dev:**

```bash
cd super_admin
php -S 127.0.0.1:8080
```

Open <http://127.0.0.1:8080/login.php>

**Production:** point your vhost document root at the `super_admin/` folder (or place it under the site root at `/super_admin`). Ensure `config/`, `includes/`, and `database/` are not web-accessible if your server allows it (deny rules recommended).

## 3. Default credentials

| Account            | Username        | Email               | Password       | Role       |
|--------------------|-----------------|---------------------|----------------|------------|
| Primary admin      | `superadmin`    | `admin@madeals.co.zw` | `Madeals@2026!` | superadmin |
| Moderator          | `moderator_tendai` | `tendai@madeals.co.zw` | `Madeals@2026!` | moderator  |
| Moderator          | `moderator_rutendo` | `rutendo@madeals.co.zw` | `Madeals@2026!` | moderator  |

> **Change these passwords immediately in production.**

### Password hash note

The bcrypt hashes in `database/schema.sql` were generated with:

```bash
php -r "echo password_hash('Madeals@2026!', PASSWORD_DEFAULT);"
```

If you need to regenerate (e.g., different password), run:

```bash
php -r "echo password_hash('YourNewPassword', PASSWORD_DEFAULT);"
```

…or use `database/create_hash.php` (kept as a convenience utility):

```bash
php database/create_hash.php
```

Paste the output into the `password_hash` column value in `schema.sql` (or run an `UPDATE` statement). PHP automatically rehashes on next successful login if the algorithm parameters change.

## 4. Pages

| File               | Purpose |
|--------------------|---------|
| `login.php`        | Admin login (CSRF, `password_verify`, session regenerate, delay on failure) |
| `logout.php`       | Destroys session + cookie |
| `index.php`        | Dashboard: live stat cards, regional CSS bar chart, pending queue, recent audit |
| `listings.php`     | Listings table: search, status/category/price filters, pagination, AJAX moderation |
| `users.php`        | Verification queue + user table: verify / reject / suspend / hard ban |
| `audit_logs.php`   | Audit trail: admin, action, target, reason, IP, timestamp + filters + pagination |

All admin pages redirect to `login.php` when there is no session.

## 5. API

### `GET api/v1/listings.php`

Public — returns **active** listings for the Flutter cache.

Query params: `category`, `q`, `limit` (default 50, max 200), `offset`.

```json
{
  "success": true,
  "count": 2,
  "total": 10,
  "listings": [
    {
      "id": "lst_axio_001",
      "title": "Toyota Axio 2013 Automatic",
      "price": 15500.0,
      "category": "vehicles",
      "location": "Harare, Borrowdale",
      "latitude": -17.734,
      "longitude": 31.067,
      "description": "...",
      "images": ["https://..."],
      "seller_phone": "+263771000101",
      "is_verified": true,
      "is_featured": true,
      "status": "active",
      "created_at": "2026-09-10 08:15:00"
    }
  ]
}
```

### `POST api/v1/listings.php`

Public — creates a listing from mobile (no auth; validated + honeypot checks).

```json
{
  "title": "iPhone 14 Pro",
  "price": 950,
  "category": "electronics",
  "location": "Harare, Avondale",
  "latitude": -17.783,
  "longitude": 31.048,
  "description": "Clean, boxed",
  "images": ["https://cdn/img1.jpg"],
  "seller_phone": "+263771000101"
}
```

Returns `201` with the created record, or `422` with an `errors` object.

### `POST api/v1/admin/moderate.php`

Requires admin session + `X-CSRF-Token` header (or `csrf_token` form field).

```json
{ "action": "hide", "target_id": "lst_axio_001", "reason": "Duplicate" }
```

| Group   | Actions |
|---------|---------|
| Listing | `feature`, `unfeature`, `approve`, `hide`, `delete` |
| User    | `verify`, `reject`, `suspend`, `ban` (`target_id` = numeric user id) |

Status codes: `200` OK · `401` not logged in · `403` bad CSRF/role · `404` target missing · `422` bad action/params · `405` wrong method · `500` server error.

Every successful action inserts a row into `audit_logs` with the real client IP.

## 6. Security checklist

- [x] All SQL via PDO prepared statements — no string interpolation
- [x] CSRF token on every POST (forms: hidden `csrf_token`; AJAX: `X-CSRF-Token` header)
- [x] `password_hash()` / `password_verify()` + automatic rehash
- [x] Session cookie: HTTP-only, SameSite=Lax, session id regenerated on login
- [x] Output escaped with `e()` / `htmlspecialchars`
- [x] Login failure delay (250–600 ms random) to slow brute force
- [x] Pagination capped at 20/page; API `limit` capped at 200

## 7. File tree

```
super_admin/
├── README.md
├── database/
│   ├── schema.sql
│   └── create_hash.php
├── config/
│   └── config.php
├── includes/
│   ├── db.php
│   ├── auth.php
│   ├── helpers.php
│   ├── header.php
│   └── footer.php
├── assets/
│   ├── css/style.css
│   └── js/app.js
├── login.php
├── logout.php
├── index.php
├── listings.php
├── users.php
├── audit_logs.php
└── api/
    └── v1/
        ├── listings.php
        └── admin/
            └── moderate.php
```
