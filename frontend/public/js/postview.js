/* public/js/postview.js
   ───────────────────────────────────────────────
   Handles: (a) display single post
            (b) list / add comments
*/

// ---------- helper wrappers ----------
async function apiGet(path) {
  const resp = await fetch(`${window.API_BASE}${path}`);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  return resp.json();
}

async function apiPost(path, payload, auth = false) {
  const opt = {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  };

  if (auth) {
    const token = localStorage.getItem("token");
    if (!token) throw new Error("Not logged in");
    opt.headers.Authorization = `Bearer ${token}`;
  }

  const resp = await fetch(`${window.API_BASE}${path}`, opt);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  return resp.json();
}

// ---------- main logic ----------
async function initPage() {
  const postBox = document.getElementById("post-container");
  const commentsBox = document.getElementById("comments-container");
  const form = document.getElementById("new-comment-form");

  if (!postBox || !commentsBox) {
    console.error("Required container(s) missing in HTML");
    return;
  }

  const params = new URLSearchParams(window.location.search);
  const id = params.get("id");

  if (!id) {
    postBox.innerHTML = "<p class='text-red-600'>No post ID in URL</p>";
    return;
  }

  try {
    const post = await apiGet(`/api/v1/posts/${id}`);
    const comments = await apiGet(`/api/v1/comments/post/${id}`);

    renderPost(post, postBox);
    renderComments(comments, commentsBox);
  } catch (err) {
    console.error("Error loading post:", err);
    postBox.innerHTML = `<p class='text-red-600'>Failed to load post: ${err.message}</p>`;
  }

  if (form) {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const content = document.getElementById("comment-content")?.value.trim();
      if (!content) return;

      try {
        await apiPost("/api/v1/comments/", { post_id: id, content }, true);
        document.getElementById("comment-content").value = "";

        const updatedComments = await apiGet(`/api/v1/comments/post/${id}`);
        renderComments(updatedComments, commentsBox);
      } catch (err) {
        alert(`Failed to add comment: ${err.message}`);
      }
    });
  }
}

// ---------- render helpers ----------
function renderPost({ title, content, author_id, created_at }, container) {
  container.innerHTML = `
    <h2 class="text-3xl font-bold mb-4">${title}</h2>
    <p class="text-gray-500 text-sm mb-4">
      by <span class="font-medium">User ${author_id}</span> •
      ${new Date(created_at).toLocaleDateString()}
    </p>
    <div class="prose max-w-none">${content}</div>
  `;
}

function renderComments(comments, container) {
  container.innerHTML = comments.length
    ? comments.map(commentCard).join("")
    : "<p class='text-gray-500'>No comments yet.</p>";
}

function commentCard({ author_id, content, created_at }) {
  return `
    <div class="border rounded-lg p-4 mb-4">
      <p class="text-sm text-gray-500 mb-2">
        <span class="font-medium">User ${author_id}</span> •
        ${new Date(created_at).toLocaleString()}
      </p>
      <p>${content}</p>
    </div>
  `;
}

// ---------- initialize ----------
document.addEventListener("DOMContentLoaded", initPage);
