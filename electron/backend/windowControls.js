const { BrowserWindow } = require("electron");

function closeApp(event) {
  BrowserWindow.fromWebContents(event.sender)?.close();
}

function getWindowBounds(event) {
  return BrowserWindow.fromWebContents(event.sender)?.getBounds();
}

function resizeWindow(event, { corner, startBounds, deltaX, deltaY }) {
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
}

module.exports = {
  closeApp,
  getWindowBounds,
  resizeWindow
};
