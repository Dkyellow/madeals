<?php
/**
 * MADEALS Super Admin — central configuration.
 * Values load from environment variables first, then fall back to defaults.
 */

declare(strict_types=1);

/* ---------------------------------------------------------------------------
 * Database
 * ------------------------------------------------------------------------ */
define('DB_HOST', getenv('MADEALS_DB_HOST') ?: '127.0.0.1');
define('DB_PORT', getenv('MADEALS_DB_PORT') ?: '3306');
define('DB_NAME', getenv('MADEALS_DB_NAME') ?: 'madeals_admin');
define('DB_USER', getenv('MADEALS_DB_USER') ?: 'root');
define('DB_PASS', getenv('MADEALS_DB_PASS') !== false ? (string)getenv('MADEALS_DB_PASS') : '');
define('DB_CHARSET', 'utf8mb4');

/* ---------------------------------------------------------------------------
 * App / URLs
 * ------------------------------------------------------------------------ */
define('APP_NAME', 'MADEALS Super Admin');
define('BASE_URL', rtrim(getenv('MADEALS_BASE_URL') ?: '/super_admin', '/'));
define('SESSION_NAME', 'madeals_admin_sess');

/* ---------------------------------------------------------------------------
 * Security
 * ------------------------------------------------------------------------ */
// Live in production; set to false only for local HTTP dev if needed.
define('SESSION_SECURE_COOKIE', (bool)(getenv('MADEALS_SECURE_COOKIES') !== false ? filter_var(getenv('MADEALS_SECURE_COOKIES'), FILTER_VALIDATE_BOOLEAN) : false));

/* ---------------------------------------------------------------------------
 * Pagination / limits
 * ------------------------------------------------------------------------ */
define('PER_PAGE', 20);
define('API_DEFAULT_LIMIT', 50);
define('API_MAX_LIMIT', 200);

/* ---------------------------------------------------------------------------
 * Categories (shared by listings page filters + API validation)
 * ------------------------------------------------------------------------ */
define('CATEGORIES', ['vehicles', 'electronics', 'property', 'home', 'fashion', 'services', 'other']);
define('LISTING_STATUSES', ['active', 'flagged', 'hidden', 'removed_by_admin']);

/* ---------------------------------------------------------------------------
 * Error display (override via env in production)
 * ------------------------------------------------------------------------ */
define('DISPLAY_ERRORS', (bool)filter_var(getenv('MADEALS_DISPLAY_ERRORS') !== false ? getenv('MADEALS_DISPLAY_ERRORS') : '1', FILTER_VALIDATE_BOOLEAN));
