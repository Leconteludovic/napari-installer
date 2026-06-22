@echo off
:: ============================================================
::  NAPARI - Bio-Image Analysis Toolkit
::  Launcher for NAPARI.ps1
::  Ludovic Leconte & Bruno Pannunzio - Institut Pasteur de Montevideo
:: ============================================================

:: Get the directory where this .bat file lives
set "SCRIPT_DIR=%~dp0"
set "PS1_FILE=%SCRIPT_DIR%NAPARI.ps1"

:: Check that NAPARI.ps1 exists next to this file
if not exist "%PS1_FILE%" (
    echo.
    echo  [ERROR] NAPARI.ps1 not found in: %SCRIPT_DIR%
    echo  Make sure NAPARI.bat and NAPARI.ps1 are in the same folder.
    echo.
    pause
    exit /b 1
)

:: Launch PowerShell with execution policy bypass (no admin required)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
