// public/js/auth.js
const API = window.API_BASE;
const LS_TOKEN_KEY = "token";

// Login logic
async function loginUser(event) {
  event.preventDefault();

  const username = document.getElementById("username")?.value.trim();
  const password = document.getElementById("password")?.value.trim();
  if (!username || !password) {
    alert("Username & password are required");
    return;
  }

  try {
    const resp = await fetch(`${API}/api/v1/login`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ username, password }),
    });

    if (!resp.ok) {
      const { detail = resp.statusText } = await resp.json().catch(() => ({}));
      throw new Error(detail);
    }

    const { access_token, token_type } = await resp.json();
    localStorage.setItem(LS_TOKEN_KEY, access_token);
    alert("Logged in successfully!");
    console.log(`⇢ stored ${token_type} token in localStorage`);

    window.location.href = "index.html"; // Redirect to feed
  } catch (err) {
    console.error("Login failed:", err);
    alert(
      `Login failed: ${err.message || "network error"}\n` +
      `Is the backend running at\n${API}\n` +
      "and accessible from your front‑end?"
    );
  }
}

// Attach login form handler
document.getElementById("loginForm")?.addEventListener("submit", loginUser);
