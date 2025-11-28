// مسیر فعلی صفحه
const pathName = location.pathname;

// -----------------------------
// ساخت فاکتور (صفحه index.html)
// -----------------------------
async function createInvoice() {
    const amount = Number(document.getElementById("amount").value || 0);
    const phone = document.getElementById("phone").value.trim();
    const merchant_id = Number(document.getElementById("merchant_id").value || 1);

    if (!amount || amount <= 0) {
        alert("لطفاً مبلغ معتبر وارد کنید.");
        return;
    }

    try {
        const res = await fetch("/api/create", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({amount, phone, merchant_id})
        });

        const data = await res.json();

        if (data.error) {
            document.getElementById("indexResult").innerHTML = "❌ خطا: " + data.error;
            return;
        }

        document.getElementById("indexResult").innerHTML =
            `✔ لینک پرداخت ساخته شد:<br>
            <a href="${data.pay_url}" target="_blank">${data.pay_url}</a><br>
            مبلغ یکتا: ${data.unique_amount} ریال`;
    } catch (e) {
        document.getElementById("indexResult").innerHTML = "⚠ خطا در اتصال به سرور";
    }
}

// ---------------------------------------------
// بارگذاری اطلاعات فاکتور (صفحه invoice.html)
// ---------------------------------------------
async function loadInvoiceInfo() {
    if (!pathName.startsWith("/invoice/")) return;

    const token = pathName.replace("/invoice/", "");

    try {
        const res = await fetch("/api/check", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({token})
        });

        const data = await res.json();

        if (data.error) {
            document.getElementById("invMsg").innerHTML = "❌ فاکتور یافت نشد";
            return;
        }

        document.getElementById("invToken").innerText = token;
        document.getElementById("invAmount").innerText = data.amount + " ریال";
        document.getElementById("invUnique").innerText = data.unique_amount + " ریال";
        document.getElementById("invPhone").innerText = data.phone || "-";

        updateStatusBadge(data.status);

    } catch (e) {
        document.getElementById("invMsg").innerHTML = "⚠ خطا در دریافت اطلاعات";
    }
}

// وضعیت پرداخت
function updateStatusBadge(status) {
    const el = document.getElementById("invStatus");
    if (!el) return;

    if (status === "paid") {
        el.innerHTML = "پرداخت شده";
        el.className = "badge badge-paid";
    } else {
        el.innerHTML = "در انتظار پرداخت";
        el.className = "badge badge-pending";
    }
}

// بررسی وضعیت فاکتور
async function checkInvoiceStatus() {
    const token = pathName.replace("/invoice/", "");

    try {
        const res = await fetch("/api/check", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify({token})
        });
        const data = await res.json();

        updateStatusBadge(data.status);

        if (data.status === "paid") {
            document.getElementById("invMsg").innerHTML = "✔ پرداخت با موفقیت ثبت شد";
        } else {
            document.getElementById("invMsg").innerHTML = "⏳ هنوز پرداخت نشده است";
        }
    } catch (e) {
        document.getElementById("invMsg").innerHTML = "⚠ خطا در بررسی وضعیت";
    }
}

// ---------------------
// ورود مدیر (admin)
// ---------------------
async function adminLogin() {
    const user = document.getElementById("adminUser").value;
    const pass = document.getElementById("adminPass").value;

    const res = await fetch("/admin/login", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({user, pass})
    });

    const data = await res.json();

    if (data.ok) {
        localStorage.setItem("admin", "1");
        location.href = "/admin/dashboard.html";
    } else {
        document.getElementById("adminLoginMsg").innerHTML = "❌ ورود ناموفق";
    }
}

// افزودن کارت جدید توسط مدیر
async function adminAddCard() {
    const number = document.getElementById("cardNumber").value;
    const bank = document.getElementById("cardBank").value;
    const owner = document.getElementById("cardOwner").value;

    const res = await fetch("/admin/add-card", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({number, bank, owner})
    });

    const j = await res.json();

    if (j.ok) {
        document.getElementById("adminCardMsg").innerHTML = "✔ کارت افزوده شد";
    } else {
        document.getElementById("adminCardMsg").innerHTML = "❌ خطا در افزودن کارت";
    }
}

// بارگذاری فاکتورهای مدیر
async function adminLoadInvoices() {
    if (!pathName.endsWith("/admin/dashboard.html")) return;

    const res = await fetch("/admin/transactions");
    const rows = await res.json();

    const tbody = document.querySelector("#adminInvTable tbody");
    let html = "";

    rows.forEach(r => {
        html += `
            <tr>
                <td>${r.id}</td>
                <td>${r.amount}</td>
                <td>${r.unique_amount}</td>
                <td>${r.status}</td>
                <td>${r.created_at}</td>
            </tr>`;
    });

    tbody.innerHTML = html;
}

// -------------------------
// ورود مرچنت (merchant)
// -------------------------
async function merchantLogin() {
    const code = document.getElementById("merchantCode").value;

    const res = await fetch("/merchant/login", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({merchant_code: code})
    });

    const data = await res.json();

    if (data.ok) {
        localStorage.setItem("merchant_id", data.merchant.id);
        location.href = "/merchant/dashboard.html";
    } else {
        document.getElementById("merchantLoginMsg").innerHTML = "❌ کد مرچنت اشتباه است";
    }
}

// بارگذاری فاکتورهای مرچنت
async function merchantLoadInvoices() {
    if (!pathName.endsWith("/merchant/dashboard.html")) return;

    const merchant_id = localStorage.getItem("merchant_id");

    const res = await fetch("/merchant/invoices", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({merchant_id})
    });

    const rows = await res.json();

    const tbody = document.querySelector("#merchantInvTable tbody");
    let html = "";

    rows.forEach(r => {
        html += `
            <tr>
                <td>${r.id}</td>
                <td>${r.amount}</td>
                <td>${r.unique_amount}</td>
                <td>${r.status}</td>
                <td>${r.created_at}</td>
            </tr>`;
    });

    tbody.innerHTML = html;
}

// -----------------------------
// اجرای خودکار صفحه مناسب
// -----------------------------
if (pathName.startsWith("/invoice/")) loadInvoiceInfo();
adminLoadInvoices();
merchantLoadInvoices();
