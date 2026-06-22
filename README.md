# napari-installer

Cross-platform installer for **napari** and related bio-image analysis tools, using Miniforge/conda.

Developed by **Ludovic Leconte & Bruno Pannunzio** — Institut Pasteur de Montevideo.

---

## What it installs

Two conda environments:

| Environment | Contents |
|---|---|
| `napari-env` | napari, cellpose (via napari-serialcellpose), napari-phasors, phasorpy, Jupyter Lab |
| `brighteyes-env` | brighteyes-ism, tifffile, h5py, Jupyter Lab |

---

## Usage

### Windows
1. Download `NAPARI.bat` and `NAPARI.ps1` into the same folder
2. Double-click `NAPARI.bat`
3. Choose `[1]` to install

### macOS / Linux
1. Download `napari.sh`
2. Open a terminal in the download folder
3. Run:
```bash
chmod +x napari.sh
./napari.sh
```
4. Choose `[1]` to install

---

## Menu options

| Key | Action |
|---|---|
| `1` | Install napari environment (napari + cellpose + phasors) |
| `2` | Launch napari |
| `3` | Launch Jupyter Lab (napari-env) |
| `4` | Install BrightEyes environment |
| `5` | Launch Jupyter Lab (brighteyes-env) |
| `6` | Install extra napari plugin |
| `7` | Open conda terminal |
| `8` | Test installations |
| `9` | Repair napari-env |
| `r` | Repair brighteyes-env |
| `u` | Uninstall everything |

---

## Requirements

- Windows 10/11, macOS (Intel or Apple Silicon), or Linux x86_64
- Internet connection for first install (~2 GB download)
- No admin rights required

---

## Notes

- Uses **Miniforge** (conda-forge channel) — not Anaconda
- `napari-env` requires Python 3.12 (required for napari-phasors)
- `brighteyes-env` uses Python 3.10
- `napari-phasors` installed from GitHub (latest dev version)
- Pixi was tested but dropped due to DLL conflicts on Windows

