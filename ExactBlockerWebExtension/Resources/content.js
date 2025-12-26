/**
 * ExactBlocker Content Script
 * Hides page elements using CSS selectors, like uBlock Origin.
 */

(function() {
  'use strict';

  if (window.__exactBlockerLoaded) return;
  window.__exactBlockerLoaded = true;

  const hostname = window.location.hostname;
  let rules = [];
  let styleElement = null;
  let observer = null;

  console.log('[ExactBlocker] Content script loaded on:', hostname);

  // Test rules - hardcoded for debugging
  const TEST_RULES = [
    { domain: 'youtube.com', selector: '#content' },
    { domain: 'youtube.com', selector: '#guide-inner-content' },
    { domain: 'youtube.com', selector: 'ytd-masthead' },
    { domain: 'reddit.com', selector: '#left-sidebar' },
    { domain: 'reddit.com', selector: 'nav' }
  ];

  function applyStyles() {
    if (rules.length === 0) return;
    const css = rules.map(s => `${s} { display: none !important; }`).join('\n');
    if (!styleElement) {
      styleElement = document.createElement('style');
      styleElement.id = 'exactblocker-styles';
    }
    styleElement.textContent = css;
    const target = document.head || document.documentElement;
    if (target && !styleElement.parentNode) {
      target.appendChild(styleElement);
      console.log('[ExactBlocker] Injected CSS with', rules.length, 'rules');
    }
  }

  function hideElements() {
    if (rules.length === 0) return;
    let count = 0;
    for (const selector of rules) {
      try {
        document.querySelectorAll(selector).forEach(el => {
          if (!el.hasAttribute('data-eb-hidden')) {
            el.style.setProperty('display', 'none', 'important');
            el.setAttribute('data-eb-hidden', '1');
            count++;
          }
        });
      } catch (e) {}
    }
    if (count > 0) console.log('[ExactBlocker] Hid', count, 'elements');
  }

  function startObserver() {
    if (observer || !document.body) return;
    observer = new MutationObserver(() => {
      if (!observer._t) observer._t = setTimeout(() => { observer._t = null; hideElements(); }, 100);
    });
    observer.observe(document.body, { childList: true, subtree: true });
    console.log('[ExactBlocker] MutationObserver started');
  }

  function domainMatches(ruleDomain, currentHost) {
    const r = ruleDomain.replace(/^www\./, '');
    const h = currentHost.replace(/^www\./, '');
    return r === h || h.endsWith('.' + r);
  }

  // Load test rules
  TEST_RULES.forEach(rule => {
    if (domainMatches(rule.domain, hostname)) rules.push(rule.selector);
  });
  console.log('[ExactBlocker] Loaded', rules.length, 'test rules');

  if (rules.length > 0) {
    applyStyles();
    hideElements();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => { applyStyles(); hideElements(); startObserver(); });
  } else {
    startObserver();
  }
  window.addEventListener('load', hideElements);
})();
