console.log("ExactBlocker: CONTENT SCRIPT RUNNING on " + window.location.href);

// Immediately try to hide #content
document.addEventListener('DOMContentLoaded', function() {
    console.log("ExactBlocker: DOM ready, hiding #content");
    var content = document.getElementById('content');
    if (content) {
        content.style.display = 'none';
        console.log("ExactBlocker: #content hidden!");
    } else {
        console.log("ExactBlocker: #content not found");
    }
});
