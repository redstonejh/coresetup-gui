# CoreSetup

CoreSetup installs common workstation applications on Windows.

The maintained user-facing app is the Electron installer in `electron/`. It presents a simple app picker and launches the selected winget installs through an elevated PowerShell process.

## Run The Desktop Installer

```powershell
npm install
npm start
```

The installer validates selected package IDs against an allow-list before launching PowerShell.

## Build A Client Installer

To create a Windows `.exe` installer:

```powershell
npm install
npm run dist:win
```

The generated installer is written to `dist/CoreSetup-Setup-0.1.0.exe`.

The `.exe` bundles the Electron runtime, so a client does not need Node.js, npm, or Electron installed. Windows still needs winget available for the selected application installs.

## Run Checks

```powershell
npm run check
npm audit --audit-level=high
```

## PowerShell Script

The backend script is still available as `coreSetup.ps1` for direct administrative use.

Download the raw script from the upstream repository:

https://github.com/mrdatawolf/CoreSetup/raw/main/coreSetup.ps1

Because this is a PowerShell setup script, it should be run only by someone who understands what it will change on the system.

Before first use:

- Fully run Windows and vendor updates.
- Open PowerShell and run `winget list` once so winget source agreements are accepted.
- Run from an elevated PowerShell prompt when using the script directly.

Common first-run fixes:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

If the downloaded script is blocked:

```powershell
Unblock-File .\coreSetup.ps1
```

## Notes

- The old browser prototype was removed.
- The Electron GUI is the supported client-facing installer.
- The PowerShell script remains the setup backend.
