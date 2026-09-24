<?php
/**
 * Admin moderation endpoint (AJAX/JSON).
 *
 * POST JSON: { action, target_id, reason? }
 * Requires: admin session + valid CSRF (X-CSRF-Token header or csrf_token field).
 *
 * Actions: feature | unfeature | approve | hide | delete   (→ central_listings)
 *          verify | reject | suspend | ban                 (→ users)
 */

declare(strict_types=1);

require_once __DIR__ . '/../../../config/config.php';
require_once __DIR__ . '/../../../includes/db.php';
require_once __DIR__ . '/../../../includes/auth.php';
require_once __DIR__ . '/../../../includes/helpers.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed.', 405);
}

/* 1. Admin session */
$admin = require_admin();

/* 2. CSRF (header preferred; form field fallback) */
$csrfHeader = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($_POST['csrf_token'] ?? null);
if (!csrf_verify(is_string($csrfHeader) ? $csrfHeader : null)) {
    json_error('Invalid or missing CSRF token.', 403);
}

/* 3. Parse payload */
$body = read_json_body();
if (!$body && !empty($_POST)) {
    $body = $_POST;
}

$action   = strtolower(trim((string)($body['action'] ?? '')));
$targetId = trim((string)($body['target_id'] ?? $body['targetId'] ?? ''));
$reason   = isset($body['reason']) && $body['reason'] !== ''
    ? mb_substr(trim((string)$body['reason']), 0, 1000)
    : null;

$listingActions = ['feature', 'unfeature', 'approve', 'hide', 'delete'];
$userActions    = ['verify', 'reject', 'suspend', 'ban'];
$allActions     = array_merge($listingActions, $userActions);

if (!in_array($action, $allActions, true)) {
    json_error('Unknown action.', 422, ['allowed' => $allActions]);
}
if ($targetId === '' || strlen($targetId) > 64) {
    json_error('target_id is required (max 64 chars).', 422);
}

/* 4. Resolve target + apply mutation */
try {
    if (in_array($action, $listingActions, true)) {
        $stmt = db()->prepare('SELECT id, status, is_featured FROM central_listings WHERE id = :id LIMIT 1');
        $stmt->execute([':id' => $targetId]);
        $listing = $stmt->fetch();

        if (!$listing) {
            json_error('Listing not found.', 404);
        }

        switch ($action) {
            case 'feature':
                $upd = db()->prepare('UPDATE central_listings SET is_featured = 1 WHERE id = :id');
                $upd->execute([':id' => $targetId]);
                $message = 'Listing featured.';
                break;

            case 'unfeature':
                $upd = db()->prepare('UPDATE central_listings SET is_featured = 0 WHERE id = :id');
                $upd->execute([':id' => $targetId]);
                $message = 'Listing unfeatured.';
                break;

            case 'approve':
                if ($listing['status'] === 'removed_by_admin' && (string)$admin['role'] !== 'superadmin') {
                    json_error('Only a superadmin can restore a removed listing.', 403);
                }
                $upd = db()->prepare("UPDATE central_listings SET status = 'active' WHERE id = :id");
                $upd->execute([':id' => $targetId]);
                $message = 'Listing approved and set to active.';
                break;

            case 'hide':
                $upd = db()->prepare("UPDATE central_listings SET status = 'hidden' WHERE id = :id");
                $upd->execute([':id' => $targetId]);
                $message = 'Listing hidden.';
                break;

            case 'delete':
                $upd = db()->prepare("UPDATE central_listings SET status = 'removed_by_admin' WHERE id = :id");
                $upd->execute([':id' => $targetId]);
                // Also try hard delete for superadmins? Spec says "Delete" — soft-remove is safer
                // for audit trails; hard delete via second statement below.
                $del = db()->prepare('DELETE FROM central_listings WHERE id = :id');
                $del->execute([':id' => $targetId]);
                $message = 'Listing deleted.';
                break;
        }
    } else {
        /* User actions — target_id is the numeric user id */
        if (!ctype_digit($targetId)) {
            json_error('target_id must be a numeric user id for this action.', 422);
        }

        $stmt = db()->prepare(
            'SELECT id, phone, verification_status, is_suspended, is_banned
             FROM users WHERE id = :id LIMIT 1'
        );
        $stmt->execute([':id' => (int)$targetId]);
        $user = $stmt->fetch();

        if (!$user) {
            json_error('User not found.', 404);
        }

        switch ($action) {
            case 'verify':
                $upd = db()->prepare(
                    "UPDATE users
                     SET verification_status = 'verified',
                         trust_score = GREATEST(trust_score, 70)
                     WHERE id = :id"
                );
                $upd->execute([':id' => (int)$targetId]);
                $message = 'User marked as verified.';
                break;

            case 'reject':
                $upd = db()->prepare(
                    "UPDATE users
                     SET verification_status = 'rejected'
                     WHERE id = :id"
                );
                $upd->execute([':id' => (int)$targetId]);
                $message = 'ID verification rejected.';
                break;

            case 'suspend':
                $upd = db()->prepare('UPDATE users SET is_suspended = 1 WHERE id = :id');
                $upd->execute([':id' => (int)$targetId]);
                $message = 'User suspended.';
                break;

            case 'ban':
                $upd = db()->prepare(
                    'UPDATE users SET is_banned = 1, is_suspended = 1 WHERE id = :id'
                );
                $upd->execute([':id' => (int)$targetId]);

                // Hard-ban the phone: remove their active listings too.
                $delListings = db()->prepare(
                    "DELETE FROM central_listings
                     WHERE seller_phone = :phone
                       AND status IN ('active', 'flagged', 'hidden')"
                );
                $delListings->execute([':phone' => $user['phone']]);
                $removed = $delListings->rowCount();

                $message = 'User hard banned. ' . $removed . ' listing(s) removed.';
                break;
        }
    }
} catch (PDOException $e) {
    error_log('[MADEALS moderate] ' . $e->getMessage());
    json_error('Database error while applying action.', 500);
}

/* 5. Audit log with real client IP — exactly one row per action */
$auditPrefix = in_array($action, $userActions, true) ? 'user_' : 'listing_';
log_audit($auditPrefix . $action, $targetId, $reason, $admin);

json_response([
    'success' => true,
    'message' => $message,
    'action'  => $action,
    'target'  => $targetId,
]);
