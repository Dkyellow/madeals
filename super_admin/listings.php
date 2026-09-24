<?php
/**
 * Listings management — search, filters, pagination, AJAX moderation.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/helpers.php';

$admin = require_admin();

$page_title = 'Listings';

/* ---------------------------------------------------------------------
 * Filters (all server-side, prepared)
 * ------------------------------------------------------------------- */
$q        = trim((string)($_GET['q'] ?? ''));
$status   = (string)($_GET['status'] ?? '');
$category = (string)($_GET['category'] ?? '');
$priceMin = $_GET['price_min'] ?? '';
$priceMax = $_GET['price_max'] ?? '';
$page     = max(1, (int)($_GET['page'] ?? 1));

if (!in_array($status, LISTING_STATUSES, true)) {
    $status = '';
}
if (!in_array($category, CATEGORIES, true)) {
    $category = '';
}

$priceMin = ($priceMin !== '' && is_numeric($priceMin)) ? (float)$priceMin : null;
$priceMax = ($priceMax !== '' && is_numeric($priceMax)) ? (float)$priceMax : null;

$where  = [];
$params = [];

if ($q !== '') {
    $where[] = '(title LIKE :q1 OR location LIKE :q2 OR seller_phone LIKE :q3 OR id LIKE :q4)';
    $like    = '%' . $q . '%';
    $params[':q1'] = $like;
    $params[':q2'] = $like;
    $params[':q3'] = $like;
    $params[':q4'] = $like;
}
if ($status !== '') {
    $where[] = 'status = :status';
    $params[':status'] = $status;
}
if ($category !== '') {
    $where[] = 'category = :category';
    $params[':category'] = $category;
}
if ($priceMin !== null) {
    $where[] = 'price >= :price_min';
    $params[':price_min'] = $priceMin;
}
if ($priceMax !== null) {
    $where[] = 'price <= :price_max';
    $params[':price_max'] = $priceMax;
}

$whereSql = $where ? (' WHERE ' . implode(' AND ', $where)) : '';

/* Count */
$countStmt = db()->prepare('SELECT COUNT(*) FROM central_listings' . $whereSql);
$countStmt->execute($params);
$total = (int)$countStmt->fetchColumn();

$perPage  = PER_PAGE;
$pages    = max(1, (int)ceil($total / $perPage));
$page     = min($page, $pages);
$offset   = ($page - 1) * $perPage;

/* Rows */
$sql = 'SELECT id, title, price, category, location, image_url, seller_phone,
               status, is_featured, is_verified, created_at
        FROM central_listings'
     . $whereSql
     . ' ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset';

$stmt = db()->prepare($sql);
foreach ($params as $k => $v) {
    $stmt->bindValue($k, $v);
}
$stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$listings = $stmt->fetchAll();

/* Base URL for pagination links */
$baseQuery = array_filter([
    'q'         => $q,
    'status'    => $status,
    'category'  => $category,
    'price_min' => $priceMin !== null ? (string)$priceMin : '',
    'price_max' => $priceMax !== null ? (string)$priceMax : '',
], static fn($v) => $v !== '' && $v !== null);

require __DIR__ . '/includes/header.php';
?>

<section class="card section-gap">
  <div class="card-header">
    <h2>Filters</h2>
    <a class="btn btn-ghost btn-sm" href="<?= e(BASE_URL) ?>/listings.php">Reset</a>
  </div>
  <div class="card-body">
    <form method="get" action="<?= e(BASE_URL) ?>/listings.php" class="toolbar server-filter">
      <input type="hidden" name="status" value="<?= e($status) ?>">

      <div class="search-input">
        <input type="search" name="q" placeholder="Search title, location, phone, ID…" value="<?= e($q) ?>">
      </div>

      <select name="category" aria-label="Category">
        <option value="">All categories</option>
        <?php foreach (CATEGORIES as $c): ?>
          <option value="<?= e($c) ?>" <?= $category === $c ? 'selected' : '' ?>><?= e(ucfirst($c)) ?></option>
        <?php endforeach; ?>
      </select>

      <input type="number" name="price_min" placeholder="Min $" step="0.01" min="0"
             value="<?= e($priceMin !== null ? (string)$priceMin : '') ?>" style="max-width:120px">
      <input type="number" name="price_max" placeholder="Max $" step="0.01" min="0"
             value="<?= e($priceMax !== null ? (string)$priceMax : '') ?>" style="max-width:120px">

      <button type="submit" class="btn btn-primary">Apply</button>
    </form>

    <div class="filter-pills" style="margin-top:14px">
      <?php
      $pills = [
          ''            => 'All',
          'active'      => 'Active',
          'flagged'     => 'Flagged',
          'hidden'      => 'Hidden',
          'removed_by_admin' => 'Removed',
      ];
      foreach ($pills as $value => $label):
      ?>
        <button type="button"
                class="pill <?= $status === $value ? 'active' : '' ?>"
                data-value="<?= e($value) ?>"><?= e($label) ?></button>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="card">
  <div class="card-header">
    <h2>Listings <span class="text-muted">(<?= e((string)$total) ?> results)</span></h2>
  </div>

  <div class="table-wrap">
    <table class="data-table">
      <thead>
        <tr>
          <th></th>
          <th>Title</th>
          <th>Price</th>
          <th>Category</th>
          <th>Location</th>
          <th>Seller</th>
          <th>Status</th>
          <th>Created</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$listings): ?>
          <tr><td colspan="9" class="table-empty">No listings match your filters.</td></tr>
        <?php else: foreach ($listings as $l):
          $firstImg = trim(explode(',', (string)($l['image_url'] ?? ''))[0]);
          $flags = status_badge((string)$l['status'])
                 . ((int)$l['is_featured'] ? tag_chip(true, 'FEATURED', 'badge-yellow') : '')
                 . ((int)$l['is_verified'] ? tag_chip(true, 'VERIFIED', 'badge-blue') : '');
        ?>
          <tr>
            <td>
              <?php if ($firstImg !== ''): ?>
                <img class="thumb" src="<?= e($firstImg) ?>" alt="" loading="lazy">
              <?php else: ?>
                <span class="thumb"></span>
              <?php endif; ?>
            </td>
            <td>
              <span class="cell-title"><?= e($l['title']) ?></span>
              <span class="cell-sub mono"><?= e($l['id']) ?></span>
            </td>
            <td class="cell-price">$<?= e(format_price($l['price'])) ?></td>
            <td><?= e(ucfirst((string)$l['category'])) ?></td>
            <td><?= e($l['location']) ?></td>
            <td class="mono"><?= e($l['seller_phone'] ?? '—') ?></td>
            <td><span class="badge-row"><?= $flags ?></span></td>
            <td class="nowrap"><?= e(format_date($l['created_at'])) ?></td>
            <td class="cell-actions">
              <?php if ((int)$l['is_featured']): ?>
                <button class="btn btn-ghost btn-icon" data-action="unfeature" data-target="<?= e($l['id']) ?>">Unfeature</button>
              <?php else: ?>
                <button class="btn btn-ghost btn-icon" data-action="feature" data-target="<?= e($l['id']) ?>">Feature</button>
              <?php endif; ?>

              <?php if ($l['status'] !== 'active'): ?>
                <button class="btn btn-primary btn-icon" data-action="approve" data-target="<?= e($l['id']) ?>">Approve</button>
              <?php else: ?>
                <button class="btn btn-ghost btn-icon" data-action="hide" data-target="<?= e($l['id']) ?>">Hide</button>
              <?php endif; ?>

              <button class="btn btn-danger btn-icon" data-action="delete" data-target="<?= e($l['id']) ?>">Delete</button>
            </td>
          </tr>
        <?php endforeach; endif; ?>
      </tbody>
    </table>
  </div>

  <?php
  // Pagination render helper (inline).
  $renderPageBtn = static function (int $p, string $label, bool $active, bool $disabled, array $base) {
      $base['page'] = $p;
      $href = e(BASE_URL . '/listings.php?' . http_build_query($base));
      $cls = 'page-btn' . ($active ? ' active' : '');
      if ($disabled) {
          return '<button class="' . $cls . '" disabled>' . $label . '</button>';
      }
      return '<a class="' . $cls . '" href="' . $href . '">' . $label . '</a>';
  };
  ?>

  <div class="pagination">
    <span class="pagination-info">
      Showing <?= $total ? e((string)($offset + 1)) : '0' ?>–<?= e((string)min($offset + $perPage, $total)) ?>
      of <?= e((string)$total) ?>
    </span>
    <div class="pagination-pages">
      <?= $renderPageBtn(max(1, $page - 1), '‹', false, $page <= 1, $baseQuery + ['page' => $page]) ?>
      <?php
      $start = max(1, $page - 2);
      $end   = min($pages, $page + 2);
      for ($p = $start; $p <= $end; $p++) {
          echo $renderPageBtn($p, (string)$p, $p === $page, false, $baseQuery + ['page' => $page]);
      }
      ?>
      <?= $renderPageBtn(min($pages, $page + 1), '›', false, $page >= $pages, $baseQuery + ['page' => $page]) ?>
    </div>
  </div>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
