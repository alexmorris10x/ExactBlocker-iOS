console.log("ExactBlocker: Content script running on " + window.location.href);

// Hide #content on YouTube
document.addEventListener('DOMContentLoaded', function() {
    console.log("ExactBlocker: DOM ready");
    var content = document.getElementById('content');
    if (content) {
        content.style.display = 'none';
        console.log("ExactBlocker: #content hidden!");
    }
});
