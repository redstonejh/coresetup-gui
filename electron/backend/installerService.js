const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

function buildInstallScript(ids) {
  const lines = [
    "$ErrorActionPreference = 'Continue'",
    "$Host.UI.RawUI.WindowTitle = 'CoreSetup Installer'",
    "Write-Host 'CoreSetup is installing selected apps...'",
    "winget source update --disable-interactivity",
    ""
  ];

  for (const id of ids) {
    lines.push(`Write-Host 'Installing ${id}...'`);
    lines.push(`winget install --id ${id} --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity`);
    lines.push("if ($LASTEXITCODE -ne 0) { Write-Host 'Install failed or needs attention.' }");
    lines.push("");
  }

  lines.push("Write-Host ''");
  lines.push("Write-Host 'CoreSetup finished. You can close this window.'");
  lines.push("Read-Host 'Press Enter to close'");
  return lines.join("\r\n");
}

function installApps(ids, allowedIds) {
  if (!Array.isArray(ids) || ids.length === 0) {
    return { ok: false, message: "Choose at least one app first." };
  }

  const cleanIds = ids.filter((id) => allowedIds.has(id));
  if (cleanIds.length !== ids.length) {
    return { ok: false, message: "The app list contains an unknown package." };
  }

  const scriptPath = path.join(os.tmpdir(), `CoreSetup-Install-${Date.now()}.ps1`);
  fs.writeFileSync(scriptPath, buildInstallScript(cleanIds), "utf8");

  const escapedScript = scriptPath.replace(/'/g, "''");
  const command = [
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    `Start-Process -FilePath pwsh.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File','${escapedScript}')`
  ];

  const child = spawn("powershell.exe", command, {
    windowsHide: true,
    detached: true,
    stdio: "ignore"
  });

  child.unref();
  return { ok: true, message: "Windows will ask for permission, then CoreSetup will install the apps." };
}

module.exports = {
  buildInstallScript,
  installApps
};
