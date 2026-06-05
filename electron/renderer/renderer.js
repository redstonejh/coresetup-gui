const apps = [
  ["Firefox", "Mozilla.Firefox", "firefox.svg"],
  ["Google Chrome", "Google.Chrome", "chrome.svg"],
  ["Adobe Acrobat Reader", "Adobe.Acrobat.Reader.64-bit", "acrobat.svg"],
  ["SonicWall NetExtender", "SonicWall.NetExtender", "sonicwall.svg"],
  ["PowerShell 7", "Microsoft.PowerShell", "powershell.svg"],
  ["Microsoft 365", "Microsoft.Office", "office.svg"],
  ["Git", "Git.Git", "git.svg"],
  ["Visual Studio Code", "Microsoft.VisualStudioCode", "vscode.svg"],
  ["GitHub Desktop", "GitHub.GitHubDesktop", "github.svg"],
  ["Oh My Posh", "JanDeDobbeleer.OhMyPosh", "ohmyposh.svg"],
  ["NVM for Windows", "CoreyButler.NVMforWindows", "nvm.svg"],
  ["TightVNC", "GlavSoft.TightVNC", "tightvnc.svg"]
];

const selected = new Set();
let query = "";
const appsNode = document.querySelector("#apps");
const installButton = document.querySelector("#install");
const clearButton = document.querySelector("#clear");
const searchInput = document.querySelector("#search");
const searchField = document.querySelector(".search-field");

function renderApps() {
  appsNode.innerHTML = "";
  const normalizedQuery = query.trim().toLowerCase();
  const visibleApps = apps.filter(([name]) => name.toLowerCase().includes(normalizedQuery));
  for (const [name, id, icon] of visibleApps) {
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
  await window.coreSetup.installApps(ids);
}

document.querySelector("#selectAll").addEventListener("click", () => {
  apps.forEach(([, id]) => selected.add(id));
  render();
});

document.querySelector("#install").addEventListener("click", () => {
  installSelected(Array.from(selected));
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

render();
