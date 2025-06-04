// public/js/singlePost.js  ---------------------------
import { apiGet } from "./api.js";          // same helper used elsewhere

const API  = window.API_BASE;
const postId = new URLSearchParams(location.search).get("postId");

const postBox     = document.getElementById("postContainer");
const commentBox  = document.getElementById("commentsContainer");

if (!postId) {
  postBox.textContent = "No post id in URL.";
  commentBox.classList.add("hidden");
} else {
  loadPost();
  loadComments();
}

async function loadPost() {
  try {
    const post = await apiGet(`${API}/api/v1/posts/${postId}`);
    postBox.innerHTML = `
      <h2 class="text-3xl font-bold mb-4">${post.title}</h2>
      <p class="text-gray-600 mb-8">${post.content}</p>
    `;
  } catch (err) {
    postBox.textContent = "Failed to load post.";
  }
}

async function loadComments() {
  try {
    const comments = await apiGet(`${API}/api/v1/comments/post/${postId}`);
    commentBox.innerHTML = comments
      .map(c => `<div class="mb-4 p-4 border rounded">
                   <p class="font-semibold">${c.author_username}</p>
                   <p>${c.content}</p>
                 </div>`)
      .join("");
  } catch {
    commentBox.textContent = "Failed to load comments.";
  }
}
