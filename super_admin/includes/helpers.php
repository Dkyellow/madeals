<?php
/**
 * Small view/formatting helpers.
 */

declare(strict_types=1);

/**
 * HTML-escape output.
 */
function e(?string $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * Format a price as USD string: 1,550.00
 */
function format_price($value): string
{
    return number_format((float)$value, 2, '.', ',');
}

/**
 * Format a datetime string for display.
 */
function format_date(?string $value, string $format = 'd M Y, H:i'): string
{
    if ($value === null || $value === '') {
        return '—';
    }
    $ts = strtotime($value);
    if ($ts === false) {
        return '—';
    }
    return date($format, $ts);
}

/**
 * Return an HTML badge for a listing/user status.
 */
function status_badge(string $status): string
{
    $map = [
        'active'       => ['Active',       'badge-green'],
        'flagged'      => ['Flagged',      'badge-red'],
        'hidden'       => ['Hidden',       'badge-gray'],
        'removed_by_admin' => ['Removed',  'badge-dark'],
        'unverified'   => ['Unverified',   'badge-gray'],
        'pending'      => ['Pending',      'badge-yellow'],
        'verified'     => ['Verified',     'badge-blue'],
        'rejected'     => ['Rejected',     'badge-red'],
    ];

    [$label, $class] = $map[$status] ?? [ucfirst($status), 'badge-gray'];
    return '<span class="badge ' . e($class) . '">' . e($label) . '</span>';
}

/**
 * Small featured/verified tag chips.
 */
function tag_chip(bool $on, string $label, string $class): string
{
    if (!$on) {
        return '';
    }
    return '<span class="badge ' . e($class) . '">' . e($label) . '</span>';
}
