const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("coreSetup", {
  getApps: () => ipcRenderer.invoke("get-apps"),
  getInstalledApps: () => ipcRenderer.invoke("get-installed-apps"),
  installApps: (ids) => ipcRenderer.invoke("install-apps", ids),
  closeApp: () => ipcRenderer.invoke("close-app"),
  getWindowBounds: () => ipcRenderer.invoke("get-window-bounds"),
  resizeWindow: (payload) => ipcRenderer.invoke("resize-window", payload)
});
