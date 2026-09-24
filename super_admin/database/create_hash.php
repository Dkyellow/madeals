<?php
/**
 * Convenience utility: prints a bcrypt hash for the default admin password.
 * Run:  php database/create_hash.php
 *       php database/create_hash.php "MyNewPassword"
 */

declare(strict_types=1);

$password = $argv[1] ?? 'Madeals@2026!';

echo password_hash($password, PASSWORD_DEFAULT) . PHP_EOL;
