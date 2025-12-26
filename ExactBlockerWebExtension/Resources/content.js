(function() {
    'use strict';

    if (window.__exactBlockerLoaded) return;
    window.__exactBlockerLoaded = true;

    console.log('[ExactBlocker] Content script started');

    // 1. ASK SWIFT FOR RULES
    browser.runtime.sendNativeMessage({ type: "getRules" }).then((response) => {
        console.log('[ExactBlocker] Received response from Swift:', response);

        if (response && response.rules) {
            applyRules(response.rules);
        }
    }).catch((error) => {
        console.error('[ExactBlocker] Native messaging error:', error);
    });

    function applyRules(rules) {
        const hostname = window.location.hostname;
        // Filter rules that match the current site
        const activeRules = rules.filter(r => {
             const cleanHost = hostname.replace(/^www\./, '');
             const cleanRuleDomain = r.domain.replace(/^www\./, '');
             return cleanHost === cleanRuleDomain || cleanHost.endsWith('.' + cleanRuleDomain);
        });

        if (activeRules.length === 0) return;

        console.log(`[ExactBlocker] Found ${activeRules.length} rules for ${hostname}`);

        // Create CSS to hide elements
        const css = activeRules.map(r => `${r.selector} { display: none !important; }`).join('\n');

        const style = document.createElement('style');
        style.id = 'exactblocker-dynamic-styles';
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
    }
})();
