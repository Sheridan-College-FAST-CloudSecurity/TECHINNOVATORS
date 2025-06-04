document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("signup-form");
  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    const username = document.getElementById("signup-username").value.trim();
    const email = document.getElementById("signup-email").value.trim();
    const password = document.getElementById("signup-password").value.trim();

    try {
      // Step 1: Signup
      const signupResp = await fetch(`${window.API_BASE}/api/v1/signup`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, email, password }),
      });

      if (!signupResp.ok) throw new Error("Signup failed");

      // Step 2: Auto-login
      const loginResp = await fetch(`${window.API_BASE}/api/v1/login`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ username, password }),
      });

      if (!loginResp.ok) throw new Error("Login after signup failed");

      const { access_token } = await loginResp.json();
      localStorage.setItem("token", access_token);

      alert("Signup successful! You are now logged in.");
      window.location.href = "index.html";
    } catch (err) {
      alert("Error: " + err.message);
    }
  });
});
