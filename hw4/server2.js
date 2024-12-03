require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');
const multer = require('multer');
const os = require('os');
const path = require('path');

const app = express();
const port = 8080;
const host = '192.168.105.2';

// PostgreSQL connection
const pool = new Pool({
    user: 'root',
    host: 'localhost',
    database: 'sa-hw4',
    password: process.env.PGPASSWORD,
    port: 5432,
});

// Configure file upload
const uploadDir = "/home/judge/upload";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}
const upload = multer({ dest: uploadDir });

// Routes

// GET /ip
app.get("/ip", (req, res) => {
  const hostname = os.hostname();
  const networkInterfaces = os.networkInterfaces();
  const ip = networkInterfaces["em2"]
  const serverIp = ip ? ip[0].address : "127.0.0.1";

  res.json({
    ip: serverIp,
    hostname: hostname,
  });
});

// GET /file/{filename}
app.get("/file/:filename", (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(uploadDir, filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).send("File not found");
  }

  res.sendFile(path.resolve(filePath));
});

// POST /upload
app.post("/upload", upload.single("file"), (req, res) => {
  const file = req.file;

  if (!file) {
    return res.status(400).send("No file uploaded");
  }

  res.json({
    filename: file.filename,
    success: true,
  }); 
});

// GET /db/{username}
app.get("/db/:username", async (req, res) => {
  const username = req.params.username;

  try {
    const result = await pool.query("SELECT * FROM \"user\" WHERE name = $1", [username]);

    if (result.rows.length === 0) {
      return res.status(404).send("User not found");
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send("Database query failed");
  }
});

// Start server
app.listen(port, host, () => {
  console.log(`Server is running on http://192.168.105.2:${port}`);
});