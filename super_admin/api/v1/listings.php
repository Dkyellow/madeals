<?php
/**
 * Public listings API for the Flutter app.
 *
 * GET  /api/v1/listings.php?category=&q=&limit=&offset=
 *      → { success, count, listings: [...] }  (only status='active')
 *
 * POST /api/v1/listings.php
 *      → creates a listing from the mobile app (no auth, basic validation).
 *      Body: JSON { id?, title, price, category, location, latitude, longitude,
 *                   description?, images?: [], seller_phone?, user_id? }
 */

declare(strict_types=1);

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/db.php';
require_once __DIR__ . '/../../includes/auth.php';
require_once __DIR__ . '/../../includes/helpers.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/**
 * Map a DB row to the Flutter-facing JSON shape.
 */
function map_listing(array $row): array
{
    $images = array_values(array_filter(array_map('trim', explode(',', (string)($row['image_url'] ?? '')))));

    return [
        'id'          => (string)$row['id'],
        'title'       => (string)$row['title'],
        'price'       => (float)$row['price'],
        'category'    => (string)$row['category'],
        'location'    => (string)$row['location'],
        'latitude'    => (float)$row['latitude'],
        'longitude'   => (float)$row['longitude'],
        'description' => $row['description'] !== null ? (string)$row['description'] : null,
        'images'      => $images,
        'seller_phone'=> $row['seller_phone'] !== null ? (string)$row['seller_phone'] : null,
        'is_verified' => (int)$row['is_verified'] === 1,
        'is_featured' => (int)$row['is_featured'] === 1,
        'status'      => (string)$row['status'],
        'created_at'  => (string)$row['created_at'],
    ];
}

/* -------------------------------------------------------------------------
 * GET — active listings for Flutter cache
 * ---------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $category = trim((string)($_GET['category'] ?? ''));
    $q        = trim((string)($_GET['q'] ?? ''));
    $limit    = isset($_GET['limit']) ? (int)$_GET['limit'] : API_DEFAULT_LIMIT;
    $offset   = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

    $limit = max(1, min($limit, API_MAX_LIMIT));

    $where  = ["status = 'active'"];
    $params = [];

    if ($category !== '' && in_array($category, CATEGORIES, true)) {
        $where[] = 'category = :category';
        $params[':category'] = $category;
    }
    if ($q !== '') {
        $where[] = '(title LIKE :q OR location LIKE :q OR description LIKE :q)';
        $params[':q'] = '%' . $q . '%';
    }

    $whereSql = ' WHERE ' . implode(' AND ', $where);

    $countStmt = db()->prepare('SELECT COUNT(*) FROM central_listings' . $whereSql);
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    $sql = 'SELECT id, title, price, category, location, latitude, longitude,
                   description, image_url, seller_phone, user_id, status,
                   is_featured, is_verified, created_at
            FROM central_listings'
         . $whereSql
         . ' ORDER BY is_featured DESC, created_at DESC
            LIMIT :limit OFFSET :offset';

    $stmt = db()->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $rows = $stmt->fetchAll();

    json_response([
        'success'  => true,
        'count'    => count($rows),
        'total'    => $total,
        'limit'    => $limit,
        'offset'   => $offset,
        'listings' => array_map('map_listing', $rows),
    ]);
}

/* -------------------------------------------------------------------------
 * POST — submit a new listing from mobile
 * ---------------------------------------------------------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = read_json_body();

    // Fall back to form-encoded body if JSON not provided.
    if (!$body && !empty($_POST)) {
        $body = $_POST;
    }

    /* Basic anti-abuse checks (honeypot-ish) */
    if (!empty($body['website']) || !empty($body['hp_field'])) {
        json_error('Rejected.', 422);
    }
    if (isset($body['form_time']) && is_numeric($body['form_time'])) {
        if ((time() - (int)$body['form_time']) < 2) {
            json_error('Submitted too quickly.', 422);
        }
    }

    $title       = trim((string)($body['title'] ?? ''));
    $priceRaw    = $body['price'] ?? null;
    $category    = trim((string)($body['category'] ?? ''));
    $location    = trim((string)($body['location'] ?? ''));
    $latitude    = $body['latitude'] ?? null;
    $longitude   = $body['longitude'] ?? null;
    $description = isset($body['description']) ? trim((string)$body['description']) : null;
    $sellerPhone = isset($body['seller_phone']) ? trim((string)$body['seller_phone']) : null;
    $userId      = isset($body['user_id']) ? (int)$body['user_id'] : null;
    $id          = trim((string)($body['id'] ?? ''));

    /* Images: accept array or comma-separated string */
    $images = [];
    if (isset($body['images'])) {
        if (is_array($body['images'])) {
            $images = array_values(array_filter(array_map(static fn($u) => trim((string)$u), $body['images'])));
        } else {
            $images = array_values(array_filter(array_map('trim', explode(',', (string)$body['images']))));
        }
    }
    $imageUrl = implode(',', array_slice($images, 0, 10));

    /* Validation */
    $errors = [];
    if ($title === '' || mb_strlen($title) > 255) {
        $errors['title'] = 'Title is required (max 255 chars).';
    }
    if ($priceRaw === null || $priceRaw === '' || !is_numeric($priceRaw) || (float)$priceRaw < 0) {
        $errors['price'] = 'A valid non-negative price is required.';
    }
    if ($category === '' || !in_array($category, CATEGORIES, true)) {
        $errors['category'] = 'Category must be one of: ' . implode(', ', CATEGORIES);
    }
    if ($location === '' || mb_strlen($location) > 100) {
        $errors['location'] = 'Location is required (max 100 chars).';
    }
    if ($latitude === null || !is_numeric($latitude) || (float)$latitude < -90 || (float)$latitude > 90) {
        $errors['latitude'] = 'latitude must be a number between -90 and 90.';
    }
    if ($longitude === null || !is_numeric($longitude) || (float)$longitude < -180 || (float)$longitude > 180) {
        $errors['longitude'] = 'longitude must be a number between -180 and 180.';
    }
    if ($description !== null && mb_strlen($description) > 5000) {
        $errors['description'] = 'Description too long (max 5000 chars).';
    }
    if ($sellerPhone !== null && !preg_match('/^\+?[0-9]{7,20}$/', $sellerPhone)) {
        $errors['seller_phone'] = 'Invalid phone number format.';
    }

    if ($errors) {
        json_error('Validation failed.', 422, ['errors' => $errors]);
    }

    /* Generate ID if not supplied */
    if ($id === '') {
        $id = 'lst_' . bin2hex(random_bytes(12));
    }
    if (strlen($id) > 64 || !preg_match('/^[A-Za-z0-9_\-]+$/', $id)) {
        json_error('Invalid listing id format.', 422, ['errors' => ['id' => 'Max 64 chars, alphanumeric/underscore/dash only.']]);
    }

    /* Duplicate check */
    $existsStmt = db()->prepare('SELECT 1 FROM central_listings WHERE id = :id LIMIT 1');
    $existsStmt->execute([':id' => $id]);
    if ($existsStmt->fetchColumn()) {
        json_error('Listing id already exists.', 409);
    }

    /* Resolve user_id / is_verified if phone matches a known verified user */
    $isVerified = 0;
    if ($sellerPhone !== null) {
        $userStmt = db()->prepare(
            'SELECT id, verification_status FROM users WHERE phone = :phone LIMIT 1'
        );
        $userStmt->execute([':phone' => $sellerPhone]);
        $found = $userStmt->fetch();
        if ($found) {
            if ($userId === null) {
                $userId = (int)$found['id'];
            }
            if ($found['verification_status'] === 'verified') {
                $isVerified = 1;
            }
        }
    }

    try {
        $insert = db()->prepare(
            'INSERT INTO central_listings
                (id, title, price, category, location, latitude, longitude,
                 description, image_url, seller_phone, user_id, status, is_featured, is_verified)
             VALUES
                (:id, :title, :price, :category, :location, :latitude, :longitude,
                 :description, :image_url, :seller_phone, :user_id, :status, 0, :is_verified)'
        );
        $insert->execute([
            ':id'           => $id,
            ':title'        => $title,
            ':price'        => (float)$priceRaw,
            ':category'     => $category,
            ':location'     => $location,
            ':latitude'     => (float)$latitude,
            ':longitude'    => (float)$longitude,
            ':description'  => $description,
            ':image_url'    => $imageUrl !== '' ? $imageUrl : null,
            ':seller_phone' => $sellerPhone,
            ':user_id'      => $userId,
            ':status'       => 'active',
            ':is_verified'  => $isVerified,
        ]);
    } catch (PDOException $e) {
        if ((string)$e->getCode() === '23000') {
            json_error('Duplicate listing id.', 409);
        }
        error_log('[MADEALS api] ' . $e->getMessage());
        json_error('Could not save listing.', 500);
    }

    $fetch = db()->prepare('SELECT * FROM central_listings WHERE id = :id LIMIT 1');
    $fetch->execute([':id' => $id]);
    $created = $fetch->fetch();

    json_response([
        'success' => true,
        'message' => 'Listing created.',
        'listing' => map_listing($created),
    ], 201);
}

/* Anything else */
json_error('Method not allowed.', 405);
