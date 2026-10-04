/**
 * Cursor MCP entry: ensure local Hindsight daemon, then stdio-proxy via mcp-remote.
 * Spawns node directly (no npx.cmd / cmd.exe) so no console window appears on Windows.
 */
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const home = process.env.USERPROFILE || process.env.HOME || "";
const ensurePs1 = path.join(home, ".hindsight", "ensure-daemon.ps1");
const mcpUrl = "http://127.0.0.1:9077/mcp/cursor/";

function fail(message, code = 1) {
  process.stderr.write(`${message}\n`);
  process.exit(code);
}

function resolveMcpRemoteProxy() {
  const candidates = [];
  if (process.env.APPDATA) {
    candidates.push(
      path.join(process.env.APPDATA, "npm", "node_modules", "mcp-remote", "dist", "proxy.js")
    );
  }
  candidates.push(
    path.join(path.dirname(fileURLToPath(import.meta.url)), "node_modules", "mcp-remote", "dist", "proxy.js")
  );

  for (const candidate of candidates) {
    try {
      if (fs.existsSync(candidate)) return candidate;
    } catch {
      // ignore
    }
  }
  return null;
}

const ensure = spawnSync(
  "powershell.exe",
  [
    "-NoLogo",
    "-NoProfile",
    "-WindowStyle",
    "Hidden",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    ensurePs1,
    "-WaitSeconds",
    "150",
  ],
  {
    encoding: "utf8",
    windowsHide: true,
  }
);

if (ensure.stdout) process.stderr.write(ensure.stdout);
if (ensure.stderr) process.stderr.write(ensure.stderr);
if (ensure.status !== 0) {
  fail("hindsight MCP: local daemon not ready on 127.0.0.1:9077", ensure.status ?? 1);
}

const proxyJs = resolveMcpRemoteProxy();
if (!proxyJs) {
  fail(
    "hindsight MCP: mcp-remote not found. Install with: npm install -g mcp-remote"
  );
}

const child = spawn(process.execPath, [proxyJs, mcpUrl], {
  stdio: "inherit",
  windowsHide: true,
  env: process.env,
});

child.on("error", (err) => fail(`hindsight MCP: failed to start mcp-remote: ${err.message}`));
child.on("exit", (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 1);
});
