$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "coreSetup.ps1"
$readmePath = Join-Path $repoRoot "README.md"
$electronRoot = Join-Path $repoRoot "electron"
$electronBackendRoot = Join-Path $electronRoot "backend"
$electronCatalogPath = Join-Path $electronBackendRoot "app-catalog.json"
$electronCatalogModulePath = Join-Path $electronBackendRoot "catalog.js"
$electronInstallerServicePath = Join-Path $electronBackendRoot "installerService.js"
$electronWindowMaterialPath = Join-Path $electronBackendRoot "windowMaterial.js"
$electronWindowControlsPath = Join-Path $electronBackendRoot "windowControls.js"
$electronMainPath = Join-Path $electronRoot "main.js"
$electronPreloadPath = Join-Path $electronRoot "preload.js"
$electronIconRoot = Join-Path $electronRoot "renderer\assets\icons"
$electronIndexPath = Join-Path $electronRoot "renderer\index.html"
$electronRendererPath = Join-Path $electronRoot "renderer\renderer.js"
$electronStylesPath = Join-Path $electronRoot "renderer\styles.css"
$packagePath = Join-Path $repoRoot "package.json"
$scriptText = Get-Content $scriptPath -Raw
$readmeText = Get-Content $readmePath -Raw
$electronMainText = Get-Content $electronMainPath -Raw
$electronCatalogText = Get-Content $electronCatalogPath -Raw
$electronCatalog = $electronCatalogText | ConvertFrom-Json
$electronCatalogModuleText = Get-Content $electronCatalogModulePath -Raw
$electronInstallerServiceText = Get-Content $electronInstallerServicePath -Raw
$electronWindowMaterialText = Get-Content $electronWindowMaterialPath -Raw
$electronWindowControlsText = Get-Content $electronWindowControlsPath -Raw
$electronPreloadText = Get-Content $electronPreloadPath -Raw
$electronIndexText = Get-Content $electronIndexPath -Raw
$electronBodyText = [regex]::Match($electronIndexText, '(?s)<body>(.*)</body>').Groups[1].Value
$electronRendererText = Get-Content $electronRendererPath -Raw
$electronStylesText = Get-Content $electronStylesPath -Raw
$packageText = Get-Content $packagePath -Raw

$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Assert-Matches {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Assert-True -Condition ($Text -match $Pattern) -Message $Message
}

function Assert-NotMatches {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Assert-True -Condition ($Text -notmatch $Pattern) -Message $Message
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
Assert-True -Condition ($parseErrors.Count -eq 0) -Message "coreSetup.ps1 should parse without PowerShell syntax errors."

Assert-NotMatches `
    -Text $scriptText `
    -Pattern 'Remove-AppxPackage[^\r\n]*-Online' `
    -Message "Remove-AppxPackage must not use the unsupported -Online parameter."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'winget install --id \$app --exact' `
    -Message "Install-App should install by exact winget package ID."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'winget list --id \$app --exact' `
    -Message "Install-Apps should detect installed apps by exact package ID."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'winget uninstall --name \$app --exact' `
    -Message "Uninstall-Apps should use exact display-name matching."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'winget list --id \$app --exact' `
    -Message "Uninstall-Apps should fall back to exact package ID matching."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'winget uninstall --id \$app --exact' `
    -Message "Uninstall-Apps should support exact package ID uninstalls."

Assert-Matches `
    -Text $scriptText `
    -Pattern '\$script:failureCount\s*=\s*0' `
    -Message "Script should initialize a shared failure counter."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'function Test-NoNewFailures' `
    -Message "Script should have an operation-local success helper."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'if \(\$script:failureCount -gt 0\)\s*\{[\s\r\n]*exit 1' `
    -Message "Script should exit non-zero when operations record failures."

Assert-NotMatches `
    -Text $scriptText `
    -Pattern 'Remove-Appx(?:Provisioned)?Package[^\r\n]*(?:\r?\n(?!\s*\}\s*(?:catch|else)).*){0,2}\$LASTEXITCODE' `
    -Message "Appx cmdlet success should not be judged with native-command `$LASTEXITCODE."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Get-AppxProvisionedPackage -Online -ErrorAction Stop' `
    -Message "Provisioned Appx package query should use terminating errors."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Remove-AppxProvisionedPackage -Online -PackageName \$package\.PackageName -ErrorAction Stop' `
    -Message "Provisioned Appx package removal should use terminating errors."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Get-AppxPackage -Name "Microsoft\.OutlookForWindows" -AllUsers -ErrorAction Stop' `
    -Message "Installed Outlook query should inspect all users with terminating errors."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Remove-AppxPackage -AllUsers -Package \$package\.PackageFullName -ErrorAction Stop' `
    -Message "Installed Outlook removal should use terminating errors."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Add-Failure "failed to disable WiFi adapter' `
    -Message "WiFi adapter disable failures should increment failure count."

Assert-Matches `
    -Text $scriptText `
    -Pattern 'Add-Failure "failed to disable Bluetooth adapter' `
    -Message "Bluetooth adapter disable failures should increment failure count."

$expectedWingetIds = @(
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
)

foreach ($id in $expectedWingetIds) {
    Assert-Matches `
        -Text $scriptText `
        -Pattern ([regex]::Escape($id)) `
        -Message "Expected exact winget package ID missing: $id"
}

Assert-NotMatches `
    -Text $scriptText `
    -Pattern '"vscode"|"github desktop"|"nvm-windows"|"tightvnc"|"Microsoft 365"|"Adobe Acrobat Reader DC"' `
    -Message "Legacy ambiguous winget identifiers should not be used."

Assert-NotMatches `
    -Text $readmeText `
    -Pattern 'coreUpdate\.ps1' `
    -Message "README should not link to missing coreUpdate.ps1."

Assert-True `
    -Condition (-not (Test-Path (Join-Path $repoRoot "frontend"))) `
    -Message "Legacy browser frontend prototype should not be present."

Assert-Matches `
    -Text $packageText `
    -Pattern '"start":\s*"electron \."' `
    -Message "Package should expose an Electron start command."

Assert-Matches `
    -Text $packageText `
    -Pattern '"dist:win":\s*"electron-builder --win nsis"' `
    -Message "Package should expose a Windows installer build command."

Assert-Matches `
    -Text $packageText `
    -Pattern '"electron-builder":' `
    -Message "Package should include electron-builder for distributable Windows installers."

Assert-Matches `
    -Text $packageText `
    -Pattern '"target":\s*"nsis"' `
    -Message "Windows build should produce an NSIS installer executable."

Assert-Matches `
    -Text $packageText `
    -Pattern '"signAndEditExecutable":\s*false' `
    -Message "Local Windows installer builds should avoid code-signing helper extraction that requires symlink privileges."

Assert-Matches `
    -Text $readmeText `
    -Pattern 'does not need Node\.js, npm, or Electron installed' `
    -Message "README should explain that the packaged installer bundles the Electron runtime."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'ipcMain\.handle\("install-apps"' `
    -Message "Electron main process should expose an install-apps IPC handler."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'frame:\s*false' `
    -Message "Electron window should be frameless without the native Windows title bar."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'width:\s*560[\s\S]*height:\s*820[\s\S]*resizable:\s*true' `
    -Message "Electron window should default to a narrower, taller resizable utility dialog."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'thickFrame:\s*true[\s\S]*hasShadow:\s*true' `
    -Message "Frameless Electron window should keep native resize frame and window depth."

Assert-Matches `
    -Text $electronWindowMaterialText `
    -Pattern 'function supportsWindowsAcrylic\(\)[\s\S]*process\.platform !== "win32"[\s\S]*build >= 22621' `
    -Message "Electron should gate Windows acrylic to Windows 11 22H2 or newer."

Assert-Matches `
    -Text $electronWindowMaterialText `
    -Pattern 'backgroundColor:\s*"#00000000"[\s\S]*backgroundMaterial:\s*"acrylic"' `
    -Message "Windows 11 material path should use native acrylic with transparent backgroundColor."

Assert-Matches `
    -Text $electronWindowMaterialText `
    -Pattern 'function applyWindowMaterial\(win\)[\s\S]*win\.setBackgroundMaterial\("acrylic"\)' `
    -Message "Electron should reapply native acrylic material through the BrowserWindow API."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'win\.on\("focus", \(\) => applyWindowMaterial\(win\)\);[\s\r\n]*win\.on\("blur", \(\) => applyWindowMaterial\(win\)\);' `
    -Message "Electron should reapply acrylic on focus and blur so material does not drop to a solid fill."

Assert-NotMatches `
    -Text $electronWindowMaterialText `
    -Pattern 'return\s*\{[\s\r\n]*backgroundColor:\s*"#00000000",[\s\r\n]*backgroundMaterial:\s*"acrylic",?[\s\r\n]*transparent:\s*true' `
    -Message "Windows acrylic should not be combined with transparent:true."

Assert-Matches `
    -Text $electronWindowMaterialText `
    -Pattern 'process\.platform === "darwin"[\s\S]*backgroundColor:\s*"#00000000"[\s\S]*transparent:\s*true[\s\S]*vibrancy:\s*"under-window"' `
    -Message "macOS material path should use under-window vibrancy with a transparent window."

Assert-Matches `
    -Text $electronWindowMaterialText `
    -Pattern 'return\s*\{[\s\r\n]*backgroundColor:\s*"#1a2233"[\s\r\n]*\}' `
    -Message "Unsupported platforms should fall back to a solid dark window background."

Assert-Matches `
    -Text $electronPreloadText `
    -Pattern 'contextBridge\.exposeInMainWorld\("coreSetup"' `
    -Message "Electron preload should expose a narrow coreSetup API."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'ipcMain\.handle\("close-app"' `
    -Message "Electron main process should expose a close-app IPC handler for the custom Exit button."

Assert-Matches `
    -Text ($electronMainText + $electronWindowControlsText) `
    -Pattern 'ipcMain\.handle\("get-window-bounds", getWindowBounds\)[\s\S]*getBounds\(\)' `
    -Message "Electron main process should expose window bounds for custom corner resize."

Assert-Matches `
    -Text ($electronMainText + $electronWindowControlsText) `
    -Pattern 'ipcMain\.handle\("resize-window", resizeWindow\)[\s\S]*win\.setBounds\(next, false\)' `
    -Message "Electron main process should resize the native window from custom corner handles."

Assert-Matches `
    -Text $electronPreloadText `
    -Pattern 'closeApp:\s*\(\)\s*=>\s*ipcRenderer\.invoke\("close-app"\)' `
    -Message "Electron preload should expose a narrow closeApp API."

Assert-Matches `
    -Text $electronPreloadText `
    -Pattern 'getWindowBounds:\s*\(\)\s*=>\s*ipcRenderer\.invoke\("get-window-bounds"\)' `
    -Message "Electron preload should expose a narrow getWindowBounds API."

Assert-Matches `
    -Text $electronPreloadText `
    -Pattern 'resizeWindow:\s*\(payload\)\s*=>\s*ipcRenderer\.invoke\("resize-window", payload\)' `
    -Message "Electron preload should expose a narrow resizeWindow API."

Assert-Matches `
    -Text $electronInstallerServiceText `
    -Pattern 'Start-Process -FilePath pwsh\.exe -Verb RunAs' `
    -Message "Electron installer should launch PowerShell with Windows elevation."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'const \{ getApps, getAllowedPackageIds \} = require\("\./backend/catalog"\)' `
    -Message "Electron main process should depend on the backend catalog module."

Assert-Matches `
    -Text $electronCatalogModuleText `
    -Pattern 'function getAllowedPackageIds\(\)[\s\S]*new Set\(appCatalog\.map\(\(item\) => item\.id\)\)' `
    -Message "Backend catalog module should derive the package allow-list from the shared catalog."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'ipcMain\.handle\("get-apps", \(\) => getApps\(\)\)' `
    -Message "Electron main process should expose the shared catalog through IPC."

Assert-Matches `
    -Text $electronMainText `
    -Pattern 'ipcMain\.handle\("install-apps", \(_event, ids\) => installApps\(ids, allowedIds\)\)' `
    -Message "Electron main process should delegate install work to the backend installer service."

Assert-NotMatches `
    -Text $electronMainText `
    -Pattern 'fs\.writeFileSync|spawn\("powershell\.exe"|winget install|function buildInstallScript|function supportsWindowsAcrylic|function resizeWindow' `
    -Message "Electron main process should only wire frontend IPC to backend services, not contain backend implementation details."

Assert-Matches `
    -Text $electronPreloadText `
    -Pattern 'getApps:\s*\(\)\s*=>\s*ipcRenderer\.invoke\("get-apps"\)' `
    -Message "Electron preload should expose catalog loading through the safe API."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'window\.coreSetup\.installApps' `
    -Message "Electron renderer should call the safe preload install API."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'apps = await window\.coreSetup\.getApps\(\)' `
    -Message "Electron renderer should render from the shared application catalog instead of a hardcoded list."

Assert-NotMatches `
    -Text $electronBodyText `
    -Pattern 'scriptBox|Copy script|Installer script|Support staff|Create installer|Install selected apps|Install everything|class="eyebrow"|Choose apps|progress-steps|Pick apps|Approve prompt|Finished|Ready to install|statusbar|<h1>|CoreSetup|Install essential workstation software|app-header|selected|id="count"|selection-count' `
    -Message "Electron UI should not expose installer internals, tutorial copy, marketing headings, product header, or selected-count label."

Assert-Matches `
    -Text $electronIndexText `
    -Pattern '<label class="search-field" for="search">[\s\S]*<input class="search-input" id="search"[\s\S]*<span>Search applications</span>' `
    -Message "Electron UI should make search the primary visual anchor with a floating label."

Assert-Matches `
    -Text $electronIndexText `
    -Pattern 'id="install">Install' `
    -Message "Electron UI should expose one simple Install button."

Assert-Matches `
    -Text $electronIndexText `
    -Pattern 'id="selectAll">Select all' `
    -Message "Electron UI should expose Select all without installing immediately."

foreach ($appId in @(
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
)) {
    Assert-Matches `
        -Text $electronCatalogText `
        -Pattern ([regex]::Escape($appId)) `
        -Message "Electron catalog should include package ID: $appId"
    Assert-NotMatches `
        -Text $electronIndexText `
        -Pattern ([regex]::Escape($appId)) `
        -Message "Electron HTML should not display package ID: $appId"
    Assert-NotMatches `
        -Text $electronRendererText `
        -Pattern ([regex]::Escape($appId)) `
        -Message "Electron renderer should not hardcode package ID: $appId"
}

Assert-True `
    -Condition ($electronCatalog.Count -eq 12) `
    -Message "Electron catalog should contain the 12 supported installer options."

foreach ($item in $electronCatalog) {
    Assert-True `
        -Condition (-not [string]::IsNullOrWhiteSpace($item.name)) `
        -Message "Every catalog entry should have a human-readable name."
    Assert-True `
        -Condition (-not [string]::IsNullOrWhiteSpace($item.id)) `
        -Message "Every catalog entry should have an exact winget package ID."
    Assert-True `
        -Condition (-not [string]::IsNullOrWhiteSpace($item.icon)) `
        -Message "Every catalog entry should have an icon filename."
    Assert-True `
        -Condition (Test-Path (Join-Path $electronIconRoot $item.icon)) `
        -Message "Every catalog entry should point at an existing icon: $($item.icon)"
}

Assert-NotMatches `
    -Text $electronRendererText `
    -Pattern 'app-id' `
    -Message "Electron renderer should not render package IDs under app names."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'className = `app-row' `
    -Message "Electron renderer should use a focused utility-picker app list."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'className = "app-icon"' `
    -Message "Electron app rows should render an icon element."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'checkbox\.type = "checkbox"' `
    -Message "Electron app rows should keep visible checkbox affordances."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'searchInput\.addEventListener\("input"' `
    -Message "Electron picker should support quick application search."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'searchField\.classList\.toggle\("has-value"' `
    -Message "Electron search label should float after text is entered."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'installButton\.disabled = selected\.size === 0' `
    -Message "Install button should have a clear disabled state when no apps are selected."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'installButton\.textContent = selected\.size \? `Install \$\{selected\.size\}` : "Install"' `
    -Message "Install button should stay simple when empty and show the selected count when useful."

Assert-Matches `
    -Text $electronIndexText `
    -Pattern '<footer class="action-bar">[\s\S]*id="exit">Exit</button>[\s\S]*id="clear">Clear</button>[\s\S]*id="selectAll">Select all</button>[\s\S]*id="install">Install</button>[\s\S]*</footer>' `
    -Message "Electron UI should keep Exit on the left and Clear, Select all, Install in the bottom action bar."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'window\.coreSetup\.closeApp\(\)' `
    -Message "Electron Exit button should close the app through preload."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'document\.querySelectorAll\("\.resize-corner"\)' `
    -Message "Electron renderer should attach custom resize handling to all resize corners."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'window\.coreSetup\.getWindowBounds\(\)' `
    -Message "Electron renderer should read native window bounds before resizing."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'window\.coreSetup\.resizeWindow' `
    -Message "Electron renderer should resize through the preload window API."

Assert-Matches `
    -Text $electronRendererText `
    -Pattern 'apps\.forEach\(\(\{ id \}\) => selected\.add\(id\)\)' `
    -Message "Select all should only select all apps."

Assert-NotMatches `
    -Text $electronStylesText `
    -Pattern 'linear-gradient\(135deg, #2563eb, #14b8a6\)' `
    -Message "Electron buttons should use a normalized single-accent palette."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.button:disabled' `
    -Message "Electron buttons should define readable disabled states."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--accent:\s*#3b82f6' `
    -Message "Electron UI should use the requested Windows-style blue accent color."

Assert-NotMatches `
    -Text $electronStylesText `
    -Pattern '#2dd4bf|#5b7cfa|cyan|teal|radial-gradient|filter:\s*drop-shadow|\.step|progress-steps|statusbar|window-surface' `
    -Message "Electron UI should not retain neon, tutorial-chip, or obsolete panel styling."

foreach ($color in @("#3b82f6", "#f8fafc", "#94a3b8")) {
    Assert-Matches `
        -Text $electronStylesText `
        -Pattern ([regex]::Escape($color)) `
        -Message "Electron UI should use requested restrained palette color: $color"
}

foreach ($glassToken in @(
    '--panel:\s*rgba\(26, 34, 51, \.66\)',
    '--panel-soft:\s*rgba\(32, 42, 61, \.34\)',
    '--secondary-glass:\s*rgba\(52, 64, 88, \.26\)',
    '--option-hover:\s*rgba\(82, 96, 125, \.20\)',
    '--button-hover:\s*rgba\(36, 48, 71, \.32\)'
)) {
    Assert-Matches `
        -Text $electronStylesText `
        -Pattern $glassToken `
        -Message "Electron UI should use active glass palette token: $glassToken"
}

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.app-row\.selected' `
    -Message "Electron app rows should define an obvious selected state."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--selected:\s*rgba\(96,\s*165,\s*250,\s*\.18\)' `
    -Message "Selected rows should use a lighter glassy accent tint without becoming a solid block."

Assert-NotMatches `
    -Text $electronStylesText `
    -Pattern 'border-left(?:-color)?:[^;\r\n]*var\(--accent\)|border-left:\s*[3-9]px|#1e2b44' `
    -Message "Selected rows should not use a navigation-style accent rail or heavy blue block."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.button\.ghost\s*\{[\s\S]*color:\s*var\(--text\);[\s\S]*background:\s*transparent;' `
    -Message "Clear should be a tertiary text action without looking disabled."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern 'grid-template-columns:\s*20px 30px minmax\(0, 1fr\)' `
    -Message "Electron app rows should align checkbox, icon, and name consistently."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.action-bar' `
    -Message "Electron UI should keep actions in a sticky bottom action bar."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.window-drag-region\s*\{[\s\S]*top:\s*0;[\s\S]*bottom:\s*0;[\s\S]*-webkit-app-region:\s*drag;' `
    -Message "Frameless Electron window should expose native drag behavior across empty background space."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.content\s*\{[\s\S]*-webkit-app-region:\s*drag;' `
    -Message "Empty content background should be draggable in the frameless window."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.action-bar\s*\{[\s\S]*-webkit-app-region:\s*drag;' `
    -Message "Empty footer background should be draggable in the frameless window."

foreach ($noDragRule in @(
    '\.search-field\s*\{[\s\S]*-webkit-app-region:\s*no-drag;',
    '\.app-row\s*\{[\s\S]*-webkit-app-region:\s*no-drag;',
    '\.toolbar\s*\{[\s\S]*-webkit-app-region:\s*no-drag;',
    '\.button\s*\{[\s\S]*-webkit-app-region:\s*no-drag;'
)) {
    Assert-Matches `
        -Text $electronStylesText `
        -Pattern $noDragRule `
        -Message "Interactive controls should remain no-drag inside the frameless window."
}

foreach ($cornerRule in @(
    '\.resize-corner\.top-left\s*\{[\s\S]*cursor:\s*nwse-resize;',
    '\.resize-corner\.bottom-right\s*\{[\s\S]*cursor:\s*nwse-resize;',
    '\.resize-corner\.top-right\s*\{[\s\S]*cursor:\s*nesw-resize;',
    '\.resize-corner\.bottom-left\s*\{[\s\S]*cursor:\s*nesw-resize;'
)) {
    Assert-Matches `
        -Text $electronStylesText `
        -Pattern $cornerRule `
        -Message "Resize corners should expose the correct diagonal resize cursors."
}

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.app-window\s*\{[\s\S]*border:\s*none;[\s\S]*outline:\s*none;[\s\S]*border-radius:\s*0;[\s\S]*box-shadow:\s*none;[\s\S]*-webkit-app-region:\s*drag;' `
    -Message "Electron shell should have no visible outer border, stroke, radius wrapper, or CSS shadow."

Assert-NotMatches `
    -Text $electronStylesText `
    -Pattern '(?s)\.app-window\s*\{(?:(?!\}).)*inset 0|border:\s*1px solid rgba\(226, 232, 240, \.18\)|box-shadow:\s*[\s\S]*0 0 0 1px|backdrop-filter:\s*blur\(14px\)|height:\s*calc\(100vh - 16px\)|padding:\s*8px' `
    -Message "Electron shell should not have an outer border, inset border, stroke, glass edge, or padded wrapper outline."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--panel:\s*rgba\(26, 34, 51, \.66\)' `
    -Message "Renderer should use one moderately opaque dark glass tint so OS acrylic remains visible."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern 'html,[\s\r\n]*body\s*\{[\s\S]*background:\s*transparent;' `
    -Message "html/body should stay transparent so they do not block native acrylic."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern 'body\s*\{[\s\S]*background:\s*transparent;' `
    -Message "body should not add a second tinted layer over native acrylic."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--secondary-glass:\s*rgba\(52, 64, 88, \.26\)' `
    -Message "Search, footer, and option hover surfaces should use one lighter less-tinted secondary glass overlay."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--button-hover:\s*rgba\(36, 48, 71, \.32\)' `
    -Message "Button hover should keep its previous darker hierarchy instead of using the lifted secondary surface tint."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--panel-soft:\s*rgba\(32, 42, 61, \.34\)' `
    -Message "Secondary buttons should use a single lighter overlay tint, not a second opaque panel."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '--accent-glass:\s*rgba\(59, 130, 246, \.72\)' `
    -Message "Primary action should remain stronger than neutral surfaces while still allowing acrylic through."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-input\s*\{[\s\S]*background:\s*var\(--secondary-glass\);[\s\S]*backdrop-filter:\s*var\(--glass-blur\);' `
    -Message "Search input should use the shared glass material while keeping text readable."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-field:focus-within \.search-input\s*\{[\s\S]*border-color:\s*rgba\(147, 197, 253, \.48\);[\s\S]*background:\s*rgba\(52, 64, 88, \.34\);' `
    -Message "Focused search input should keep a glass tint instead of a solid focus highlight."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.button\s*\{[\s\S]*background:\s*var\(--panel-soft\);[\s\S]*backdrop-filter:\s*var\(--glass-blur\);' `
    -Message "Buttons should use the shared glass material with their own hierarchy tint."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.action-bar\s*\{[\s\S]*background:\s*var\(--secondary-glass\);[\s\S]*backdrop-filter:\s*var\(--glass-blur\);' `
    -Message "Bottom action bar should use the shared glass material."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.app-row:hover\s*\{[\s\S]*background:\s*var\(--option-hover\);[\s\S]*backdrop-filter:\s*var\(--glass-blur\);' `
    -Message "Option hover state should use the lighter option-specific glass surface."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.app-row\.selected\s*\{[\s\S]*background:\s*var\(--selected\);[\s\S]*box-shadow:\s*inset 0 1px 0 rgba\(255, 255, 255, \.08\);[\s\S]*backdrop-filter:\s*var\(--glass-blur\);' `
    -Message "Selected app rows should use glass material for their highlight state."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.app-icon\s*\{[\s\S]*background:\s*#f8fafc;' `
    -Message "Graphic icon tiles should remain unchanged and not become glass surfaces."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.button\.exit' `
    -Message "Electron UI should style Exit as a tertiary destructive text action."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern 'min-width:\s*500px' `
    -Message "Electron renderer should support the narrower utility-dialog window width."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern 'overflow-y:\s*auto' `
    -Message "Electron app list should remain scrollable if the frameless utility window is resized smaller."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-field:focus-within span,[\s\r\n]*\.search-field\.has-value span' `
    -Message "Electron search label should smoothly transition on focus or value."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-field\s*\{[\s\S]*height:\s*54px;' `
    -Message "Floating search field should be tall enough to separate label and typed text."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-input\s*\{[\s\S]*height:\s*54px;[\s\S]*padding:\s*22px 40px 8px 15px;' `
    -Message "Floating search input should reserve top and right padding for label and clear button."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-field:focus-within span,[\s\r\n]*\.search-field\.has-value span\s*\{[\s\S]*top:\s*9px;[\s\S]*font-size:\s*11px;' `
    -Message "Floating search label should sit at the top-left without overlapping typed text."

Assert-Matches `
    -Text $electronStylesText `
    -Pattern '\.search-field:focus-within \.search-input\s*\{[\s\S]*border-width:\s*2px;' `
    -Message "Focused search input should use a subtle 2px border instead of a loud outer glow."

foreach ($icon in @(
    "firefox.svg",
    "chrome.svg",
    "acrobat.svg",
    "sonicwall.svg",
    "powershell.svg",
    "office.svg",
    "git.svg",
    "vscode.svg",
    "github.svg",
    "ohmyposh.svg",
    "nvm.svg",
    "tightvnc.svg"
)) {
    Assert-True `
        -Condition (Test-Path (Join-Path $electronIconRoot $icon)) `
        -Message "Electron application icon should exist: $icon"
    Assert-Matches `
        -Text $electronCatalogText `
        -Pattern ([regex]::Escape($icon)) `
        -Message "Electron catalog should reference application icon: $icon"
}

if ($failures.Count -gt 0) {
    Write-Output "FAILED: $($failures.Count) static test(s)"
    foreach ($failure in $failures) {
        Write-Output " - $failure"
    }
    exit 1
}

Write-Output "PASSED: CoreSetup static tests"
exit 0
