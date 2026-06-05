const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("coreSetup", {
  installApps: (ids) => ipcRenderer.invoke("install-apps", ids),
  closeApp: () => ipcRenderer.invoke("close-app"),
  getWindowBounds: () => ipcRenderer.invoke("get-window-bounds"),
  resizeWindow: (payload) => ipcRenderer.invoke("resize-window", payload)
});
