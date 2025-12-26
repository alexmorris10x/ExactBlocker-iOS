/**
 * ExactBlocker Background Script
 */
console.log('[ExactBlocker] Background script loaded');

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('[ExactBlocker] Received message:', request);
  if (request.greeting === "hello") {
    return Promise.resolve({ farewell: "goodbye" });
  }
  return false;
});
