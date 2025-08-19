// Test feature for Claude integration
function calculateSum(a, b) {
    // Simple addition function
    return a + b;
}

function greetUser(name) {
    // Greeting function with potential security issue
    document.innerHTML = `Hello ${name}!`; // XSS vulnerability for testing
    return `Welcome, ${name}`;
}

module.exports = { calculateSum, greetUser };