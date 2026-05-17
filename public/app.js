const productRows = document.querySelector("#productRows");
const orderRows = document.querySelector("#orderRows");
const sessionLabel = document.querySelector("#sessionLabel");
const toast = document.querySelector("#toast");
const securityOutput = document.querySelector("#securityOutput");
const productForm = document.querySelector("#productForm");
const orderForm = document.querySelector("#orderForm");
const auditBtn = document.querySelector("#auditBtn");
const customersBtn = document.querySelector("#customersBtn");
let currentUser = null;

function makeSku() {
  return `SKU-FSH-${Date.now().toString().slice(-5)}`;
}

function resetUiState() {
  productRows.innerHTML = "";
  orderRows.innerHTML = "";
  securityOutput.textContent = "Security test output appears here.";
  productForm.reset();
  orderForm.reset();
}

function setFormDisabled(form, disabled) {
  [...form.elements].forEach((element) => {
    element.disabled = disabled;
  });
}

function applyRoleUi(role) {
  const canManageProducts = role === "Admin" || role === "InventoryOfficer";
  const canCreateOrders = role === "Customer";
  const canViewAudit = role === "Admin";
  const canViewMaskedCustomers = role === "Admin" || role === "InventoryOfficer";

  setFormDisabled(productForm, !canManageProducts);
  setFormDisabled(orderForm, !canCreateOrders);
  auditBtn.disabled = !canViewAudit;
  customersBtn.disabled = !canViewMaskedCustomers;
}

function prepareRoleInputs(role) {
  resetUiState();
  applyRoleUi(role);
  if (role === "Admin" || role === "InventoryOfficer") {
    productForm.elements.sku.value = makeSku();
  }
}

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
    currentUser = data.user;
    return data.user;
  } catch {
    sessionLabel.textContent = "Not signed in";
    currentUser = null;
    return null;
  }
}

async function loadProducts() {
  const data = await api("/api/products");
  productRows.innerHTML = "";
  data.products.forEach((product) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${product.ProductID}</td>
      <td>${product.Name}</td>
      <td>${product.SKU}</td>
      <td>RM ${Number(product.Price).toFixed(2)}</td>
      <td>${product.StockQty}</td>
      <td><button class="danger" data-delete="${product.ProductID}" type="button" ${currentUser?.role === "Admin" ? "" : "disabled"}>Delete</button></td>
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
    const user = await loadMe();
    prepareRoleInputs(user?.role);
    await Promise.allSettled([loadProducts(), loadOrders()]);
  } catch (error) {
    showToast(error.message);
  }
});

document.querySelector("#logoutBtn").addEventListener("click", async () => {
  try {
    await api("/api/auth/logout", { method: "POST" });
    sessionLabel.textContent = "Not signed in";
    currentUser = null;
    resetUiState();
    applyRoleUi(null);
    showToast("Signed out");
  } catch (error) {
    sessionLabel.textContent = "Not signed in";
    currentUser = null;
    resetUiState();
    applyRoleUi(null);
    showToast(error.message);
  }
});

productForm.addEventListener("submit", async (event) => {
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

orderForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const payload = Object.fromEntries(form);
  payload.quantity = Number(payload.quantity);

  try {
    if (!Number.isInteger(payload.quantity) || payload.quantity < 1) {
      throw new Error("Quantity must be at least 1.");
    }

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
    securityOutput.textContent = JSON.stringify(data.auditLogs, null, 2);
  } catch (error) {
    securityOutput.textContent = "Security test output appears here.";
    showToast(error.message);
  }
});

document.querySelector("#customersBtn").addEventListener("click", async () => {
  try {
    const data = await api("/api/security/masked-customers");
    securityOutput.textContent = JSON.stringify(data.customers, null, 2);
  } catch (error) {
    securityOutput.textContent = "Security test output appears here.";
    showToast(error.message);
  }
});

resetUiState();
applyRoleUi(null);
loadMe().then((user) => {
  prepareRoleInputs(user?.role);
  return Promise.allSettled([loadProducts(), loadOrders()]);
});
