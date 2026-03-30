// ============================================================
// umami-events.js  — Medical Calculators India
// Place at: /assets/umami-events.js
//
// Your Umami script tag already handles page views automatically.
// This file adds CUSTOM EVENT TRACKING for every calculator.
//
// Load this AFTER your Umami script tag:
//   <script src="assets/umami-events.js"></script>
// ============================================================


// ── SAFE WRAPPER ─────────────────────────────────────────────
// Waits for Umami to be ready before firing events.
// Prevents "umami is not defined" errors if script loads slowly.
function uTrack(eventName, props) {
  if (typeof window.umami !== 'undefined') {
    window.umami.track(eventName, props || {});
  } else {
    // Queue it — retry once after 1s in case umami loads late
    setTimeout(function() {
      if (typeof window.umami !== 'undefined') {
        window.umami.track(eventName, props || {});
      }
    }, 1000);
  }
}


// ── CALCULATOR USED ───────────────────────────────────────────
// Call this inside each calc() function when result is shown.
// eventName convention: "calc_[toolname]"
// props: any useful result values (score, risk, etc.)
function trackCalc(toolName, props) {
  uTrack('calc_' + toolName, props || {});
}


// ── SHARE (WhatsApp) ──────────────────────────────────────────
function trackShare(toolName) {
  uTrack('share_whatsapp', { tool: toolName });
}


// ── PRINT ─────────────────────────────────────────────────────
function trackPrint(toolName) {
  uTrack('print', { tool: toolName });
}


// ── AUTO-TRACK OUTBOUND WHATSAPP CLICKS ──────────────────────
// Fires automatically on any wa.me link click — no extra code needed.
document.addEventListener('DOMContentLoaded', function() {
  document.addEventListener('click', function(e) {
    const a = e.target.closest('a[href]');
    if (!a) return;
    if ((a.href || '').startsWith('https://wa.me')) {
      const tool = document.body.dataset.tool || document.documentElement.dataset.tool || 'unknown';
      trackShare(tool);
    }
  });
});
