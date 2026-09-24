<?php
/**
 * Dashboard — live stat counts, regional breakdown, recent audit log.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/helpers.php';

$admin = require_admin();

$page_title = 'Dashboard';

/* --- Live counts ------------------------------------------------------- */
$activeListings = (int)db()->query(
    "SELECT COUNT(*) FROM central_listings WHERE status = 'active'"
)->fetchColumn();

$totalUsers = (int)db()->query('SELECT COUNT(*) FROM users')->fetchColumn();

$flaggedReports = (int)db()->query(
    "SELECT COUNT(*) FROM central_listings WHERE status = 'flagged'"
)->fetchColumn();

$pendingVerifications = (int)db()->query(
    "SELECT COUNT(*) FROM users WHERE verification_status = 'pending'"
)->fetchColumn();

/* --- Regional breakdown (Harare vs Bulawayo vs Mutare vs Other) -------- */
$regionStmt = db()->query(
    "SELECT CASE
       WHEN location LIKE 'Harare%'   THEN 'Harare'
       WHEN location LIKE 'Bulawayo%' THEN 'Bulawayo'
       WHEN location LIKE 'Mutare%'   THEN 'Mutare'
       ELSE 'Other'
     END AS region_group,
     COUNT(*) AS total
     FROM central_listings
     WHERE status = 'active'
     GROUP BY region_group
     ORDER BY total DESC"
);
$regionRows = $regionStmt->fetchAll();

$regionMap = ['Harare' => 0, 'Bulawayo' => 0, 'Mutare' => 0, 'Other' => 0];
foreach ($regionRows as $r) {
    $regionMap[(string)$r['region_group']] = (int)$r['total'];
}
$maxRegion = max(1, max($regionMap));

/* --- Recent audit logs -------------------------------------------------- */
$recentAudit = db()->query(
    'SELECT a.action, a.target_id, a.reason, a.ip_address, a.created_at, u.username
     FROM audit_logs a
     JOIN admin_users u ON u.id = a.admin_id
     ORDER BY a.created_at DESC
     LIMIT 8'
)->fetchAll();

/* --- Pending verification queue preview -------------------------------- */
$pendingQueue = db()->query(
    "SELECT id, display_name, phone, region, id_document_url, selfie_url
     FROM users
     WHERE verification_status = 'pending'
     ORDER BY created_at ASC
     LIMIT 5"
)->fetchAll();

require __DIR__ . '/includes/header.php';
?>

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-label">Total Active Listings</span>
    <span class="stat-value accent"><?= e((string)$activeListings) ?></span>
  </div>
  <div class="stat-card">
    <span class="stat-label">Total Users</span>
    <span class="stat-value"><?= e((string)$totalUsers) ?></span>
  </div>
  <div class="stat-card">
    <span class="stat-label">Flagged Reports</span>
    <span class="stat-value danger"><?= e((string)$flaggedReports) ?></span>
  </div>
  <div class="stat-card">
    <span class="stat-label">ID Verifications Pending</span>
    <span class="stat-value warning"><?= e((string)$pendingVerifications) ?></span>
  </div>
</div>

<div class="dash-grid">
  <section class="card">
    <div class="card-header">
      <h2>Active Listings by Region</h2>
    </div>
    <div class="card-body">
      <div class="bar-chart">
        <?php foreach ($regionMap as $region => $count): ?>
          <div class="bar-row">
            <span class="bar-label"><?= e($region) ?></span>
            <div class="bar-track">
              <div class="bar-fill" style="width: <?= e((string)round($count / $maxRegion * 100)) ?>%"></div>
            </div>
            <span class="bar-value"><?= e((string)$count) ?></span>
          </div>
        <?php endforeach; ?>
      </div>
    </div>
  </section>

  <section class="card">
    <div class="card-header">
      <h2>Pending Verifications</h2>
      <a class="btn btn-ghost btn-sm" href="users.php?status=pending">View queue</a>
    </div>
    <div class="card-body" style="padding:0">
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Phone</th>
              <th>Region</th>
              <th>ID</th>
              <th>Selfie</th>
            </tr>
          </thead>
          <tbody>
            <?php if (!$pendingQueue): ?>
              <tr><td colspan="5" class="table-empty">No pending verifications 🎉</td></tr>
            <?php else: foreach ($pendingQueue as $q): ?>
              <tr>
                <td class="cell-title"><?= e($q['display_name']) ?></td>
                <td class="mono"><?= e($q['phone']) ?></td>
                <td><?= e($q['region']) ?></td>
                <td><?= $q['id_document_url'] ? '<span class="badge badge-yellow">Submitted</span>' : '<span class="badge badge-gray">Missing</span>' ?></td>
                <td><?= $q['selfie_url'] ? '<span class="badge badge-yellow">Submitted</span>' : '<span class="badge badge-gray">Missing</span>' ?></td>
              </tr>
            <?php endforeach; endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </section>
</div>

<section class="card">
  <div class="card-header">
    <h2>Recent Audit Activity</h2>
      <a class="btn btn-ghost btn-sm" href="audit_logs.php">View all</a>
  </div>
  <div class="card-body" style="padding:0">
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Admin</th>
            <th>Action</th>
            <th>Target</th>
            <th>Reason</th>
            <th>IP</th>
            <th>Timestamp</th>
          </tr>
        </thead>
        <tbody>
          <?php if (!$recentAudit): ?>
            <tr><td colspan="6" class="table-empty">No audit entries yet.</td></tr>
          <?php else: foreach ($recentAudit as $log): ?>
            <tr>
              <td class="cell-title"><?= e($log['username']) ?></td>
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
  </div>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
