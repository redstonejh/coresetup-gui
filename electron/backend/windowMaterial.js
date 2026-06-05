const os = require("os");

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

module.exports = {
  supportsWindowsAcrylic,
  getWindowMaterialOptions,
  applyWindowMaterial
};
