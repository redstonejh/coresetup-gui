let apps = [];
const installed = new Set();
const updates = new Set();
const selected = new Set();
let query = "";
const appsNode = document.querySelector("#apps");
const installButton = document.querySelector("#install");
const clearButton = document.querySelector("#clear");
const scanUpdatesButton = document.querySelector("#scanUpdates");
const searchInput = document.querySelector("#search");
const searchField = document.querySelector(".search-field");

function renderApps() {
  appsNode.innerHTML = "";
  const normalizedQuery = query.trim().toLowerCase();
  const visibleApps = apps.filter(({ name }) => name.toLowerCase().includes(normalizedQuery));
  for (const { name, id, icon } of visibleApps) {
    const row = document.createElement("label");
    row.className = `app-row${selected.has(id) ? " selected" : ""}`;

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = selected.has(id);
    checkbox.addEventListener("change", () => {
      checkbox.checked ? selected.add(id) : selected.delete(id);
      render();
    });

    const image = document.createElement("img");
    image.className = "app-icon";
    image.src = `assets/icons/${icon}`;
    image.alt = "";

    const title = document.createElement("div");
    title.className = "app-name";
    title.textContent = name;

    row.append(checkbox, image, title);

    if (updates.has(id) || installed.has(id)) {
      const badge = document.createElement("div");
      badge.className = `app-status${updates.has(id) ? " update" : ""}`;
      badge.textContent = updates.has(id) ? "Update available" : "Installed";
      row.append(badge);
    }

    appsNode.append(row);
  }
}

function render() {
  installButton.textContent = selected.size ? `Install ${selected.size}` : "Install";
  installButton.disabled = selected.size === 0;
  clearButton.disabled = selected.size === 0;
  renderApps();
}

async function installSelected(ids) {
  if (!ids.length) {
    return;
  }
  const updateIds = ids.filter((id) => updates.has(id));
  await window.coreSetup.installApps({ ids, updateIds });
}

document.querySelector("#selectAll").addEventListener("click", () => {
  apps.forEach(({ id }) => selected.add(id));
  render();
});

document.querySelector("#install").addEventListener("click", () => {
  installSelected(Array.from(selected));
});

scanUpdatesButton.addEventListener("click", async () => {
  scanUpdatesButton.disabled = true;
  scanUpdatesButton.textContent = "Scanning...";
  updates.clear();
  renderApps();

  const updateIds = await window.coreSetup.scanUpdates();
  updateIds.forEach((id) => updates.add(id));

  scanUpdatesButton.disabled = false;
  scanUpdatesButton.textContent = "Scan updates";
  renderApps();
});

document.querySelector("#clear").addEventListener("click", () => {
  selected.clear();
  render();
});

document.querySelector("#exit").addEventListener("click", () => {
  window.coreSetup.closeApp();
});

for (const corner of document.querySelectorAll(".resize-corner")) {
  corner.addEventListener("pointerdown", async (event) => {
    event.preventDefault();
    corner.setPointerCapture(event.pointerId);
    const cornerName = [...corner.classList].filter((name) => name !== "resize-corner").join("-");
    const startBounds = await window.coreSetup.getWindowBounds();
    const startX = event.screenX;
    const startY = event.screenY;

    const resize = (moveEvent) => {
      window.coreSetup.resizeWindow({
        corner: cornerName,
        startBounds,
        deltaX: moveEvent.screenX - startX,
        deltaY: moveEvent.screenY - startY
      });
    };

    const stop = () => {
      if (corner.hasPointerCapture(event.pointerId)) {
        corner.releasePointerCapture(event.pointerId);
      }
      window.removeEventListener("pointermove", resize);
      window.removeEventListener("pointerup", stop);
      window.removeEventListener("pointercancel", stop);
    };

    window.addEventListener("pointermove", resize);
    window.addEventListener("pointerup", stop);
    window.addEventListener("pointercancel", stop);
  });
}

searchInput.addEventListener("input", () => {
  query = searchInput.value;
  searchField.classList.toggle("has-value", query.trim().length > 0);
  renderApps();
});

async function init() {
  apps = await window.coreSetup.getApps();
  render();
  const installedIds = await window.coreSetup.getInstalledApps();
  installedIds.forEach((id) => installed.add(id));
  renderApps();
}

init();
