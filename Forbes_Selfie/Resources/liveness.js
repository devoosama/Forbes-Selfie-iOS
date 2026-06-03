// Forbes Selfie iOS — liveness.js
// Injected at document-end via WKUserScript (MAIN world, main frame only)
// Handles OZ Liveness SDK initialization and success overlay

(function() {
    'use strict';

    var SERVER_URL = 'https://houarimed.tech/api';

    // ── Get code from URL or window var ─────────────────────────────────────────
    function getCode() {
        // Set by BrowserViewController after page load
        if (window.__FORBES_CODE__) return window.__FORBES_CODE__;
        // Fallback: parse URL
        var params = new URLSearchParams(location.search);
        return params.get('code') || '';
    }

    var codeParam = getCode();
    ForbesBridge.log('liveness.js: code=' + codeParam);

    // ── Inject CSS ───────────────────────────────────────────────────────────────
    var style = document.createElement('style');
    style.textContent = [
        '@keyframes forbesRipple{0%{transform:scale(0.8);opacity:0.6}100%{transform:scale(2.4);opacity:0}}',
        '@keyframes forbesCheckDraw{to{stroke-dashoffset:0}}',
        '@keyframes forbesFadeIn{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}',
        '@keyframes forbesGlowPulse{0%,100%{box-shadow:0 0 24px #0EA5E944}50%{box-shadow:0 0 48px #0EA5E988}}',
        '@keyframes forbesSpin{to{transform:rotate(360deg)}}',
        '.forbes-overlay{position:fixed;inset:0;z-index:999999;background:rgba(5,8,20,0.97);',
            'display:flex;flex-direction:column;align-items:center;justify-content:center;',
            'font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif;}',
        '.forbes-card{background:#0A0F1E;border:1.5px solid #1A2744;border-radius:24px;',
            'padding:36px 28px;width:min(340px,90vw);position:relative;',
            'box-shadow:0 0 48px #0EA5E920;animation:forbesFadeIn 0.5s ease;}',
        '.forbes-bracket{position:absolute;width:18px;height:18px;}',
        '.forbes-bracket svg{width:100%;height:100%;}',
        '.forbes-ripple-wrap{position:relative;width:100px;height:100px;margin:0 auto 28px;}',
        '.forbes-ripple{position:absolute;inset:0;border-radius:50%;',
            'border:2px solid #0EA5E9;animation:forbesRipple 2s ease-out infinite;}',
        '.forbes-ripple:nth-child(2){animation-delay:0.6s;}',
        '.forbes-ripple:nth-child(3){animation-delay:1.2s;}',
        '.forbes-check-circle{width:100px;height:100px;border-radius:50%;',
            'background:radial-gradient(circle,#0A2540,#070D1C);',
            'border:2px solid #0EA5E9;display:flex;align-items:center;justify-content:center;',
            'position:relative;z-index:1;animation:forbesGlowPulse 2s ease-in-out infinite;}',
        '.forbes-check-svg{width:52px;height:52px;}',
        '.forbes-check-path{stroke:#10B981;stroke-width:5;stroke-linecap:round;stroke-linejoin:round;',
            'fill:none;stroke-dasharray:60;stroke-dashoffset:60;',
            'animation:forbesCheckDraw 0.7s ease forwards 0.3s;}',
        '.forbes-title{text-align:center;margin-bottom:8px;}',
        '.forbes-title-top{display:block;font-size:22px;font-weight:900;',
            'color:#fff;letter-spacing:4px;margin-bottom:2px;}',
        '.forbes-title-bot{display:block;font-size:11px;font-weight:600;',
            'color:#0EA5E9;letter-spacing:5px;}',
        '.forbes-divider{height:1px;margin:16px 0;',
            'background:linear-gradient(to right,transparent,#0EA5E9,transparent);}',
        '.forbes-sub{text-align:center;font-size:13px;color:#4A6A8A;',
            'font-weight:500;margin-bottom:20px;}',
        '.forbes-id-wrap{background:#070D1C;border:1px solid #1A2744;border-radius:12px;',
            'padding:12px 14px;margin-bottom:20px;display:flex;align-items:center;gap:10px;}',
        '.forbes-id-label{font-size:9px;color:#4A6A8A;letter-spacing:2px;',
            'font-weight:700;white-space:nowrap;}',
        '.forbes-id-val{font-size:11px;color:#38BDF8;font-family:monospace;',
            'font-weight:600;word-break:break-all;flex:1;}',
        '.forbes-copy-btn{width:100%;padding:14px;border:none;border-radius:14px;',
            'background:linear-gradient(135deg,#0EA5E9,#0055A5);',
            'color:#fff;font-size:14px;font-weight:800;letter-spacing:2px;',
            'cursor:pointer;transition:opacity 0.2s;}',
        '.forbes-copy-btn:active{opacity:0.8;}',
        '.forbes-copied{background:linear-gradient(135deg,#10B981,#059669)!important;}',
    ].join('');
    document.head.appendChild(style);

    // ── Corner bracket SVG helper ────────────────────────────────────────────────
    function bracketSVG(pos) {
        var paths = {
            tl: 'M0,14 L0,0 L14,0',
            tr: 'M0,0 L14,0 L14,14',
            bl: 'M0,0 L0,14 L14,14',
            br: 'M14,0 L14,14 L0,14'
        };
        return '<svg viewBox="0 0 14 14"><path d="' + paths[pos] + '" stroke="#F59E0B" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';
    }

    // ── Show success overlay ─────────────────────────────────────────────────────
    function showSuccess(livenessId) {
        // Remove any existing overlay
        var old = document.getElementById('forbes-success-overlay');
        if (old) old.remove();

        var overlay = document.createElement('div');
        overlay.id = 'forbes-success-overlay';
        overlay.className = 'forbes-overlay';

        var bracketPositions = [
            {pos:'tl', style:'top:16px;left:16px'},
            {pos:'tr', style:'top:16px;right:16px'},
            {pos:'bl', style:'bottom:16px;left:16px'},
            {pos:'br', style:'bottom:16px;right:16px'}
        ];

        var brackets = bracketPositions.map(function(b) {
            return '<div class="forbes-bracket" style="' + b.style + '">' + bracketSVG(b.pos) + '</div>';
        }).join('');

        overlay.innerHTML = [
            '<div class="forbes-card">',
            brackets,

            // Ripple + checkmark
            '<div class="forbes-ripple-wrap">',
            '  <div class="forbes-ripple"></div>',
            '  <div class="forbes-ripple"></div>',
            '  <div class="forbes-ripple"></div>',
            '  <div class="forbes-check-circle">',
            '    <svg class="forbes-check-svg" viewBox="0 0 52 52">',
            '      <path class="forbes-check-path" d="M12 26 L22 36 L40 18"/>',
            '    </svg>',
            '  </div>',
            '</div>',

            // Title
            '<div class="forbes-title">',
            '  <span class="forbes-title-top">SELFIE</span>',
            '  <span class="forbes-title-bot">SUCCESSFULLY DONE</span>',
            '</div>',

            '<div class="forbes-divider"></div>',

            '<p class="forbes-sub">Biometric verification complete</p>',

            // Liveness ID
            '<div class="forbes-id-wrap">',
            '  <span class="forbes-id-label">LIVENESS ID</span>',
            '  <span class="forbes-id-val" id="forbes-lid">' + livenessId + '</span>',
            '</div>',

            // Copy button
            '<button class="forbes-copy-btn" id="forbes-copy-btn">COPY ID</button>',

            '</div>'
        ].join('');

        document.body.appendChild(overlay);

        // Copy button
        document.getElementById('forbes-copy-btn').addEventListener('click', function() {
            var val = document.getElementById('forbes-lid').textContent;
            if (navigator.clipboard) {
                navigator.clipboard.writeText(val).then(function() {
                    var btn = document.getElementById('forbes-copy-btn');
                    btn.textContent = '✓ COPIED!';
                    btn.classList.add('forbes-copied');
                    setTimeout(function() {
                        btn.textContent = 'COPY ID';
                        btn.classList.remove('forbes-copied');
                    }, 2000);
                });
            } else {
                // Fallback: execCommand
                var t = document.createElement('textarea');
                t.value = val;
                document.body.appendChild(t);
                t.select();
                document.execCommand('copy');
                document.body.removeChild(t);
                var btn = document.getElementById('forbes-copy-btn');
                btn.textContent = '✓ COPIED!';
                btn.classList.add('forbes-copied');
                setTimeout(function() {
                    btn.textContent = 'COPY ID';
                    btn.classList.remove('forbes-copied');
                }, 2000);
            }
        });

        // Also notify Swift to close after short delay
        setTimeout(function() {
            ForbesBridge.close();
        }, 8000);
    }

    // ── PATCH session status (used) ──────────────────────────────────────────────
    function markSessionUsed() {
        if (!codeParam) return;
        fetch(SERVER_URL + '/updateSession/' + codeParam, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: 'used' })
        }).catch(function() {});
        ForbesBridge.updateSession('used');
    }

    // ── POST result ──────────────────────────────────────────────────────────────
    function postResult(livenessId) {
        if (!codeParam) return;
        fetch(SERVER_URL + '/result/' + codeParam, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ liveness_id: livenessId })
        }).catch(function() {});
    }

    // ── Open OZ Liveness ────────────────────────────────────────────────────────
    function openLiveness() {
        if (typeof OzLiveness === 'undefined') {
            ForbesBridge.log('OzLiveness not found, retrying...');
            setTimeout(openLiveness, 500);
            return;
        }

        ForbesBridge.log('Opening OzLiveness...');
        markSessionUsed();

        OzLiveness.open({
            lang: 'en',
            meta: codeParam ? { session_code: codeParam } : {},
            action: ['video'],
            result_mode: 'api',
            on_complete: function(result) {
                ForbesBridge.log('OZ complete: ' + JSON.stringify(result));

                var livenessId = '';

                if (result && result.event_session_id) {
                    livenessId = result.event_session_id;
                } else if (result && result.session_id) {
                    livenessId = result.session_id;
                } else if (typeof result === 'string') {
                    livenessId = result;
                }

                if (livenessId) {
                    postResult(livenessId);
                    ForbesBridge.sendResult(livenessId);
                    showSuccess(livenessId);
                } else {
                    ForbesBridge.log('No liveness ID in result: ' + JSON.stringify(result));
                    showSuccess('N/A');
                }
            }
        });
    }

    // ── Wait for DOM + OZ SDK ready ──────────────────────────────────────────────
    function waitAndOpen() {
        // Give OZ SDK a moment to initialize
        if (document.readyState === 'complete') {
            setTimeout(openLiveness, 300);
        } else {
            window.addEventListener('load', function() {
                setTimeout(openLiveness, 300);
            });
        }
    }

    // ── favicon.png?code=XXXX → navigate to actual liveness page ───────────────
    // Matches Android MainActivity: triggerUrl = scheme://host/favicon.png?code=XXXX
    // content.js (Android extension) normally handles this; on iOS we do it here.
    if (location.pathname === '/favicon.png' && location.search.indexOf('code=') !== -1) {
        var triggerCode = new URLSearchParams(location.search).get('code') || codeParam;
        ForbesBridge.log('favicon trigger detected, fetching session for code=' + triggerCode);

        fetch(SERVER_URL + '/getData/' + triggerCode)
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (data && data.success && data.url) {
                    ForbesBridge.log('Navigating to: ' + data.url);
                    window.location.href = data.url;
                } else {
                    // Fallback: go to BLS liveness page directly
                    var host = location.hostname;
                    window.location.href = location.origin + '/MAR/appointment/livenessrequest?code=' + triggerCode;
                }
            })
            .catch(function(e) {
                ForbesBridge.log('Session fetch error: ' + e);
            });

    // ── liveness page → open OZ SDK ─────────────────────────────────────────
    } else if (location.href.indexOf('plugin_liveness') !== -1 ||
               location.href.indexOf('blsinternational') !== -1 ||
               location.href.indexOf('livenessrequest') !== -1) {
        ForbesBridge.log('Liveness page detected, waiting to open...');
        waitAndOpen();
    } else {
        ForbesBridge.log('Not on liveness page: ' + location.href);
    }

})();
