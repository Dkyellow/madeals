<?php
/**
 * Audit logs — filter by action/admin, paginated.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/helpers.php';

$admin = require_admin();

$page_title = 'Audit Logs';

$q      = trim((string)($_GET['q'] ?? ''));
$action = trim((string)($_GET['action'] ?? ''));
$adminFilter = trim((string)($_GET['admin'] ?? ''));
$page   = max(1, (int)($_GET['page'] ?? 1));

$where  = [];
$params = [];

if ($q !== '') {
    $where[] = '(a.target_id LIKE :q1 OR a.reason LIKE :q2 OR a.ip_address LIKE :q3)';
    $like    = '%' . $q . '%';
    $params[':q1'] = $like;
    $params[':q2'] = $like;
    $params[':q3'] = $like;
}
if ($action !== '') {
    $where[] = 'a.action = :action';
    $params[':action'] = $action;
}
if ($adminFilter !== '') {
    $where[] = 'u.username = :admin';
    $params[':admin'] = $adminFilter;
}

$whereSql = $where ? (' WHERE ' . implode(' AND ', $where)) : '';

/* Distinct actions + admins for filter dropdowns */
$actionOptions = db()->query(
    'SELECT DISTINCT action FROM audit_logs ORDER BY action ASC'
)->fetchAll(PDO::FETCH_COLUMN);

$adminOptions = db()->query(
    'SELECT username FROM admin_users ORDER BY username ASC'
)->fetchAll(PDO::FETCH_COLUMN);

/* Count */
$countSql = 'SELECT COUNT(*)
             FROM audit_logs a
             JOIN admin_users u ON u.id = a.admin_id'
           . $whereSql;
$countStmt = db()->prepare($countSql);
$countStmt->execute($params);
$total = (int)$countStmt->fetchColumn();

$perPage = PER_PAGE;
$pages   = max(1, (int)ceil($total / $perPage));
$page    = min($page, $pages);
$offset  = ($page - 1) * $perPage;

$sql = 'SELECT a.id, a.action, a.target_id, a.reason, a.ip_address, a.created_at,
               u.username AS admin_username
        FROM audit_logs a
        JOIN admin_users u ON u.id = a.admin_id'
     . $whereSql
     . ' ORDER BY a.created_at DESC, a.id DESC
        LIMIT :limit OFFSET :offset';

$stmt = db()->prepare($sql);
foreach ($params as $k => $v) {
    $stmt->bindValue($k, $v);
}
$stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$logs = $stmt->fetchAll();

$baseQuery = array_filter([
    'q'      => $q,
    'action' => $action,
    'admin'  => $adminFilter,
], static fn($v) => $v !== '');

require __DIR__ . '/includes/header.php';
?>

<section class="card section-gap">
  <div class="card-header">
    <h2>Filters</h2>
    <a class="btn btn-ghost btn-sm" href="<?= e(BASE_URL) ?>/audit_logs.php">Reset</a>
  </div>
  <div class="card-body">
    <form method="get" action="<?= e(BASE_URL) ?>/audit_logs.php" class="toolbar">
      <div class="search-input">
        <input type="search" name="q" placeholder="Search target ID, reason, IP…" value="<?= e($q) ?>">
      </div>

      <select name="action" aria-label="Action">
        <option value="">All actions</option>
        <?php foreach ($actionOptions as $a): ?>
          <option value="<?= e($a) ?>" <?= $action === $a ? 'selected' : '' ?>><?= e($a) ?></option>
        <?php endforeach; ?>
      </select>

      <select name="admin" aria-label="Admin">
        <option value="">All admins</option>
        <?php foreach ($adminOptions as $aName): ?>
          <option value="<?= e($aName) ?>" <?= $adminFilter === $aName ? 'selected' : '' ?>><?= e($aName) ?></option>
        <?php endforeach; ?>
      </select>

      <button type="submit" class="btn btn-primary">Apply</button>
    </form>
  </div>
</section>

<section class="card">
  <div class="card-header">
    <h2>Audit Log <span class="text-muted">(<?= e((string)$total) ?> entries)</span></h2>
  </div>

  <div class="table-wrap">
    <table class="data-table">
      <thead>
        <tr>
          <th>Admin Username</th>
          <th>Action</th>
          <th>Target ID</th>
          <th>Reason</th>
          <th>IP Address</th>
          <th>Timestamp</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$logs): ?>
          <tr><td colspan="6" class="table-empty">No audit entries match your filters.</td></tr>
        <?php else: foreach ($logs as $log): ?>
          <tr>
            <td class="cell-title"><?= e($log['admin_username']) ?></td>
            <td><span class="badge badge-blue mono"><?= e($log['action']) ?></span></td>
            <td class="mono"><?= e($log['target_id']) ?></td>
            <td><?= e($log['reason'] ?? '—') ?></td>
            <td class="mono"><?= e($log['ip_address']) ?></td>
            <td class="nowrap"><?= e(format_date($log['created_at'])) ?></td>
          </tr>
        <?php endforeach; endif; ?>
      </tbody>
    </table>
  </div>

  <?php
  $renderPageBtn = static function (int $p, string $label, bool $active, bool $disabled, array $base) {
      $base['page'] = $p;
      $href = e(BASE_URL . '/audit_logs.php?' . http_build_query($base));
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
      <?= $renderPageBtn(max(1, $page - 1), '‹', false, $page <= 1, $baseQuery) ?>
      <?php
      $start = max(1, $page - 2);
      $end   = min($pages, $page + 2);
      for ($p = $start; $p <= $end; $p++) {
          echo $renderPageBtn($p, (string)$p, $p === $page, false, $baseQuery);
      }
      ?>
      <?= $renderPageBtn(min($pages, $page + 1), '›', false, $page >= $pages, $baseQuery) ?>
    </div>
  </div>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
