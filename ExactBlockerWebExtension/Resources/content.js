(function() {
    console.log("ExactBlocker: Content script loaded on " + window.location.href);

    // Simple test - just log that we're running
    document.addEventListener('DOMContentLoaded', function() {
        console.log("ExactBlocker: DOM ready");
    });

    // Also try immediate action
    if (document.body) {
        document.body.style.border = "5px solid red";
        console.log("ExactBlocker: Added red border to body");
    }
})();
