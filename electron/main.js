const { app, BrowserWindow, ipcMain } = require("electron");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

const allowedIds = new Set([
  "Mozilla.Firefox",
  "Google.Chrome",
  "Adobe.Acrobat.Reader.64-bit",
  "SonicWall.NetExtender",
  "Microsoft.PowerShell",
  "Microsoft.Office",
  "Git.Git",
  "Microsoft.VisualStudioCode",
  "GitHub.GitHubDesktop",
  "JanDeDobbeleer.OhMyPosh",
  "CoreyButler.NVMforWindows",
  "GlavSoft.TightVNC"
]);

function supportsWindowsAcrylic() {
  if (process.platform !== "win32") {
    return false;
  }

  const [major, , build] = os.release().split(".").map((part) => Number.parseInt(part, 10));
  return major >= 10 && build >= 22621;
}

function getWindowMaterialOptions() {
  if (supportsWindowsAcrylic()) {
    return {
      backgroundColor: "#00000000",
      backgroundMaterial: "acrylic"
    };
  }

  if (process.platform === "darwin") {
    return {
      backgroundColor: "#00000000",
      transparent: true,
      vibrancy: "under-window"
    };
  }

  return {
    backgroundColor: "#1a2233"
  };
}

function applyWindowMaterial(win) {
  if (supportsWindowsAcrylic() && typeof win.setBackgroundMaterial === "function") {
    win.setBackgroundMaterial("acrylic");
  }
}

function createWindow() {
  const win = new BrowserWindow({
    width: 560,
    height: 820,
    minWidth: 500,
    minHeight: 760,
    title: "CoreSetup Installer",
    autoHideMenuBar: true,
    frame: false,
    resizable: true,
    thickFrame: true,
    hasShadow: true,
    ...getWindowMaterialOptions(),
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  applyWindowMaterial(win);
  win.on("focus", () => applyWindowMaterial(win));
  win.on("blur", () => applyWindowMaterial(win));

  win.loadFile(path.join(__dirname, "renderer", "index.html"));
}

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

ipcMain.handle("install-apps", async (_event, ids) => {
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
});

ipcMain.handle("close-app", (event) => {
  BrowserWindow.fromWebContents(event.sender)?.close();
});

ipcMain.handle("get-window-bounds", (event) => {
  return BrowserWindow.fromWebContents(event.sender)?.getBounds();
});

ipcMain.handle("resize-window", (event, { corner, startBounds, deltaX, deltaY }) => {
  const win = BrowserWindow.fromWebContents(event.sender);
  if (!win || !startBounds) {
    return;
  }

  const [minWidth, minHeight] = win.getMinimumSize();
  const next = { ...startBounds };

  if (corner.includes("right")) {
    next.width = Math.max(minWidth, startBounds.width + deltaX);
  }

  if (corner.includes("bottom")) {
    next.height = Math.max(minHeight, startBounds.height + deltaY);
  }

  if (corner.includes("left")) {
    const width = Math.max(minWidth, startBounds.width - deltaX);
    next.x = startBounds.x + startBounds.width - width;
    next.width = width;
  }

  if (corner.includes("top")) {
    const height = Math.max(minHeight, startBounds.height - deltaY);
    next.y = startBounds.y + startBounds.height - height;
    next.height = height;
  }

  win.setBounds(next, false);
});

app.whenReady().then(createWindow);

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
