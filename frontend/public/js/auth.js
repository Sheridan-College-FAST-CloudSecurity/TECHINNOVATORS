// public/js/auth.js
// ────────────────────────────────────────────────
// Expects window.API_BASE to be injected by config.js
// DO NOT redeclare that global – just read it.

const API          = window.API_BASE;    // shorthand used everywhere below
const LS_TOKEN_KEY = "token";            // key shared by postView.js, etc.

// ———————————————————————————————————————————————————————————
// POST /login  (OAuth2‑password flow)
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
      body: new URLSearchParams({ username, password })
    });

    if (!resp.ok) {
      // FastAPI error shape: { "detail": "..." }
      const { detail = resp.statusText } = await resp.json().catch(() => ({}));
      throw new Error(detail);
    }

    const { access_token, token_type } = await resp.json();
    localStorage.setItem(LS_TOKEN_KEY, access_token);
    alert("Logged in successfully!");
    console.log(`⇢ stored ${token_type} token in localStorage`);
  } catch (err) {
    console.error("Login failed:", err);
    alert(
      `Login failed: ${err.message || "network error"}\n` +
      `Is the backend running at\n${API}\n` +
      "and accessible from your front‑end?"
    );
  }
}

// attach handler only if the form exists on this page
document.getElementById("loginForm")?.addEventListener("submit", loginUser);
