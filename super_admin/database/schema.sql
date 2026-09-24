-- MADEALS Super Admin — MySQL 8.x Schema
-- Import with: mysql -u root -p < database/schema.sql
-- Or in phpMyAdmin, select the database first then import this file.

CREATE DATABASE IF NOT EXISTS madeals_admin
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE madeals_admin;

-- ---------------------------------------------------------------------------
-- 1. admin_users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_users (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  username      VARCHAR(50)  NOT NULL,
  email         VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('superadmin','moderator') NOT NULL DEFAULT 'superadmin',
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admin_username (username),
  UNIQUE KEY uq_admin_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2. users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  display_name        VARCHAR(100) NOT NULL,
  phone               VARCHAR(20)  NOT NULL,
  avatar_url          VARCHAR(512) NULL,
  trust_score         INT          NOT NULL DEFAULT 55,
  verification_status ENUM('unverified','pending','verified','rejected') NOT NULL DEFAULT 'unverified',
  id_document_url     VARCHAR(512) NULL,
  selfie_url          VARCHAR(512) NULL,
  is_suspended        TINYINT(1)   NOT NULL DEFAULT 0,
  is_banned           TINYINT(1)   NOT NULL DEFAULT 0,
  region              VARCHAR(50)  NOT NULL DEFAULT 'Harare',
  created_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_phone (phone),
  KEY idx_users_verification (verification_status),
  KEY idx_users_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3. central_listings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS central_listings (
  id           VARCHAR(64)   NOT NULL,
  title        VARCHAR(255)  NOT NULL,
  price        DECIMAL(10,2) NOT NULL,
  category     VARCHAR(50)   NOT NULL,
  location     VARCHAR(100)  NOT NULL,
  latitude     DOUBLE        NOT NULL,
  longitude    DOUBLE        NOT NULL,
  description  TEXT          NULL,
  image_url    TEXT          NULL,
  seller_phone VARCHAR(20)   NULL,
  user_id      INT UNSIGNED  NULL,
  status       ENUM('active','flagged','hidden','removed_by_admin') NOT NULL DEFAULT 'active',
  is_featured  TINYINT(1)    NOT NULL DEFAULT 0,
  is_verified  TINYINT(1)    NOT NULL DEFAULT 0,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_listings_status (status),
  KEY idx_listings_category (category),
  KEY idx_listings_location (location),
  KEY idx_listings_user (user_id),
  CONSTRAINT fk_listings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. audit_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  admin_id    INT UNSIGNED NOT NULL,
  action      VARCHAR(100) NOT NULL,
  target_id   VARCHAR(64)  NOT NULL,
  reason      TEXT         NULL,
  ip_address  VARCHAR(45)  NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_admin (admin_id),
  KEY idx_audit_action (action),
  KEY idx_audit_created (created_at),
  CONSTRAINT fk_audit_admin FOREIGN KEY (admin_id) REFERENCES admin_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===========================================================================
-- SEED DATA
-- ===========================================================================

-- Admin users
-- Password for ALL seeded accounts: Madeals@2026!
-- Hash generated via: php -r "echo password_hash('Madeals@2026!', PASSWORD_DEFAULT);"
INSERT INTO admin_users (username, email, password_hash, role, is_active) VALUES
('superadmin', 'admin@madeals.co.zw', '$2y$10$Uxig/PMEwq0M0c.isWV/w.OxZxqq07r4qNSRxmUYVW6ZGd4NP6g.a', 'superadmin', 1),
('moderator_tendai', 'tendai@madeals.co.zw', '$2y$10$Uxig/PMEwq0M0c.isWV/w.OxZxqq07r4qNSRxmUYVW6ZGd4NP6g.a', 'moderator', 1),
('moderator_rutendo', 'rutendo@madeals.co.zw', '$2y$10$Uxig/PMEwq0M0c.isWV/w.OxZxqq07r4qNSRxmUYVW6ZGd4NP6g.a', 'moderator', 1);

-- Users
INSERT INTO users (display_name, phone, avatar_url, trust_score, verification_status, id_document_url, selfie_url, is_suspended, is_banned, region) VALUES
('Tinashe Moyo',      '+263771000101', 'uploads/avatars/av_1001.jpg', 78, 'verified',   'uploads/ids/id_1001.jpg',     'uploads/selfies/selfie_1001.jpg', 0, 0, 'Harare'),
('Chipo Ncube',       '+263772000102', 'uploads/avatars/av_1002.jpg', 65, 'pending',    'uploads/ids/id_1002.jpg',     'uploads/selfies/selfie_1002.jpg', 0, 0, 'Bulawayo'),
('Farai Chikafu',     '+263773000103', NULL,                           55, 'unverified', NULL,                            NULL,                              0, 0, 'Harare'),
('Rutendo Marima',    '+263774000104', 'uploads/avatars/av_1004.jpg', 82, 'verified',   'uploads/ids/id_1004.jpg',     'uploads/selfies/selfie_1004.jpg', 0, 0, 'Mutare'),
('Kudzai Phiri',      '+263775000105', NULL,                           40, 'rejected',   'uploads/ids/id_1005.jpg',     'uploads/selfies/selfie_1005.jpg', 1, 0, 'Bulawayo'),
('Nyasha Sibanda',    '+263776000106', 'uploads/avatars/av_1006.jpg', 60, 'pending',    'uploads/ids/id_1006.jpg',     'uploads/selfies/selfie_1006.jpg', 0, 0, 'Harare');

-- Central listings
INSERT INTO central_listings (id, title, price, category, location, latitude, longitude, description, image_url, seller_phone, user_id, status, is_featured, is_verified, created_at) VALUES
('lst_axio_001',  'Toyota Axio 2013 Automatic',            15500.00, 'vehicles',  'Harare, Borrowdale',   -17.7340, 31.0670, 'Clean title, low mileage, A/C working. Imported direct from Japan. Comes with spare key.', 'https://example.com/img/axio1.jpg,https://example.com/img/axio2.jpg', '+263771000101', 1, 'active', 1, 1, '2026-09-10 08:15:00'),
('lst_hfit_002',  'Honda Fit Shuttle 2011',                 9800.00,  'vehicles',  'Bulawayo, Belmont',    -20.1320, 28.6260, 'Fuel efficient family wagon. New tyres, recent service. Negotiable for serious buyer.',      'https://example.com/img/fit1.jpg,https://example.com/img/fit2.jpg',                                        '+263772000102', 2, 'active', 0, 1, '2026-09-11 10:30:00'),
('lst_iph13_003','iPhone 13 128GB Unlocked',              750.00,   'electronics','Harare, Avondale',     -17.7830, 31.0480, 'Excellent condition, battery health 91%. Face ID working. Includes box and cable.',         'https://example.com/img/iph13.jpg',                                                                        '+263773000103', 3, 'active', 1, 1, '2026-09-12 14:05:00'),
('lst_s22u_004', 'Samsung Galaxy S22 Ultra 256GB',        900.00,   'electronics','Bulawayo, Parklands',  -20.1450, 28.6120, 'S-Pen included, no scratches, screen protector on since day one.',                          'https://example.com/img/s22u1.jpg,https://example.com/img/s22u2.jpg',                                      '+263774000104', 4, 'active', 0, 1, '2026-09-12 16:40:00'),
('lst_inv_005',  '5kVA Pure Sine Wave Solar Inverter',     650.00,   'electronics','Mutare, Sakubva',      -18.9350, 32.6300, 'Brand new, 12-month warranty. Handles fridge, TV, lights. Installation available in Mutare.', 'https://example.com/img/inverter.jpg',                                                                      '+263771000101', 1, 'flagged', 0, 0, '2026-09-13 09:10:00'),
('lst_mba_006',  'MacBook Air M1 2020 8/256',             1100.00,  'electronics','Harare, Mount Pleasant',-17.7920, 31.0710, 'Cycle count 240, always on charger protection. Comes with original 30W adapter.',           'https://example.com/img/mba1.jpg,https://example.com/img/mba2.jpg',                                        '+263775000105', 5, 'active', 0, 1, '2026-09-13 11:25:00'),
('lst_stand_007','Stand for Sale — Msasa Park 800m2',     45000.00, 'property',  'Harare, Msasa Park',   -17.8050, 31.0950, 'Title deeds available, ready for transfer. Water and electricity on site. Council rates paid.', 'https://example.com/img/stand1.jpg',                            '+263772000102', 2, 'active', 1, 1, '2026-09-14 07:50:00'),
('lst_room_008','Room to Rent — Mbare (furnished)',       120.00,   'property',  'Harare, Mbare',        -17.8580, 31.0640, 'Secure gated house, wifi included, water tank backup. Monthly payment in advance.',          'https://example.com/img/room1.jpg',                             '+263773000103', 3, 'active', 0, 0, '2026-09-14 13:00:00'),
('lst_fridge_009','Hisense 312L Fridge Freezer',          380.00,   'home',      'Bulawayo, Nkulumane',  -20.1620, 28.5900, 'Bought last year, works perfectly, selling because of relocation.',                         'https://example.com/img/fridge.jpg',                            '+263774000104', 4, 'flagged', 0, 0, '2026-09-15 15:35:00'),
('lst_bike_010', 'Honda CG125 Motorbike 2019',            1300.00,  'vehicles',  'Mutare, CBD',          -18.9770, 32.6300, 'Low km, recently serviced, licence and papers up to date.',                                 'https://example.com/img/bike1.jpg,https://example.com/img/bike2.jpg',                                      '+263776000106', 6, 'active', 0, 1, '2026-09-15 17:20:00'),
('lst_laptop_011','HP EliteBook 840 G6 i7',              620.00,   'electronics','Harare, Eastlea',      -17.7760, 31.0820, 'i7 8th gen, 16GB RAM, 512GB SSD. Perfect for students and office work.',                    'https://example.com/img/eb840.jpg',                             '+263771000101', 1, 'hidden', 0, 0, '2026-09-16 08:45:00'),
('lst_couch_012','Leather 3-Seater Couch',               450.00,   'home',      'Bulawayo, Hillcrest',  -20.1210, 28.5750, 'Genuine leather, brown, minor wear on left arm. Buyer to collect.',                          'https://example.com/img/couch.jpg',                             '+263775000105', 5, 'active', 0, 0, '2026-09-16 12:10:00');

-- Audit logs
INSERT INTO audit_logs (admin_id, action, target_id, reason, ip_address, created_at) VALUES
(1, 'listing_feature',   'lst_axio_001',  'Featured weekly deal',            '127.0.0.1',        '2026-09-10 08:20:00'),
(1, 'listing_flag',      'lst_inv_005',   'Possible scam — no contact match','41.203.12.45',     '2026-09-13 09:30:00'),
(2, 'user_verify',       '1',             'ID and selfie match profile',     '102.184.67.20',    '2026-09-11 11:05:00'),
(1, 'listing_hide',      'lst_laptop_011','Duplicate listing detected',      '127.0.0.1',        '2026-09-16 09:00:00'),
(3, 'user_suspend',      '5',             'Repeated rejected verifications', '197.221.9.88',     '2026-09-15 16:40:00');
