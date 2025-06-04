

// Helper to format date/times
function formatDateTime(isoString) {
  const date = new Date(isoString);
  return date.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

// Read the “id” query parameter from URL
function getPostIdFromURL() {
  const params = new URLSearchParams(window.location.search);
  return params.get("id");
}

// Build a single comment HTML string
function createCommentHTML(comment) {
  /*
    comment object fields (from FastAPI):
      {
        id,
        content,
        post_id,
        user_id,
        created_at
      }
  */
  return `
    <div class="flex space-x-4">
      <!-- Placeholder avatar based on user_id -->
      <img
        src="https://i.pravatar.cc/40?u=${comment.user_id}"
        alt="Commenter avatar"
        class="w-10 h-10 rounded-full flex-shrink-0"
      />
      <div class="flex-1">
        <div class="bg-gray-50 rounded-lg p-4">
          <div class="flex items-center space-x-2 mb-2">
            <span class="font-medium text-gray-900">User ${comment.user_id}</span>
            <span class="text-gray-500 text-sm">${formatDateTime(comment.created_at)}</span>
          </div>
          <p class="text-gray-700">${comment.content}</p>
        </div>
      </div>
    </div>
  `;
}

// Fetch and render the post’s details (title, content, author, date)
async function fetchAndRenderPost() {
  const postId = getPostIdFromURL();
  if (!postId) {
    console.error("No post ID in URL");
    return;
  }

  try {
    const response = await fetch(`${API}/api/v1/posts/${postId}`, {
      headers: {
        "Content-Type": "application/json",
        // "Authorization": `Bearer ${localStorage.getItem("token")}`
      },
    });
    if (!response.ok) {
      throw new Error(`Failed to load post (${response.status})`);
    }
    const post = await response.json();
    const container = document.getElementById("post-container");

    // Insert post HTML (simple layout; tweak as needed)
    container.innerHTML = `
      <div class="mb-6">
        <h2 class="text-4xl font-bold text-gray-900 mb-2">${post.title}</h2>
        <div class="text-gray-500 text-sm">
          By User ${post.author_id} • ${new Date(post.created_at).toLocaleDateString()}
        </div>
      </div>
      <div class="prose max-w-none text-gray-700">
        ${post.content}
      </div>
      <div class="mt-6 text-gray-500 text-sm flex items-center space-x-4">
        <i class="fa-regular fa-heart"></i>
        <span>${post.like_count}</span>
      </div>
    `;
  } catch (err) {
    console.error("Error fetching post:", err);
    document.getElementById("post-container").innerHTML =
      "<p class='text-red-500'>Failed to load post.</p>";
  }
}

// Fetch and render comments for this post
async function fetchAndRenderComments() {
  const postId = getPostIdFromURL();
  if (!postId) return;

  try {
    const response = await fetch(`${API}/api/v1/comments/post/${postId}`, {
      headers: {
        "Content-Type": "application/json",
      },
    });
    if (!response.ok) {
      throw new Error(`Failed to load comments (${response.status})`);
    }
    const comments = await response.json(); // array of { id, content, post_id, user_id, created_at }

    const container = document.getElementById("comments-container");
    container.innerHTML = ""; // Clear existing

    if (comments.length === 0) {
      container.innerHTML = "<p class='text-gray-500'>No comments yet.</p>";
      return;
    }

    comments.forEach((comment) => {
      const html = createCommentHTML(comment);
      container.insertAdjacentHTML("beforeend", html);
    });
  } catch (err) {
    console.error("Error fetching comments:", err);
    document.getElementById("comments-container").innerHTML =
      "<p class='text-red-500'>Failed to load comments.</p>";
  }
}

// Handle submission of a new comment
async function handleNewComment(event) {
  event.preventDefault();
  const postId = getPostIdFromURL();
  if (!postId) return;

  const contentInput = document.getElementById("comment-content");
  const content = contentInput.value.trim();
  if (!content) return;

  try {
    const token = localStorage.getItem("token"); // assume JWT stored under “token”
    const response = await fetch(`${API}/api/v1/comments/`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // send JWT if required by your backend
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        content,
        post_id: Number(postId),
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to post comment (${response.status})`);
    }
    const newComment = await response.json(); // the newly created comment

    // Prepend the new comment to the list
    const container = document.getElementById("comments-container");
    const html = createCommentHTML(newComment);
    container.insertAdjacentHTML("afterbegin", html);

    // Clear the textarea
    contentInput.value = "";
  } catch (err) {
    console.error("Error posting comment:", err);
    alert("Failed to post comment. Make sure you are logged in.");
  }
}

// Initialize on DOMContentLoaded
window.addEventListener("DOMContentLoaded", () => {
  fetchAndRenderPost();
  fetchAndRenderComments();

  // Attach form submit handler
  const form = document.getElementById("new-comment-form");
  if (form) {
    form.addEventListener("submit", handleNewComment);
  }
});
