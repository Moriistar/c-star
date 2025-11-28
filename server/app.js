const express = require('express');
const path = require('path');
const cors = require('cors');
const body = require('body-parser');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(body.json());

// سرو استاتیک
app.use(express.static(path.join(__dirname, "../public")));

// API ها
app.use("/api", require("./routes/api"));
app.use("/admin", require("./routes/admin"));
app.use("/merchant", require("./routes/merchant"));

// صفحه فاکتور داینامیک
app.get("/invoice/:token", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/invoice.html"));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log("🚀 C-STAR PRO is running on port " + PORT)
);
