// public/js/navbar.js

document.addEventListener("DOMContentLoaded", () => {
  const navContainer = document.getElementById("navbar");
  const token = localStorage.getItem("token");

  const navHTML = `
    <nav style="background-color: #631bff;" class="shadow-lg sticky top-0 z-50">
      <div class="px-6 py-4 flex justify-between items-center max-w-6xl mx-auto">
        <!-- Logo / Title -->
        <div class="flex items-center space-x-4">
          <a href="index.html" class="flex items-center space-x-2">
            <h1 class="text-2xl font-bold text-white">BlogSphere</h1>
            <span class="material-symbols-outlined text-white">code</span>
          </a>
        </div>

        <!-- Auth Buttons -->
        <div class="flex items-center space-x-4" id="auth-buttons">
          ${token ? `
            ${window.location.pathname.includes("profile.html") ? "" : `
              <a href="profile.html" class="bg-white text-primary-700 px-4 py-2 rounded-lg hover:bg-gray-100">My Profile</a>
            `}
            <button id="logout-btn" class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700">Logout</button>
          ` : `
            <a href="login.html" class="bg-white text-primary-700 px-4 py-2 rounded-lg hover:bg-gray-100">Login</a>
            <a href="signup.html" class="bg-white text-primary-700 px-4 py-2 rounded-lg hover:bg-gray-100">Sign Up</a>
          `}
        </div>
      </div>
    </nav>
  `;

  navContainer.innerHTML = navHTML;

  if (token) {
    document.getElementById("logout-btn").addEventListener("click", () => {
      localStorage.removeItem("token");
      alert("Logged out successfully");
      window.location.href = "index.html";
    });
  }
});
