// public/js/profile.js

const API = window.API_BASE;
const token = localStorage.getItem("token");

let editingPostId = null;

document.addEventListener("DOMContentLoaded", () => {
  fetchUserInfo();
  fetchUserPosts();

  document.getElementById("add-post-btn").addEventListener("click", () => {
    editingPostId = null;
    document.getElementById("modal-title").textContent = "Create New Blog";
    document.getElementById("post-title").value = "";
    document.getElementById("post-content").value = "";
    document.getElementById("post-modal").classList.remove("hidden");
  });

  document.getElementById("close-modal").addEventListener("click", () => {
    document.getElementById("post-modal").classList.add("hidden");
  });

  document.getElementById("create-post-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const title = document.getElementById("post-title").value;
    const content = document.getElementById("post-content").value;

    const url = editingPostId
      ? `${API}/api/v1/posts/${editingPostId}`
      : `${API}/api/v1/posts/`;

    const method = editingPostId ? "PUT" : "POST";

    try {
      const resp = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ title, content })
      });

      if (!resp.ok) throw new Error("Failed to save post");
      document.getElementById("post-modal").classList.add("hidden");
      fetchUserPosts();
    } catch (err) {
      alert("Error: " + err.message);
    }
  });
});

async function fetchUserInfo() {
  try {
    const resp = await fetch(`${API}/api/v1/me`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await resp.json();
    document.getElementById("user-email").textContent = data.email;
  } catch {
    document.getElementById("user-email").textContent = "Failed to load user";
  }
}

async function fetchUserPosts() {
  try {
    const resp = await fetch(`${API}/api/v1/posts/my`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const posts = await resp.json();
    const container = document.getElementById("my-posts");
    container.innerHTML = "";

    posts.forEach(post => {
      const card = document.createElement("div");
      card.className = "bg-white p-4 shadow rounded relative hover:shadow-lg transition";
      card.innerHTML = `
        <h4 class="text-lg font-bold text-primary-700 mb-2 cursor-pointer">${post.title}</h4>
        <p class="text-gray-600 text-sm truncate">${post.content}</p>
        <button class="absolute top-2 right-2 text-gray-500 hover:text-primary-600 edit-btn" data-id="${post.id}">
          <i class="fas fa-edit"></i>
        </button>
      `;
      card.querySelector("h4").addEventListener("click", () => {
        window.location.href = `postview.html?id=${post.id}`;
      });
      card.querySelector(".edit-btn").addEventListener("click", () => {
        editingPostId = post.id;
        document.getElementById("modal-title").textContent = "Edit Blog";
        document.getElementById("post-title").value = post.title;
        document.getElementById("post-content").value = post.content;
        document.getElementById("post-modal").classList.remove("hidden");
      });
      container.appendChild(card);
    });

  } catch (err) {
    console.error("Failed to fetch posts:", err);
  }
}
