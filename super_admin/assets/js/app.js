/* ==========================================================================
   MADEALS Super Admin — front-end behaviour
   CSRF for AJAX, confirm modals, filters, toasts, moderation calls.
   ========================================================================== */

'use strict';

const App = (() => {
  const CSRF = document.body.dataset.csrf || '';

  /* ------------------------------------------------------------------ */
  /* Toast                                                               */
  /* ------------------------------------------------------------------ */
  let toastTimer = null;
  function toast(message, type = 'success') {
    const el = document.getElementById('toast');
    if (!el) return;
    el.textContent = message;
    el.className = `toast show ${type}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { el.className = 'toast'; }, 3200);
  }

  /* ------------------------------------------------------------------ */
  /* Modal with confirm callback                                         */
  /* ------------------------------------------------------------------ */
  const overlay = document.getElementById('modalOverlay');
  let confirmCb = null;

  function openModal({ title, body, confirmLabel = 'Confirm', danger = true, onConfirm }) {
    if (!overlay) {
      if (window.confirm(body)) onConfirm && onConfirm();
      return;
    }
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalBody').innerHTML = body;
    const confirmBtn = document.getElementById('modalConfirm');
    confirmBtn.textContent = confirmLabel;
    confirmBtn.className = danger ? 'btn btn-danger' : 'btn btn-primary';
    confirmCb = onConfirm || null;
    overlay.hidden = false;
    confirmBtn.focus();
  }

  function closeModal() {
    if (!overlay) return;
    overlay.hidden = true;
    confirmCb = null;
  }

  if (overlay) {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay || e.target.closest('[data-close-modal]')) closeModal();
    });
    document.getElementById('modalConfirm').addEventListener('click', () => {
      const cb = confirmCb;
      closeModal();
      if (cb) cb();
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !overlay.hidden) closeModal();
    });
  }

  function confirmAction(title, message, onConfirm, confirmLabel = 'Confirm') {
    openModal({ title, body: `<p>${message}</p>`, confirmLabel, onConfirm });
  }

  /* ------------------------------------------------------------------ */
  /* AJAX with CSRF header                                               */
  /* ------------------------------------------------------------------ */
  async function post(url, data = {}) {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': CSRF,
        'X-Requested-With': 'XMLHttpRequest',
      },
      credentials: 'same-origin',
      body: JSON.stringify(data),
    });

    let payload = null;
    try { payload = await res.json(); } catch (_) { /* non-JSON */ }

    if (!res.ok) {
      const msg = (payload && payload.message) || `Request failed (${res.status})`;
      const err = new Error(msg);
      err.status = res.status;
      err.payload = payload;
      throw err;
    }
    return payload;
  }

  /* ------------------------------------------------------------------ */
  /* Sidebar toggle (mobile)                                             */
  /* ------------------------------------------------------------------ */
  function initSidebar() {
    const toggle = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('sidebar');
    if (!toggle || !sidebar) return;

    let backdrop = document.querySelector('.sidebar-backdrop');
    if (!backdrop) {
      backdrop = document.createElement('div');
      backdrop.className = 'sidebar-backdrop';
      document.body.appendChild(backdrop);
    }

    const setOpen = (open) => {
      sidebar.classList.toggle('open', open);
      backdrop.classList.toggle('show', open);
    };

    toggle.addEventListener('click', () => setOpen(!sidebar.classList.contains('open')));
    backdrop.addEventListener('click', () => setOpen(false));
  }

  /* ------------------------------------------------------------------ */
  /* Client-side quick filter (progressive enhancement on top of GET    */
  /* forms — rows carry data-filter attributes)                          */
  /* ------------------------------------------------------------------ */
  function initTableSearch() {
    document.querySelectorAll('[data-quick-filter]').forEach((input) => {
      const tableId = input.getAttribute('data-quick-filter');
      const table = document.getElementById(tableId);
      if (!table) return;
      input.addEventListener('input', () => {
        const q = input.value.trim().toLowerCase();
        table.querySelectorAll('tbody tr').forEach((row) => {
          if (row.classList.contains('table-empty')) return;
          row.style.display = !q || row.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
      });
    });
  }

  /* ------------------------------------------------------------------ */
  /* Server-side filter forms: submit on Enter / pill click             */
  /* ------------------------------------------------------------------ */
  function initFilterForms() {
    document.querySelectorAll('form.server-filter').forEach((form) => {
      form.querySelectorAll('.pill').forEach((pill) => {
        pill.addEventListener('click', () => {
          const hidden = form.querySelector('input[name="status"]');
          if (hidden) hidden.value = pill.dataset.value || '';
          form.querySelectorAll('.pill').forEach((p) => p.classList.remove('active'));
          pill.classList.add('active');
          form.submit();
        });
      });
    });
  }

  /* ------------------------------------------------------------------ */
  /* Moderation actions (listings + users)                               */
  /* ------------------------------------------------------------------ */
  const MESSAGES = {
    feature:   ['Feature Listing?',   'Feature this listing so it appears at the top of the feed?',   'Feature',   false],
    unfeature: ['Unfeature Listing?', 'Remove featured placement from this listing?',                 'Unfeature', true],
    approve:   ['Approve Listing?',   'Set this listing status back to active?',                      'Approve',   false],
    hide:      ['Hide Listing?',      'Hide this listing from the public feed?',                      'Hide',      true],
    delete:    ['Delete Listing?',    'Permanently remove this listing from the database. This cannot be undone.', 'Delete', true],
    verify:    ['Approve Verification?', 'Mark this user as verified? Their verification badge will be visible to buyers.', 'Approve', false],
    reject:    ['Reject ID?',         'Reject this identity verification and notify the user as rejected?', 'Reject', true],
    suspend:   ['Suspend User?',      'Suspend this user? They will not be able to list or transact.', 'Suspend',  true],
    ban:       ['Hard Ban Phone?',    'Ban this phone number permanently? All their listings will be removed.', 'Ban', true],
  };

  async function moderate(action, targetId, reason = null) {
    const payload = await post('api/v1/admin/moderate.php', {
      action,
      target_id: targetId,
      reason,
    });
    toast(payload.message || 'Done', 'success');
    setTimeout(() => window.location.reload(), 650);
    return payload;
  }

  function bindModerationButtons() {
    document.querySelectorAll('[data-action][data-target]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const target = btn.dataset.target;
        const [title, msg, label, danger] = MESSAGES[action] || ['Confirm', 'Are you sure?', 'Confirm', true];

        const needsReason = ['hide', 'delete', 'reject', 'suspend', 'ban'].includes(action);
        let body = `<p>${msg}</p><p class="text-muted mono">Target: ${escapeHtml(target)}</p>`;
        if (needsReason) {
          body += `<div class="form-group"><label for="modalReason">Reason (logged in audit)</label>
                   <textarea id="modalReason" rows="2" placeholder="Optional reason..."></textarea></div>`;
        }

        openModal({
          title,
          body,
          confirmLabel: label,
          danger,
          onConfirm: () => {
            let reason = null;
            const el = document.getElementById('modalReason');
            if (el) reason = el.value.trim() || null;
            btn.disabled = true;
            moderate(action, target, reason)
              .catch((err) => {
                btn.disabled = false;
                toast(err.message || 'Action failed', 'error');
              });
          },
        });
      });
    });
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = String(str);
    return div.innerHTML;
  }

  /* ------------------------------------------------------------------ */
  /* Guard native POST forms without CSRF field (safety net)             */
  /* ------------------------------------------------------------------ */
  function initFormCsrf() {
    document.querySelectorAll('form[method="post" i]').forEach((form) => {
      if (form.querySelector('input[name="csrf_token"]')) return;
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'csrf_token';
      input.value = CSRF;
      form.appendChild(input);
    });
  }

  /* ------------------------------------------------------------------ */
  /* Init                                                                */
  /* ------------------------------------------------------------------ */
  document.addEventListener('DOMContentLoaded', () => {
    initSidebar();
    initTableSearch();
    initFilterForms();
    bindModerationButtons();
    initFormCsrf();
  });

  return { toast, post, confirmAction, openModal, closeModal, moderate };
})();
