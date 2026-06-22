# ============================================================
#  NAPARI - Bio-Image Analysis Toolkit
#  Miniforge/Conda edition
#  Ludovic Leconte & Bruno Pannunzio - Institut Pasteur de Montevideo
# ============================================================

$ConfigFile   = "$env:USERPROFILE\.napari-toolkit.txt"
$MiniforgeDir = "$env:USERPROFILE\Miniforge3"
$EnvCours     = "napari-env"
$EnvBright    = "brighteyes-env"
$PhasorsGit   = "git+https://github.com/napari-phasors/napari-phasors.git"
$PhasorPyGit  = "git+https://github.com/phasorpy/phasorpy.git"

function Setup-CondaPath {
    foreach ($p in @("$MiniforgeDir\Scripts","$MiniforgeDir\condabin","$MiniforgeDir","$MiniforgeDir\Library\bin")) {
        if ($env:PATH -notlike "*$p*") { $env:PATH = "$p;$env:PATH" }
    }
}
Setup-CondaPath

function Get-WorkDir {
    if ((Test-Path $ConfigFile) -and (Get-Content $ConfigFile -First 1)) {
        return (Get-Content $ConfigFile -First 1)
    }
    return $null
}

function Conda-Exe { return "$MiniforgeDir\Scripts\conda.exe" }

function Show-Menu {
    Clear-Host
    $workDir = Get-WorkDir
    $condaOK = Test-Path (Conda-Exe)
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "     NAPARI - Bio-Image Analysis Toolkit" -ForegroundColor Cyan
    Write-Host "     Developed by Ludovic Leconte & Bruno Pannunzio" -ForegroundColor DarkGray
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    if ($condaOK) { Write-Host "     Conda : OK" -ForegroundColor Green }
    else          { Write-Host "     Conda : not installed" -ForegroundColor Red }
    if ($workDir) { Write-Host "     Dir   : $workDir" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host "  --- Cours (napari + cellpose + phasors) ---" -ForegroundColor Cyan
    Write-Host "     [1] Install napari-cours"
    Write-Host "     [2] Launch napari"
    Write-Host "     [3] Launch Jupyter Lab  (cours)"
    Write-Host ""
    Write-Host "  --- BrightEyes (HDF5 reader + TIFF export) ---" -ForegroundColor Yellow
    Write-Host "     [4] Install brighteyes-env"
    Write-Host "     [5] Launch Jupyter Lab  (brighteyes)"
    Write-Host ""
    Write-Host "  --- Tools ---" -ForegroundColor DarkGray
    Write-Host "     [6] Install extra plugin  (cours env)"
    Write-Host "     [7] Open conda terminal"
    Write-Host "     [8] Test installations"
    Write-Host "     [9] Repair cours env"
    Write-Host "     [R] Repair brighteyes env"
    Write-Host "     [U] Uninstall everything"
    Write-Host "     [0] Quit"
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Ensure-Miniforge {
    if (Test-Path (Conda-Exe)) {
        Setup-CondaPath
        Write-Host "  [OK] Miniforge found." -ForegroundColor Green
        return $true
    }
    Write-Host "  Downloading Miniforge..." -ForegroundColor Yellow
    $installer = "$env:TEMP\Miniforge3-Windows-x86_64.exe"
    try {
        Invoke-WebRequest -Uri "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe" -OutFile $installer -UseBasicParsing
    } catch {
        Write-Host "  [ERROR] Download failed." -ForegroundColor Red
        return $false
    }
    Write-Host "  Installing Miniforge (silent)..." -ForegroundColor Yellow
    Start-Process -FilePath $installer -ArgumentList "/InstallationType=JustMe /RegisterPython=0 /S /D=$MiniforgeDir" -NoNewWindow -Wait
    if (-not (Test-Path (Conda-Exe))) {
        Write-Host "  [ERROR] Installation failed." -ForegroundColor Red
        return $false
    }
    Setup-CondaPath
    Write-Host "  [OK] Miniforge installed." -ForegroundColor Green
    return $true
}

# ── [1] Install napari-cours ──────────────────────────────────────────────────
function Install-Cours {
    Write-Host ""
    Write-Host "  NAPARI COURS INSTALLATION" -ForegroundColor Cyan
    Write-Host "  =========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Close napari and Jupyter before continuing." -ForegroundColor Red
    Read-Host "  Press Enter when ready"
    Write-Host ""

    if (-not (Ensure-Miniforge)) { return }
    Write-Host ""

    $default = "$env:USERPROFILE\napari-cours"
    $userInput = Read-Host "  Working directory [$default]"
    $workDir = if ([string]::IsNullOrWhiteSpace($userInput)) { $default } else { $userInput }
    if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir | Out-Null }
    Set-Content -Path $ConfigFile -Value $workDir -Encoding ASCII
    Write-Host "  [OK] Directory: $workDir" -ForegroundColor Green
    Write-Host ""

    $conda = Conda-Exe
    $envExists = & $conda env list 2>&1 | Select-String $EnvCours
    if ($envExists) {
        Write-Host "  Environment '$EnvCours' already exists. Updating..." -ForegroundColor Yellow
        & $conda update -n $EnvCours --all -y
    } else {
        Write-Host "  Creating environment '$EnvCours' (5-10 min)..." -ForegroundColor Yellow
        Write-Host "  python 3.12 + napari + pytorch + scikit-image + jupyter" -ForegroundColor Yellow
        Write-Host ""
        & $conda create -n $EnvCours -y python=3.12 napari pyqt pytorch scikit-image scipy matplotlib pandas tifffile jupyter jupyterlab ipykernel git pip
    }
    if ($LASTEXITCODE -ne 0) { Write-Host "  [ERROR] Environment creation failed." -ForegroundColor Red; return }
    Write-Host "  [OK] Environment created." -ForegroundColor Green
    Write-Host ""

    Write-Host "  Installing plugins..." -ForegroundColor Yellow
    Write-Host "  -> napari-serialcellpose..." -ForegroundColor Yellow
    & $conda run -n $EnvCours pip install napari-serialcellpose
    Write-Host "  -> napari-animation..." -ForegroundColor Yellow
    & $conda run -n $EnvCours pip install napari-animation
    Write-Host "  -> napari-phasors (GitHub)..." -ForegroundColor Yellow
    & $conda run -n $EnvCours pip install $PhasorsGit
    Write-Host "  -> phasorpy (GitHub - dev branch)..." -ForegroundColor Yellow
    & $conda run -n $EnvCours pip install --upgrade $PhasorPyGit

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "     COURS INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "     [2] to launch napari" -ForegroundColor Cyan
    Write-Host "     [3] to launch Jupyter Lab" -ForegroundColor Cyan
    Write-Host ""
}

# ── [4] Install brighteyes-env ────────────────────────────────────────────────
function Install-BrightEyes {
    Write-Host ""
    Write-Host "  BRIGHTEYES INSTALLATION" -ForegroundColor Yellow
    Write-Host "  =======================" -ForegroundColor Yellow
    Write-Host ""

    if (-not (Ensure-Miniforge)) { return }

    $conda = Conda-Exe
    $envExists = & $conda env list 2>&1 | Select-String $EnvBright
    if ($envExists) {
        Write-Host "  Environment '$EnvBright' already exists. Updating..." -ForegroundColor Yellow
        & $conda run -n $EnvBright pip install --upgrade brighteyes-ism tifffile matplotlib jupyterlab
    } else {
        Write-Host "  Creating environment '$EnvBright'..." -ForegroundColor Yellow
        Write-Host "  python 3.10 + brighteyes-ism + tifffile + jupyter" -ForegroundColor Yellow
        Write-Host ""
        & $conda create -n $EnvBright -y python=3.10 pip
        if ($LASTEXITCODE -ne 0) { Write-Host "  [ERROR] Environment creation failed." -ForegroundColor Red; return }
        Write-Host "  Installing brighteyes-ism (may take a few minutes)..." -ForegroundColor Yellow
        & $conda run -n $EnvBright pip install brighteyes-ism tifffile matplotlib jupyterlab
    }
    if ($LASTEXITCODE -ne 0) { Write-Host "  [ERROR] Install failed." -ForegroundColor Red; return }

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "     BRIGHTEYES INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "     [5] to launch Jupyter Lab (brighteyes)" -ForegroundColor Yellow
    Write-Host ""
}

# ── [2] Launch napari ─────────────────────────────────────────────────────────
function Start-Napari {
    $workDir = Get-WorkDir
    if (-not $workDir) { Write-Host "  [ERROR] Not installed. Choose [1]." -ForegroundColor Red; return }
    Write-Host "`n  Launching napari  [$EnvCours]...`n" -ForegroundColor Cyan
    Set-Location $workDir
    & (Conda-Exe) run -n $EnvCours napari
}

# ── [3] Jupyter cours ─────────────────────────────────────────────────────────
function Start-JupyterCours {
    $workDir = Get-WorkDir
    if (-not $workDir) { Write-Host "  [ERROR] Not installed. Choose [1]." -ForegroundColor Red; return }
    Write-Host "`n  Launching Jupyter Lab  [$EnvCours]...`n" -ForegroundColor Cyan
    Set-Location $workDir
    & (Conda-Exe) run -n $EnvCours jupyter lab
}

# ── [5] Jupyter brighteyes ────────────────────────────────────────────────────
function Start-JupyterBrightEyes {
    $workDir = Get-WorkDir
    if (-not $workDir) {
        $workDir = "$env:USERPROFILE\napari-cours"
        if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir | Out-Null }
    }
    $conda = Conda-Exe
    $envExists = & $conda env list 2>&1 | Select-String $EnvBright
    if (-not $envExists) {
        Write-Host "  [ERROR] brighteyes-env not installed. Choose [4]." -ForegroundColor Red
        return
    }
    Write-Host "`n  Launching Jupyter Lab  [$EnvBright]...`n" -ForegroundColor Yellow
    Set-Location $workDir
    & $conda run -n $EnvBright jupyter lab
}

# ── [6] Install extra plugin (cours) ─────────────────────────────────────────
function Install-Plugins {
    $workDir = Get-WorkDir
    if (-not $workDir) { Write-Host "  [ERROR] Not installed. Choose [1]." -ForegroundColor Red; return }
    Write-Host ""
    Write-Host "  Install a napari plugin  [$EnvCours]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Examples:"
    Write-Host "    napari-serialcellpose      (cellpose segmentation + analysis)"
    Write-Host "    napari-animation           (make movies)"
    Write-Host "    napari-phasors             (phasor analysis)"
    Write-Host "    napari-skimage-regionprops (object measurements)"
    Write-Host "    napari-segment-blobs-and-things-with-membranes"
    Write-Host "    micro-sam"
    Write-Host ""
    $plugin = Read-Host "  Plugin name (or 'q' to cancel)"
    if ($plugin -eq "q" -or [string]::IsNullOrWhiteSpace($plugin)) { return }
    Write-Host "`n  Installing $plugin..." -ForegroundColor Yellow
    & (Conda-Exe) run -n $EnvCours pip install $plugin
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] $plugin installed." -ForegroundColor Green }
    else { Write-Host "  [ERROR] Failed." -ForegroundColor Red }
}

# ── [7] Open shell ────────────────────────────────────────────────────────────
function Open-Shell {
    $workDir = Get-WorkDir
    if (-not $workDir) { Write-Host "  [ERROR] Not installed. Choose [1]." -ForegroundColor Red; return }
    Write-Host ""
    Write-Host "  Which environment?" -ForegroundColor Cyan
    Write-Host "    [1] $EnvCours   (cours)"
    Write-Host "    [2] $EnvBright  (brighteyes)"
    Write-Host ""
    $choice = Read-Host "  Your choice"
    $env = if ($choice -eq "2") { $EnvBright } else { $EnvCours }
    Write-Host ""
    Write-Host "  Opening terminal in '$env'..." -ForegroundColor Green
    Write-Host "  Type 'exit' to return." -ForegroundColor Yellow
    Write-Host ""
    Set-Location $workDir
    & (Conda-Exe) run -n $env powershell -NoExit -Command "Set-Location '$workDir'; Write-Host '  $env active. Type exit to return.' -ForegroundColor Green"
}

# ── [8] Test both envs ────────────────────────────────────────────────────────
function Test-Installation {
    $conda  = Conda-Exe
    $tmpDir = $env:TEMP

    # Write test scripts to temp files — avoids conda run multiline bug (conda >= 26)
    $scriptCours = "$tmpDir\napari_test_cours.py"
    $scriptBright = "$tmpDir\napari_test_bright.py"

    @"
import sys
def test(pkg, attr='__version__', label=None):
    try:
        m = __import__(pkg)
        v = getattr(m, attr, 'OK')
        print(f'  {label or pkg}: {v}')
    except Exception as e:
        print(f'  {label or pkg}: not installed')

test('napari')
test('torch')
test('cellpose')
test('napari_serialcellpose', label='napari-serialcellpose')
test('napari_phasors',        label='napari-phasors')
test('napari_animation',      label='napari-animation')
test('phasorpy')
"@ | Set-Content -Path $scriptCours -Encoding UTF8

    @"
import sys
def test(pkg, attr='__version__', label=None):
    try:
        m = __import__(pkg)
        v = getattr(m, attr, 'OK')
        print(f'  {label or pkg}: {v}')
    except Exception as e:
        print(f'  {label or pkg}: not installed')

test('brighteyes_ism', label='brighteyes-ism')
test('tifffile')
test('h5py')
"@ | Set-Content -Path $scriptBright -Encoding UTF8

    Write-Host "`n  Testing [$EnvCours]...`n" -ForegroundColor Cyan
    & $conda run -n $EnvCours python $scriptCours 2>&1

    Write-Host ""
    Write-Host "  Testing [$EnvBright]...`n" -ForegroundColor Yellow
    $envExists = & $conda env list 2>&1 | Select-String $EnvBright
    if (-not $envExists) {
        Write-Host "  brighteyes-env not installed. Choose [4]." -ForegroundColor DarkGray
    } else {
        & $conda run -n $EnvBright python $scriptBright 2>&1
    }

    Remove-Item $scriptCours  -Force -ErrorAction SilentlyContinue
    Remove-Item $scriptBright -Force -ErrorAction SilentlyContinue
}

# ── [9] Repair cours ──────────────────────────────────────────────────────────
function Repair-Cours {
    Write-Host ""
    Write-Host "  Close napari and Jupyter first." -ForegroundColor Red
    Read-Host "  Press Enter when ready"
    Write-Host "`n  Removing '$EnvCours'..." -ForegroundColor Yellow
    & (Conda-Exe) env remove -n $EnvCours -y
    Write-Host "  Recreating..." -ForegroundColor Yellow
    & (Conda-Exe) create -n $EnvCours -y python=3.12 napari pyqt pytorch scikit-image scipy matplotlib pandas tifffile jupyter jupyterlab ipykernel git pip
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Reinstalling plugins..." -ForegroundColor Yellow
        & (Conda-Exe) run -n $EnvCours pip install napari-serialcellpose napari-animation $PhasorsGit $PhasorPyGit
        Write-Host "  [OK] Repair complete." -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Repair failed." -ForegroundColor Red
    }
}

# ── [R] Repair brighteyes ─────────────────────────────────────────────────────
function Repair-BrightEyes {
    Write-Host "`n  Removing '$EnvBright'..." -ForegroundColor Yellow
    & (Conda-Exe) env remove -n $EnvBright -y
    Write-Host "  Recreating..." -ForegroundColor Yellow
    & (Conda-Exe) create -n $EnvBright -y python=3.10 pip
    & (Conda-Exe) run -n $EnvBright pip install brighteyes-ism tifffile matplotlib jupyterlab
    if ($LASTEXITCODE -eq 0) { Write-Host "  [OK] Repair complete." -ForegroundColor Green }
    else { Write-Host "  [ERROR] Repair failed." -ForegroundColor Red }
}

# ── [U] Uninstall everything ──────────────────────────────────────────────────
function Uninstall-Everything {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "     UNINSTALL" -ForegroundColor Red
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This will remove:" -ForegroundColor Yellow
    Write-Host ""
    $workDir = Get-WorkDir
    $condaExists = Test-Path (Conda-Exe)
    if ($condaExists) {
        Write-Host "     - Conda environments '$EnvCours' and '$EnvBright'" -ForegroundColor Yellow
        Write-Host "     - Miniforge ($MiniforgeDir)" -ForegroundColor Yellow
    }
    if ($workDir -and (Test-Path $workDir)) {
        Write-Host "     - Working directory ($workDir)" -ForegroundColor Yellow
    }
    Write-Host "     - Config file" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Your images and notebooks will also be deleted!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Type 'YES' to confirm uninstall"
    if ($confirm -ne "YES") { Write-Host "  Cancelled." -ForegroundColor Green; return }
    Write-Host ""
    if ($condaExists) {
        Write-Host "  Removing environments..." -ForegroundColor Yellow
        & (Conda-Exe) env remove -n $EnvCours  -y 2>$null
        & (Conda-Exe) env remove -n $EnvBright -y 2>$null
        Write-Host "  [OK] Environments removed." -ForegroundColor Green
    }
    if (Test-Path $MiniforgeDir) {
        Write-Host "  Removing Miniforge..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $MiniforgeDir -ErrorAction SilentlyContinue
        Write-Host "  [OK] Miniforge removed." -ForegroundColor Green
    }
    if ($workDir -and (Test-Path $workDir)) {
        Write-Host "  Removing working directory..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
        Write-Host "  [OK] Working directory removed." -ForegroundColor Green
    }
    if (Test-Path $ConfigFile) { Remove-Item $ConfigFile -Force }
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "     UNINSTALL COMPLETE" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  You can delete NAPARI.bat and NAPARI.ps1 manually." -ForegroundColor Green
    Write-Host ""
}

# ---- Main ----
do {
    Show-Menu
    $c = Read-Host "  Your choice (0-9 / R / U)"
    switch ($c) {
        "1" { Install-Cours }
        "2" { Start-Napari }
        "3" { Start-JupyterCours }
        "4" { Install-BrightEyes }
        "5" { Start-JupyterBrightEyes }
        "6" { Install-Plugins }
        "7" { Open-Shell }
        "8" { Test-Installation }
        "9" { Repair-Cours }
        "R" { Repair-BrightEyes }
        "r" { Repair-BrightEyes }
        "U" { Uninstall-Everything }
        "u" { Uninstall-Everything }
        "0" { exit }
        default { Write-Host "  Invalid choice." -ForegroundColor Red }
    }
    if ($c -ne "0") { Write-Host ""; Read-Host "  Press Enter to return to menu" }
} while ($true)
