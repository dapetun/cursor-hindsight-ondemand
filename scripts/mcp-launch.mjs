/**
 * Cursor MCP entry: ensure local Hindsight daemon, then stdio-proxy via mcp-remote.
 * Uses windowsHide so no CMD/PowerShell windows stay on screen.
 */
import { spawn, spawnSync } from "node:child_process";
import path from "node:path";
import process from "node:process";

const home = process.env.USERPROFILE || process.env.HOME || "";
const ensurePs1 = path.join(home, ".hindsight", "ensure-daemon.ps1");
const mcpUrl = "http://127.0.0.1:9077/mcp/cursor/";

function fail(message, code = 1) {
  process.stderr.write(`${message}\n`);
  process.exit(code);
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

const child = spawn(
  "npx.cmd",
  ["-y", "mcp-remote@0.14.3", mcpUrl],
  {
    stdio: "inherit",
    windowsHide: true,
    env: process.env,
  }
);

child.on("error", (err) => fail(`hindsight MCP: failed to start mcp-remote: ${err.message}`));
child.on("exit", (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 1);
});
