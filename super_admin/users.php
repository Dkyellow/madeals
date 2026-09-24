<?php
/**
 * Users — verification queue + user table with moderation actions.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/helpers.php';

$admin = require_admin();

$page_title = 'Users';

/* ---------------------------------------------------------------------
 * Filters
 * ------------------------------------------------------------------- */
$q          = trim((string)($_GET['q'] ?? ''));
$vStatus    = (string)($_GET['status'] ?? '');
$flag       = (string)($_GET['flag'] ?? '');       // suspended | banned | verified | pending
$page       = max(1, (int)($_GET['page'] ?? 1));

$validV = ['unverified', 'pending', 'verified', 'rejected'];
if (!in_array($vStatus, $validV, true)) {
    $vStatus = '';
}
$validFlags = ['suspended', 'banned', 'verified', 'pending'];
if (!in_array($flag, $validFlags, true)) {
    $flag = '';
}

$where  = [];
$params = [];

if ($q !== '') {
    $where[] = '(display_name LIKE :q OR phone LIKE :q OR region LIKE :q)';
    $params[':q'] = '%' . $q . '%';
}
if ($vStatus !== '') {
    $where[] = 'verification_status = :vstatus';
    $params[':vstatus'] = $vStatus;
}
if ($flag === 'suspended') {
    $where[] = 'is_suspended = 1';
} elseif ($flag === 'banned') {
    $where[] = 'is_banned = 1';
} elseif ($flag === 'verified') {
    $where[] = "verification_status = 'verified'";
} elseif ($flag === 'pending') {
    $where[] = "verification_status = 'pending'";
}

$whereSql = $where ? (' WHERE ' . implode(' AND ', $where)) : '';

$countStmt = db()->prepare('SELECT COUNT(*) FROM users' . $whereSql);
$countStmt->execute($params);
$total = (int)$countStmt->fetchColumn();

$perPage = PER_PAGE;
$pages   = max(1, (int)ceil($total / $perPage));
$page    = min($page, $pages);
$offset  = ($page - 1) * $perPage;

$sql = 'SELECT id, display_name, phone, avatar_url, trust_score, verification_status,
               id_document_url, selfie_url, is_suspended, is_banned, region, created_at
        FROM users'
     . $whereSql
     . ' ORDER BY
          FIELD(verification_status, "pending", "rejected", "unverified", "verified"),
          created_at DESC
        LIMIT :limit OFFSET :offset';

$stmt = db()->prepare($sql);
foreach ($params as $k => $v) {
    $stmt->bindValue($k, $v);
}
$stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$users = $stmt->fetchAll();

/* Pending queue count for the header chip */
$pendingCount = (int)db()->query(
    "SELECT COUNT(*) FROM users WHERE verification_status = 'pending'"
)->fetchColumn();

$baseQuery = array_filter([
    'q'      => $q,
    'status' => $vStatus,
    'flag'   => $flag,
], static fn($v) => $v !== '');

require __DIR__ . '/includes/header.php';
?>

<section class="card section-gap">
  <div class="card-header">
    <h2>Filters</h2>
    <a class="btn btn-ghost btn-sm" href="<?= e(BASE_URL) ?>/users.php">Reset</a>
  </div>
  <div class="card-body">
    <form method="get" action="<?= e(BASE_URL) ?>/users.php" class="toolbar">
      <input type="hidden" name="status" value="<?= e($vStatus) ?>">

      <div class="search-input">
        <input type="search" name="q" placeholder="Search name, phone, region…" value="<?= e($q) ?>">
      </div>

      <select name="status" aria-label="Verification status">
        <option value="">All verification</option>
        <?php foreach ($validV as $s): ?>
          <option value="<?= e($s) ?>" <?= $vStatus === $s ? 'selected' : '' ?>><?= e(ucfirst($s)) ?></option>
        <?php endforeach; ?>
      </select>

      <select name="flag" aria-label="Flags">
        <option value="">All users</option>
        <option value="pending"   <?= $flag === 'pending'   ? 'selected' : '' ?>>Pending verification</option>
        <option value="verified"  <?= $flag === 'verified'  ? 'selected' : '' ?>>Verified</option>
        <option value="suspended" <?= $flag === 'suspended' ? 'selected' : '' ?>>Suspended</option>
        <option value="banned"    <?= $flag === 'banned'    ? 'selected' : '' ?>>Banned</option>
      </select>

      <button type="submit" class="btn btn-primary">Apply</button>
    </form>
  </div>
</section>

<section class="card section-gap">
  <div class="card-header">
    <h2>Verification Queue <span class="queue-count"><?= e((string)$pendingCount) ?></span></h2>
    <a class="btn btn-ghost btn-sm" href="<?= e(BASE_URL) ?>/users.php?status=pending">Open queue</a>
  </div>
  <div class="card-body" style="padding:0">
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Phone</th>
            <th>ID Document</th>
            <th>Selfie</th>
            <th>Region</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php
          $queueStmt = db()->query(
              "SELECT id, display_name, phone, region, id_document_url, selfie_url
               FROM users
               WHERE verification_status = 'pending'
               ORDER BY created_at ASC
               LIMIT 6"
          );
          $queue = $queueStmt->fetchAll();
          ?>
          <?php if (!$queue): ?>
            <tr><td colspan="6" class="table-empty">Verification queue is empty.</td></tr>
          <?php else: foreach ($queue as $u): ?>
            <tr>
              <td class="cell-title">#<?= e((string)$u['id']) ?> <?= e($u['display_name']) ?></td>
              <td class="mono"><?= e($u['phone']) ?></td>
              <td>
                <?php if (!empty($u['id_document_url'])): ?>
                  <img class="doc-thumb" src="<?= e($u['id_document_url']) ?>" alt="ID document" loading="lazy">
                <?php else: ?>
                  <span class="doc-none">None</span>
                <?php endif; ?>
              </td>
              <td>
                <?php if (!empty($u['selfie_url'])): ?>
                  <img class="doc-thumb" src="<?= e($u['selfie_url']) ?>" alt="Selfie" loading="lazy">
                <?php else: ?>
                  <span class="doc-none">None</span>
                <?php endif; ?>
              </td>
              <td><?= e($u['region']) ?></td>
              <td class="cell-actions">
                <button class="btn btn-primary btn-icon" data-action="verify" data-target="<?= e((string)$u['id']) ?>">Approve Badge</button>
                <button class="btn btn-danger btn-icon" data-action="reject" data-target="<?= e((string)$u['id']) ?>">Reject ID</button>
              </td>
            </tr>
          <?php endforeach; endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</section>

<section class="card">
  <div class="card-header">
    <h2>All Users <span class="text-muted">(<?= e((string)$total) ?> results)</span></h2>
  </div>

  <div class="table-wrap">
    <table class="data-table">
      <thead>
        <tr>
          <th>#</th>
          <th>Name</th>
          <th>Phone</th>
          <th>Region</th>
          <th>Trust</th>
          <th>Verification</th>
          <th>Flags</th>
          <th>Joined</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$users): ?>
          <tr><td colspan="9" class="table-empty">No users match your filters.</td></tr>
        <?php else: foreach ($users as $u): ?>
          <tr>
            <td class="mono"><?= e((string)$u['id']) ?></td>
            <td>
              <span class="cell-title"><?= e($u['display_name']) ?></span>
              <?php if (!empty($u['avatar_url'])): ?>
                <span class="cell-sub">avatar on file</span>
              <?php endif; ?>
            </td>
            <td class="mono"><?= e($u['phone']) ?></td>
            <td><?= e($u['region']) ?></td>
            <td><?= e((string)$u['trust_score']) ?></td>
            <td><?= status_badge((string)$u['verification_status']) ?></td>
            <td>
              <span class="badge-row">
                <?php if ((int)$u['is_suspended']): ?><span class="badge badge-yellow">SUSPENDED</span><?php endif; ?>
                <?php if ((int)$u['is_banned']): ?><span class="badge badge-dark">BANNED</span><?php endif; ?>
                <?php if (!(int)$u['is_suspended'] && !(int)$u['is_banned']): ?><span class="badge badge-green">OK</span><?php endif; ?>
              </span>
            </td>
            <td class="nowrap"><?= e(format_date($u['created_at'], 'd M Y')) ?></td>
            <td class="cell-actions">
              <?php if ($u['verification_status'] !== 'verified'): ?>
                <button class="btn btn-primary btn-icon" data-action="verify" data-target="<?= e((string)$u['id']) ?>">Verify</button>
              <?php endif; ?>
              <?php if (!(int)$u['is_suspended']): ?>
                <button class="btn btn-ghost btn-icon" data-action="suspend" data-target="<?= e((string)$u['id']) ?>">Suspend</button>
              <?php endif; ?>
              <?php if (!(int)$u['is_banned']): ?>
                <button class="btn btn-danger btn-icon" data-action="ban" data-target="<?= e((string)$u['id']) ?>">Hard Ban</button>
              <?php endif; ?>
            </td>
          </tr>
        <?php endforeach; endif; ?>
      </tbody>
    </table>
  </div>

  <?php
  $renderPageBtn = static function (int $p, string $label, bool $active, bool $disabled, array $base) {
      $base['page'] = $p;
      $href = e(BASE_URL . '/users.php?' . http_build_query($base));
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
