<?php
/**
 * Shared footer + script includes.
 * Closes the <main>/<div>/<body> opened in header.php.
 */
?>
    </main>
    <footer class="app-footer">
      <span>&copy; <?= date('Y') ?> MADEALS &middot; Zimbabwe P2P Marketplace</span>
    </footer>
  </div>
</div>

<div class="modal-overlay" id="modalOverlay" hidden>
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
    <div class="modal-header">
      <h2 id="modalTitle">Confirm</h2>
      <button class="modal-close" data-close-modal aria-label="Close">&times;</button>
    </div>
    <div class="modal-body" id="modalBody"></div>
    <div class="modal-footer">
      <button class="btn btn-ghost" data-close-modal>Cancel</button>
      <button class="btn btn-danger" id="modalConfirm">Confirm</button>
    </div>
  </div>
</div>

<div class="toast" id="toast" role="status" aria-live="polite"></div>

<script src="assets/js/app.js"></script>
</body>
</html>
