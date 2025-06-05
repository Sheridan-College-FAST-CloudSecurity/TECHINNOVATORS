/* public/js/posts.js
   ---------------------------------------------------------- */
/*const API = window.API_BASE;*/
const feedContainerId = "postsContainer";

/* ------------ helper ------------- */
async function apiGet(path) {
  const resp = await fetch(`${window.API_BASE}${path}`);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  return resp.json();
}

/* ------------ UI helpers ---------- */
function createPostCard({ id, title, content, like_count }) {
  return `
    <article class="bg-white rounded-xl shadow hover:shadow-lg p-6">
      <h4 class="text-xl font-bold mb-2">${title}</h4>
      <p class="text-gray-600 mb-4 line-clamp-3">${content}</p>
      <a href="postview.html?id=${id}"
         class="text-primary-600 hover:underline">Read more</a>
      <span class="ml-2 text-sm text-gray-500">${like_count ?? 0} ❤</span>
    </article>`;
}

/* ------------ main feed ------------ */
async function fetchAndRenderPosts() {
  const box = document.getElementById(feedContainerId);
  if (!box) return;               // not on index.html → nothing to do

  try {
    const posts = await apiGet("/api/v1/posts/");
    box.innerHTML =
      posts.length
        ? posts.map(createPostCard).join("")
        : "<p>No posts yet.</p>";
  } catch (err) {
    console.error("Error fetching posts:", err);
    box.innerHTML =
      "<p class='text-red-600'>Failed to load posts – see console.</p>";
  }
}

/* run after DOM is ready */
document.addEventListener("DOMContentLoaded", fetchAndRenderPosts);
