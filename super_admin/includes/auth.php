<?php
/**
 * Authentication, CSRF, and audit-log helpers.
 */

declare(strict_types=1);

/**
 * Start a hardened session (idempotent).
 */
function start_secure_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }

    $cookieParams = [
        'lifetime' => 0,
        'path'     => '/',
        'secure'   => SESSION_SECURE_COOKIE,
        'httponly' => true,
        'samesite' => 'Lax',
    ];
    session_set_cookie_params($cookieParams);
    session_name(SESSION_NAME);
    session_start();

    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
}

/**
 * Return (and lazily create) the CSRF token for this session.
 */
function csrf_token(): string
{
    start_secure_session();
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return (string)$_SESSION['csrf_token'];
}

/**
 * Verify a CSRF token. Accepts form field or X-CSRF-Token header.
 * Returns bool; does NOT exit.
 */
function csrf_verify(?string $token = null): bool
{
    start_secure_session();

    if ($token === null || $token === '') {
        $token = $_POST['csrf_token'] ?? $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    }

    $expected = (string)($_SESSION['csrf_token'] ?? '');
    return $expected !== '' && is_string($token) && hash_equals($expected, $token);
}

/**
 * Hard-stop if CSRF verification fails (sends JSON if request looks like AJAX).
 */
function csrf_require(): void
{
    if (!csrf_verify()) {
        json_error('Invalid or missing CSRF token.', 403);
        exit;
    }
}

/**
 * Require a logged-in admin; redirect to login.php for HTML pages,
 * or return 401 JSON for API/AJAX requests.
 */
function require_admin(): array
{
    start_secure_session();

    $admin = current_admin();

    if ($admin === null) {
        $isAjax = (
            strtolower((string)($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '')) === 'xmlhttprequest'
            || str_contains((string)($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')
            || str_contains($_SERVER['REQUEST_URI'] ?? '', '/api/')
        );

        if ($isAjax) {
            json_error('Authentication required.', 401);
            exit;
        }

        header('Location: login.php');
        exit;
    }

    return $admin;
}

/**
 * Return the current admin row (array) or null.
 */
function current_admin(): ?array
{
    start_secure_session();

    if (empty($_SESSION['admin_id'])) {
        return null;
    }

    static $cached = null;
    static $cachedId = null;

    $id = (int)$_SESSION['admin_id'];
    if ($cached !== null && $cachedId === $id) {
        return $cached;
    }

    $stmt = db()->prepare(
        'SELECT id, username, email, role, is_active FROM admin_users WHERE id = :id LIMIT 1'
    );
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch();

    if (!$row || (int)$row['is_active'] !== 1) {
        $cached = null;
        $cachedId = null;
        return null;
    }

    $cached = $row;
    $cachedId = $id;
    return $cached;
}

/**
 * Insert an audit log row. Never throws — audit failures must not break UX.
 *
 * @param array|null $admin Pass current admin array; falls back to session lookup.
 */
function log_audit(string $action, string $targetId, ?string $reason = null, ?array $admin = null): void
{
    try {
        $admin = $admin ?? current_admin();
        if ($admin === null) {
            return;
        }

        $ip = client_ip();
        $stmt = db()->prepare(
            'INSERT INTO audit_logs (admin_id, action, target_id, reason, ip_address)
             VALUES (:admin_id, :action, :target_id, :reason, :ip)'
        );
        $stmt->execute([
            ':admin_id'  => (int)$admin['id'],
            ':action'    => $action,
            ':target_id' => $targetId,
            ':reason'    => $reason,
            ':ip'        => $ip,
        ]);
    } catch (Throwable $e) {
        error_log('[MADEALS audit] ' . $e->getMessage());
    }
}

/**
 * Best-effort client IP.
 */
function client_ip(): string
{
    $candidates = [
        $_SERVER['HTTP_CF_CONNECTING_IP'] ?? null,
        $_SERVER['HTTP_X_FORWARDED_FOR']  ?? null,
        $_SERVER['REMOTE_ADDR']           ?? null,
    ];

    foreach ($candidates as $ip) {
        if (!$ip) {
            continue;
        }
        $ip = trim(explode(',', (string)$ip)[0]);
        if (filter_var($ip, FILTER_VALIDATE_IP)) {
            return $ip;
        }
    }

    return '0.0.0.0';
}

/* ---------------------------------------------------------------------------
 * JSON response helpers (shared by API endpoints)
 * ------------------------------------------------------------------------ */

/**
 * Send a JSON payload with an HTTP status code and exit.
 */
function json_response($data, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Send a JSON error envelope and exit.
 */
function json_error(string $message, int $status = 400, array $extra = []): void
{
    json_response(array_merge([
        'success' => false,
        'message' => $message,
    ], $extra), $status);
}

/**
 * Read and decode a JSON request body.
 */
function read_json_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}
