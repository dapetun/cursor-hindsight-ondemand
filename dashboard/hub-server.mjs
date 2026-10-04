#!/usr/bin/env node
/**
 * Local hub for Hindsight UI + GitNexus web.
 * Binds 127.0.0.1 only. Does not start services until /api/start.
 */
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";
import os from "node:os";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const HOST = "127.0.0.1";
const PORT = Number(process.env.MEMORY_GRAPH_HUB_PORT || 8765);
const HINDSIGHT_API = process.env.HINDSIGHT_API_URL || "http://127.0.0.1:9077";
const HINDSIGHT_UI = process.env.HINDSIGHT_UI_URL || "http://127.0.0.1:19077";
const CONTROL = process.env.HINDSIGHT_CONTROL_URL || "http://127.0.0.1:7878";
const GITNEXUS = process.env.GITNEXUS_URL || "http://127.0.0.1:4747";
const HUB_DIR = path.join(__dirname, "hub");
const SCRIPTS_DIR = __dirname;

function fetchOk(url, timeoutMs = 1500) {
  return new Promise((resolve) => {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeoutMs);
    fetch(url, { signal: ctrl.signal })
      .then((r) => {
        clearTimeout(t);
        resolve(r.ok);
      })
      .catch(() => {
        clearTimeout(t);
        resolve(false);
      });
  });
}

async function fetchJson(url, timeoutMs = 2500) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const r = await fetch(url, { signal: ctrl.signal });
    clearTimeout(t);
    if (!r.ok) return null;
    return await r.json();
  } catch {
    clearTimeout(t);
    return null;
  }
}

function readRegistryRepos() {
  try {
    const regPath = path.join(os.homedir(), ".gitnexus", "registry.json");
    if (!fs.existsSync(regPath)) return [];
    const data = JSON.parse(fs.readFileSync(regPath, "utf8"));
    const repos = Array.isArray(data) ? data : data.repos || [];
    return repos.map((r) => ({
      name: r.name || path.basename(r.path || r.repoPath || ""),
      path: r.path || r.repoPath || "",
      indexedAt: r.indexedAt || r.lastIndexed || null,
      stats: r.stats || r.indexStats || null,
    }));
  } catch {
    return [];
  }
}

async function getStatus() {
  const [hindsightApi, hindsightUi, control, gitnexus] = await Promise.all([
    fetchOk(`${HINDSIGHT_API}/health`),
    fetchOk(HINDSIGHT_UI),
    fetchOk(CONTROL),
    fetchOk(`${GITNEXUS}/api/repos`),
  ]);
  let repos = [];
  if (gitnexus) {
    const payload = await fetchJson(`${GITNEXUS}/api/repos`);
    if (Array.isArray(payload)) repos = payload;
    else if (payload && Array.isArray(payload.repos)) repos = payload.repos;
  }
  if (!repos.length) repos = readRegistryRepos();
  return {
    hindsightApi,
    hindsightUi,
    control,
    gitnexus,
    hindsightApiUrl: HINDSIGHT_API,
    hindsightUiUrl: HINDSIGHT_UI,
    controlUrl: CONTROL,
    gitnexusUrl: GITNEXUS,
    repos,
  };
}

function runScript(name, extraEnv = {}) {
  const ps1 = path.join(SCRIPTS_DIR, name);
  if (!fs.existsSync(ps1)) {
    return Promise.reject(new Error(`Missing ${ps1}`));
  }
  return new Promise((resolve, reject) => {
    const child = spawn(
      "powershell.exe",
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps1],
      {
        windowsHide: true,
        stdio: "ignore",
        detached: false,
        env: { ...process.env, ...extraEnv },
      }
    );
    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${name} exited ${code}`));
    });
  });
}

function contentType(filePath) {
  if (filePath.endsWith(".html")) return "text/html; charset=utf-8";
  if (filePath.endsWith(".css")) return "text/css; charset=utf-8";
  if (filePath.endsWith(".js")) return "application/javascript; charset=utf-8";
  if (filePath.endsWith(".json")) return "application/json; charset=utf-8";
  if (filePath.endsWith(".svg")) return "image/svg+xml";
  return "application/octet-stream";
}

function sendJson(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://${HOST}:${PORT}`);

  if (req.method === "GET" && url.pathname === "/api/status") {
    try {
      sendJson(res, 200, await getStatus());
    } catch (e) {
      sendJson(res, 500, { error: String(e) });
    }
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/start") {
    try {
      // Avoid spawning a second hub while this process already serves it.
      await runScript("start-dashboards.ps1", { MEMORY_GRAPH_HUB_SKIP_SELF: "1" });
      sendJson(res, 200, { ok: true });
    } catch (e) {
      sendJson(res, 500, { ok: false, error: String(e) });
    }
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/stop") {
    try {
      await runScript("stop-dashboards.ps1");
      sendJson(res, 200, { ok: true });
    } catch (e) {
      sendJson(res, 500, { ok: false, error: String(e) });
    }
    return;
  }

  if (req.method === "GET") {
    let rel = url.pathname === "/" ? "/index.html" : url.pathname;
    rel = path.normalize(rel).replace(/^(\.\.[/\\])+/, "");
    const filePath = path.join(HUB_DIR, rel);
    if (!filePath.startsWith(HUB_DIR) || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }
    const data = fs.readFileSync(filePath);
    res.writeHead(200, { "Content-Type": contentType(filePath) });
    res.end(data);
    return;
  }

  res.writeHead(405);
  res.end("Method not allowed");
});

server.listen(PORT, HOST, () => {
  console.log(`Memory & Graphs hub: http://${HOST}:${PORT}`);
});
