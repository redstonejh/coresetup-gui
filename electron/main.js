const { app, BrowserWindow, ipcMain } = require("electron");
const path = require("path");
const { getApps, getAllowedPackageIds } = require("./backend/catalog");
const { installApps } = require("./backend/installerService");
const { applyWindowMaterial, getWindowMaterialOptions } = require("./backend/windowMaterial");
const { closeApp, getWindowBounds, resizeWindow } = require("./backend/windowControls");

const allowedIds = getAllowedPackageIds();

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

ipcMain.handle("get-apps", () => getApps());
ipcMain.handle("install-apps", (_event, ids) => installApps(ids, allowedIds));
ipcMain.handle("close-app", closeApp);
ipcMain.handle("get-window-bounds", getWindowBounds);
ipcMain.handle("resize-window", resizeWindow);

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
