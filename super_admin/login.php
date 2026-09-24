<?php
/**
 * Admin login.
 */

declare(strict_types=1);

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/helpers.php';

start_secure_session();

// Already logged in? Go to dashboard.
if (current_admin() !== null) {
    header('Location: index.php');
    exit;
}

$error = '';
$csrf  = csrf_token();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Small delay before any processing to blunt trivial brute force.
    usleep(random_int(250000, 600000));

    if (!csrf_verify($_POST['csrf_token'] ?? '')) {
        $error = 'Session expired. Please try again.';
    } else {
        $username = trim((string)($_POST['username'] ?? ''));
        $password = (string)($_POST['password'] ?? '');

        if ($username === '' || $password === '') {
            $error = 'Username and password are required.';
        } else {
            $stmt = db()->prepare(
                'SELECT id, username, password_hash, is_active
                 FROM admin_users
                 WHERE username = :username OR email = :email
                 LIMIT 1'
            );
            $stmt->execute([':username' => $username, ':email' => $username]);
            $admin = $stmt->fetch();

            if (!$admin || (int)$admin['is_active'] !== 1 || !password_verify($password, $admin['password_hash'])) {
                $error = 'Invalid username or password.';
                // Constant-ish extra work so wrong passwords take similar time.
                password_verify($password, '$2y$10$usesomesillystringfore7hnbRJHxXVLeakoG8K30oukPsA.ztMG');
            } else {
                // Rehash if needed.
                if (password_needs_rehash($admin['password_hash'], PASSWORD_DEFAULT)) {
                    $up = db()->prepare('UPDATE admin_users SET password_hash = :h WHERE id = :id');
                    $up->execute([':h' => password_hash($password, PASSWORD_DEFAULT), ':id' => (int)$admin['id']]);
                }

                session_regenerate_id(true);
                $_SESSION['admin_id']   = (int)$admin['id'];
                $_SESSION['admin_name'] = (string)$admin['username'];
                $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

                header('Location: index.php');
                exit;
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Login — <?= e(APP_NAME) ?></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= e(BASE_URL) ?>/assets/css/style.css">
</head>
<body>
<div class="login-wrap">
  <div class="login-card">
    <div class="login-brand">
      <span class="brand-mark">M</span>
      <span class="brand-text">MADEALS<span class="brand-sub">Super Admin</span></span>
    </div>

    <h1>Sign in</h1>
    <p class="login-sub">Moderate listings, verify sellers, and review audit logs.</p>

    <?php if ($error !== ''): ?>
      <div class="login-alert"><?= e($error) ?></div>
    <?php endif; ?>

    <form method="post" action="login.php" autocomplete="off">
      <input type="hidden" name="csrf_token" value="<?= e($csrf) ?>">

      <div class="form-group">
        <label for="username">Username or email</label>
        <input type="text" id="username" name="username" required
               value="<?= e($_POST['username'] ?? '') ?>" autofocus>
      </div>

      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required>
      </div>

      <button type="submit" class="btn btn-primary btn-block">Sign in</button>
    </form>
  </div>
</div>
</body>
</html>
