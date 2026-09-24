<?php
/**
 * Shared HTML head + sidebar/topbar.
 * Expects: $page_title (string), optionally $page_css (array of extra files).
 */

declare(strict_types=1);

require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/helpers.php';

start_secure_session();

$admin = current_admin();
if ($admin === null) {
    header('Location: login.php');
    exit;
}

$page_title = $page_title ?? 'Dashboard';
$csrf = csrf_token();
$nav_items = [
    'index.php'      => ['Dashboard',   'M3 12l9-9 9 9M5 10v10h5v-6h4v6h5V10'],
    'listings.php'   => ['Listings',    'M4 6h16M4 12h16M4 18h10'],
    'users.php'      => ['Users',       'M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8zM22 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75'],
    'audit_logs.php' => ['Audit Logs',  'M12 8v4l3 3M21 12a9 9 0 11-18 0 9 9 0 0118 0z'],
];
$current_file = basename($_SERVER['PHP_SELF']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="csrf-token" content="<?= e($csrf) ?>">
<title><?= e($page_title) ?> — <?= e(APP_NAME) ?></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= e(BASE_URL) ?>/assets/css/style.css">
</head>
<body data-csrf="<?= e($csrf) ?>">
<div class="app-shell">
  <aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
      <span class="brand-mark">M</span>
      <span class="brand-text">MADEALS<span class="brand-sub">Super Admin</span></span>
    </div>
    <nav class="sidebar-nav">
      <?php foreach ($nav_items as $file => [$label, $icon]): ?>
        <a href="<?= e(BASE_URL) ?>/<?= e($file) ?>" class="<?= $current_file === $file ? 'active' : '' ?>">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="<?= e($icon) ?>"/></svg>
          <?= e($label) ?>
        </a>
      <?php endforeach; ?>
    </nav>
    <div class="sidebar-footer">
      <a href="<?= e(BASE_URL) ?>/logout.php" class="nav-logout">
        <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/></svg>
        Logout
      </a>
    </div>
  </aside>

  <div class="main-column">
    <header class="topbar">
      <button class="sidebar-toggle" id="sidebarToggle" aria-label="Toggle navigation">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
      </button>
      <h1 class="topbar-title"><?= e($page_title) ?></h1>
      <div class="topbar-user">
        <span class="user-avatar"><?= e(strtoupper(substr((string)$admin['username'], 0, 1))) ?></span>
        <span class="user-meta">
          <strong><?= e($admin['username']) ?></strong>
          <small><?= e(ucfirst((string)$admin['role'])) ?></small>
        </span>
      </div>
    </header>
    <main class="content">
