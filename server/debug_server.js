// ==============================
//      VI FULL LIVE DEBUG SERVER
// ==============================
const http = require("http");
const fs = require("fs");
const path = require("path");

const BASE = "/data/data/com.termux/files/home/AppProjects/VI/app/src/main/assets";

// --------- Utility to log JS errors ---------
function logJS(data) {
  console.log("\n===============================");
  console.log("🔥 LIVE JS LOG");
  console.log("Time:", new Date().toLocaleTimeString());
  console.log("Type:", data.type);
  console.log("Message:", data.message);
  if (data.file) console.log("File:", data.file);
  if (data.line) console.log("Line:", data.line);
  if (data.stack) console.log("Stack:", data.stack);
  console.log("===============================\n");
}

// --------- Pre-check JS files ---------
function preCheckJS() {
  console.log("🟢 Pre-scanning JS files for syntax, globals, duplicates...\n");

  const JS_DIR = path.join(BASE, "js");
  const files = fs.readdirSync(JS_DIR).filter(f => f.endsWith(".js"));

  files.forEach(file => {
    const fullPath = path.join(JS_DIR, file);
    const code = fs.readFileSync(fullPath, "utf-8");

    console.log(`🔍 Pre-checking: ${fullPath}`);

    // Syntax check
    try {
      new Function(code); // simple syntax check
      console.log("✅ Syntax OK");
    } catch (e) {
      console.log(`❌ Syntax Error: ${e.message}`);
    }

    // Browser globals check
    if (/window\./.test(code)) console.log("⚠ Uses window object");
    if (/document\./.test(code)) console.log("⚠ Uses document object");

    // Duplicate var/let/const
    const vars = (code.match(/\b(var|let|const)\s+([a-zA-Z_$][\w$]*)/g) || [])
      .map(v => v.split(/\s+/)[1]);
    const duplicates = vars.filter((v, i, a) => a.indexOf(v) !== i);
    if (duplicates.length) {
      console.log("⚠ Duplicate variables:", [...new Set(duplicates)].join(", "));
    }

    console.log("");
  });
}

// --------- Create HTTP server ---------
const server = http.createServer((req, res) => {

  // 1️⃣ Handle JS error logs from browser
  if (req.method === "POST" && req.url === "/log") {
    let body = "";
    req.on("data", chunk => body += chunk.toString());
    req.on("end", () => {
      try {
        const data = JSON.parse(body);
        logJS(data);
      } catch (e) {
        console.log("❌ Invalid log data:", e.message);
      }
      res.writeHead(200, { "Content-Type": "text/plain" });
      res.end("OK");
    });
    return;
  }

  // 2️⃣ Serve static files (HTML, JS, CSS)
  let filePath = path.join(BASE, req.url === "/" ? "index.html" : req.url);

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not Found");
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = {
      ".html": "text/html",
      ".js": "application/javascript",
      ".css": "text/css",
      ".png": "image/png",
      ".jpg": "image/jpeg",
      ".svg": "image/svg+xml"
    }[ext] || "application/octet-stream";

    res.writeHead(200, { "Content-Type": contentType });
    res.end(data);
  });
});

// 3️⃣ Start server and pre-check
server.listen(3000, "0.0.0.0", () => {
  console.clear();
  console.log("=================================");
  console.log("🚀 VI FULL LIVE DEBUG SERVER running at http://0.0.0.0:3000");
  console.log("📝 Open your browser/WebView and load index.html from this server");
  preCheckJS();
});
