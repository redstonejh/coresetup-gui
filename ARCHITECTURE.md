# CoreSetup Architecture

CoreSetup has two maintained surfaces:

- `coreSetup.ps1`: the Windows setup script and winget-backed installer logic.
- `electron/`: the desktop app used by non-technical users to select and install workstation essentials.

The old browser prototype was removed. The Electron app is the supported GUI.

## File Structure

```text
CoreSetup/
├── coreSetup.ps1
├── electron/
│   ├── backend/
│   │   ├── app-catalog.json
│   │   ├── catalog.js
│   │   ├── installerService.js
│   │   ├── windowControls.js
│   │   └── windowMaterial.js
│   ├── main.js
│   ├── preload.js
│   └── renderer/
│       ├── index.html
│       ├── renderer.js
│       ├── styles.css
│       └── assets/icons/
├── tests/
│   ├── CoreSetup.Static.Tests.ps1
│   └── Run-Checks.ps1
├── package.json
├── README.md
└── ARCHITECTURE.md
```

## Electron Process Boundaries

`electron/main.js` is the Electron composition root:

- BrowserWindow creation.
- IPC route registration.
- Delegation to backend modules.

Backend modules live in `electron/backend/`:

- `catalog.js`: exposes the supported app catalog and exact package-ID allow-list.
- `installerService.js`: validates requested installs, writes the temporary PowerShell script, and launches elevated PowerShell.
- `windowMaterial.js`: owns Windows acrylic, macOS vibrancy, and solid fallback options.
- `windowControls.js`: owns close, bounds, and resize behavior for the frameless window.

`electron/preload.js` exposes a narrow API:

- `installApps(ids)`
- `closeApp()`
- `getWindowBounds()`
- `resizeWindow(payload)`

The renderer does not get Node access.

## Renderer

`electron/renderer/renderer.js` owns UI state:

- app list rendering
- search filtering
- selection state
- install button enabled/disabled state
- custom resize-corner pointer handling

Package IDs are present only in JavaScript data and IPC payloads. The UI displays human-readable app names only.

## App Catalog

`electron/backend/app-catalog.json` is the source of truth for GUI install options.

Each entry needs:

- `name`: human-readable label shown in the app list.
- `id`: exact winget package ID sent to the installer.
- `icon`: SVG filename under `electron/renderer/assets/icons/`.

The backend derives its allow-list from the catalog and exposes the same catalog to the renderer through preload IPC. Adding a normal GUI option should not require editing the renderer or duplicating package IDs.

## Styling

`electron/renderer/styles.css` is intentionally scoped to the installer dialog.

Rules:

- Keep layout simple: search, app list, bottom action bar.
- Keep text and icons readable over native acrylic.
- Use one main window tint and lighter overlay tints for controls so alpha does not compound into opacity.
- Do not reintroduce obsolete tutorial panels, product headers, selected-count labels, or browser prototype styling.
- Keep interactive controls `no-drag`; empty background areas may be native drag regions.

## Backend Script

`coreSetup.ps1` remains the source of setup behavior. Important guarantees:

- winget app installs use exact package IDs.
- the script tracks failures and exits non-zero when failures occur.
- Appx cmdlets use terminating errors instead of `$LASTEXITCODE`.
- GUI/Electron calls are validated through allow-listed package IDs before launching elevated PowerShell.

## Validation

Run:

```powershell
npm run check
npm audit --audit-level=high
```

`tests/CoreSetup.Static.Tests.ps1` validates both the PowerShell backend and the maintained Electron GUI contract.
