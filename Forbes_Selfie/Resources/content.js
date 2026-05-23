// Forbes Selfie iOS — content.js
// Injected at document-start via WKUserScript (MAIN world)
// Sets up webkit.messageHandlers bridge helpers

(function() {
    'use strict';

    // ── Bridge helpers ──────────────────────────────────────────────────────────

    window.ForbesBridge = {
        // Send liveness result back to Swift
        sendResult: function(livenessId) {
            try {
                window.webkit.messageHandlers.livenessResult.postMessage({
                    liveness_id: livenessId
                });
            } catch(e) { console.error('[Forbes] sendResult error:', e); }
        },

        // Notify session status change
        updateSession: function(status) {
            try {
                window.webkit.messageHandlers.sessionUpdate.postMessage({
                    status: status
                });
            } catch(e) {}
        },

        // Close the browser
        close: function() {
            try {
                window.webkit.messageHandlers.close.postMessage({});
            } catch(e) {}
        },

        // Log helper
        log: function(msg) {
            try {
                window.webkit.messageHandlers.log.postMessage(String(msg));
            } catch(e) {}
            console.log('[Forbes]', msg);
        }
    };

    // Expose console.log to Swift bridge in debug builds
    var _origLog = console.log;
    console.log = function() {
        _origLog.apply(console, arguments);
        try {
            var msg = Array.prototype.join.call(arguments, ' ');
            if (msg.indexOf('[Forbes]') !== -1) {
                window.webkit.messageHandlers.log.postMessage(msg);
            }
        } catch(e) {}
    };

    ForbesBridge.log('content.js loaded on: ' + location.href);

})();
