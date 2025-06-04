// public/js/login.js
document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("login-form");

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const username = document.getElementById("login-username").value.trim();
    const password = document.getElementById("login-password").value.trim();

    try {
      const resp = await fetch(`${window.API_BASE}/api/v1/login`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ username, password }),
      });

      if (!resp.ok) throw new Error("Login failed");

      const { access_token } = await resp.json();
      localStorage.setItem("token", access_token);

      alert("Login successful!");
      window.location.href = "index.html";
    } catch (err) {
      alert("Error: " + err.message);
    }
  });
});
