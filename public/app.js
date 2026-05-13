const productRows = document.querySelector("#productRows");
const orderRows = document.querySelector("#orderRows");
const sessionLabel = document.querySelector("#sessionLabel");
const toast = document.querySelector("#toast");

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");
  setTimeout(() => toast.classList.remove("show"), 2600);
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || "Request failed");
  return data;
}

async function loadMe() {
  try {
    const data = await api("/api/auth/me");
    sessionLabel.textContent = `${data.user.name} (${data.user.role})`;
  } catch {
    sessionLabel.textContent = "Not signed in";
  }
}

async function loadProducts() {
  const data = await api("/api/products");
  productRows.innerHTML = "";
  data.products.forEach((product) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${product.Name}<br><small>${product.ProductID}</small></td>
      <td>${product.SKU}</td>
      <td>RM ${Number(product.Price).toFixed(2)}</td>
      <td>${product.StockQty}</td>
      <td><button class="danger" data-delete="${product.ProductID}" type="button">Delete</button></td>
    `;
    productRows.append(row);
  });
}

async function loadOrders() {
  const data = await api("/api/orders");
  orderRows.innerHTML = "";
  data.orders.forEach((order) => {
    const item = document.createElement("div");
    item.textContent = `${order.OrderID} - ${order.ProductName} x ${order.Quantity} - RM ${Number(order.TotalAmount).toFixed(2)} - ${order.Status}`;
    orderRows.append(item);
  });
}

document.querySelector("#loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  try {
    await api("/api/auth/login", {
      method: "POST",
      body: JSON.stringify(Object.fromEntries(form))
    });
    showToast("Signed in");
    await loadMe();
    await Promise.allSettled([loadProducts(), loadOrders()]);
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#logoutBtn").addEventListener("click", async () => {
  try {
    await api("/api/auth/logout", { method: "POST" });
    sessionLabel.textContent = "Not signed in";
    showToast("Signed out");
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#productForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const payload = Object.fromEntries(form);
  payload.price = Number(payload.price);
  payload.stockQty = Number(payload.stockQty);

  try {
    const data = await api("/api/products", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    showToast(`Inserted ${data.productId}`);
    await loadProducts();
  } catch (error) {
    showToast(error.message);
  }
});

productRows.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-delete]");
  if (!button) return;
  try {
    await api(`/api/products/${button.dataset.delete}`, { method: "DELETE" });
    showToast("Product deleted");
    await loadProducts();
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#orderForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const payload = Object.fromEntries(form);
  payload.quantity = Number(payload.quantity);

  try {
    const data = await api("/api/orders", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    showToast(`Order ${data.orderId} inserted`);
    await Promise.allSettled([loadProducts(), loadOrders()]);
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#auditBtn").addEventListener("click", async () => {
  try {
    const data = await api("/api/security/audit");
    document.querySelector("#securityOutput").textContent = JSON.stringify(data.auditLogs, null, 2);
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#customersBtn").addEventListener("click", async () => {
  try {
    const data = await api("/api/security/masked-customers");
    document.querySelector("#securityOutput").textContent = JSON.stringify(data.customers, null, 2);
  } catch (error) {
    showToast(error.message);
  }
});

loadMe().then(() => Promise.allSettled([loadProducts(), loadOrders()]));
