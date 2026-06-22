#!/bin/bash
# ============================================================
#  NAPARI - Bio-Image Analysis Toolkit
#  Miniforge/Conda edition
#  Ludovic Leconte & Bruno Pannunzio - Institut Pasteur de Montevideo
# ============================================================

CONFIG_FILE="$HOME/.napari-toolkit.txt"
MINIFORGE_DIR="$HOME/miniforge3"
ENV_COURS="napari-env"
ENV_BRIGHT="brighteyes-env"
PHASORS_GIT="git+https://github.com/napari-phasors/napari-phasors.git"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

setup_conda_path() {
    export PATH="$MINIFORGE_DIR/bin:$MINIFORGE_DIR/condabin:$PATH"
}
setup_conda_path

get_workdir() {
    if [ -f "$CONFIG_FILE" ]; then head -1 "$CONFIG_FILE"; fi
}

conda_exe() { echo "$MINIFORGE_DIR/bin/conda"; }

show_menu() {
    clear
    WORKDIR=$(get_workdir)
    CONDA_OK=false
    [ -f "$(conda_exe)" ] && CONDA_OK=true
    echo ""
    echo -e "  ${CYAN}============================================================${NC}"
    echo -e "  ${CYAN}   NAPARI - Bio-Image Analysis Toolkit${NC}"
    echo -e "  ${GRAY}   Developed by Ludovic Leconte & Bruno Pannunzio${NC}"
    echo -e "  ${CYAN}============================================================${NC}"
    echo ""
    if $CONDA_OK; then echo -e "     Conda : ${GREEN}OK${NC}"
    else               echo -e "     Conda : ${RED}not installed${NC}"; fi
    if [ -n "$WORKDIR" ]; then
        echo -e "     Dir   : ${GRAY}$WORKDIR${NC}"
    fi
    echo ""
    echo -e "  ${CYAN}--- Cours (napari + cellpose + phasors) ---${NC}"
    echo "     [1] Install napari-cours"
    echo "     [2] Launch napari"
    echo "     [3] Launch Jupyter Lab  (cours)"
    echo ""
    echo -e "  ${YELLOW}--- BrightEyes (HDF5 reader + TIFF export) ---${NC}"
    echo "     [4] Install brighteyes-env"
    echo "     [5] Launch Jupyter Lab  (brighteyes)"
    echo ""
    echo -e "  ${GRAY}--- Tools ---${NC}"
    echo "     [6] Install extra plugin  (cours env)"
    echo "     [7] Open conda terminal"
    echo "     [8] Test installations"
    echo "     [9] Repair cours env"
    echo "     [r] Repair brighteyes env"
    echo "     [u] Uninstall everything"
    echo "     [0] Quit"
    echo ""
    echo -e "  ${CYAN}============================================================${NC}"
    echo ""
}

ensure_miniforge() {
    if [ -f "$(conda_exe)" ]; then
        setup_conda_path
        echo -e "  ${GREEN}[OK] Miniforge found.${NC}"
        return 0
    fi
    echo -e "  ${YELLOW}Downloading Miniforge...${NC}"
    ARCH=$(uname -m); OS=$(uname -s)
    if [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
        else URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"; fi
    else URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"; fi
    INSTALLER="/tmp/miniforge_installer.sh"
    curl -fsSL "$URL" -o "$INSTALLER"
    if [ $? -ne 0 ]; then echo -e "  ${RED}[ERROR] Download failed.${NC}"; return 1; fi
    echo -e "  ${YELLOW}Installing Miniforge...${NC}"
    bash "$INSTALLER" -b -p "$MINIFORGE_DIR"
    if [ $? -ne 0 ]; then echo -e "  ${RED}[ERROR] Installation failed.${NC}"; return 1; fi
    setup_conda_path
    echo -e "  ${GREEN}[OK] Miniforge installed.${NC}"
    return 0
}

# ── [1] Install napari-cours ──────────────────────────────────────────────────
install_cours() {
    echo ""
    echo -e "  ${CYAN}NAPARI COURS INSTALLATION${NC}"
    echo -e "  ${CYAN}=========================${NC}"
    echo ""
    echo -e "  ${RED}Close napari and Jupyter before continuing.${NC}"
    read -p "  Press Enter when ready"
    echo ""
    ensure_miniforge || return
    echo ""
    DEFAULT="$HOME/napari-cours"
    read -p "  Working directory [$DEFAULT]: " USERDIR
    WORKDIR="${USERDIR:-$DEFAULT}"
    mkdir -p "$WORKDIR"
    echo "$WORKDIR" > "$CONFIG_FILE"
    echo -e "  ${GREEN}[OK] Directory: $WORKDIR${NC}"
    echo ""
    CONDA=$(conda_exe)
    if $CONDA env list 2>&1 | grep -q "$ENV_COURS"; then
        echo -e "  ${YELLOW}Environment '$ENV_COURS' already exists. Updating...${NC}"
        $CONDA update -n $ENV_COURS --all -y
    else
        echo -e "  ${YELLOW}Creating environment '$ENV_COURS' (5-10 min)...${NC}"
        echo -e "  ${YELLOW}python 3.11 + napari + pytorch + scikit-image + jupyter${NC}"
        echo ""
        $CONDA create -n $ENV_COURS -y \
            python=3.11 napari pyqt pytorch scikit-image scipy \
            matplotlib pandas tifffile jupyter jupyterlab ipykernel git pip
    fi
    if [ $? -ne 0 ]; then echo -e "  ${RED}[ERROR] Environment creation failed.${NC}"; return; fi
    echo -e "  ${GREEN}[OK] Environment created.${NC}"
    echo ""
    echo -e "  ${YELLOW}Installing plugins...${NC}"
    echo -e "  ${YELLOW}-> napari-serialcellpose...${NC}"
    $CONDA run -n $ENV_COURS pip install napari-serialcellpose
    echo -e "  ${YELLOW}-> napari-animation...${NC}"
    $CONDA run -n $ENV_COURS pip install napari-animation
    echo -e "  ${YELLOW}-> napari-phasors (GitHub)...${NC}"
    $CONDA run -n $ENV_COURS pip install "$PHASORS_GIT"
    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}   COURS INSTALLATION COMPLETE!${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
    echo -e "     ${CYAN}[2] to launch napari${NC}"
    echo -e "     ${CYAN}[3] to launch Jupyter Lab${NC}"
    echo ""
}

# ── [4] Install brighteyes-env ────────────────────────────────────────────────
install_brighteyes() {
    echo ""
    echo -e "  ${YELLOW}BRIGHTEYES INSTALLATION${NC}"
    echo -e "  ${YELLOW}=======================${NC}"
    echo ""
    ensure_miniforge || return
    CONDA=$(conda_exe)
    if $CONDA env list 2>&1 | grep -q "$ENV_BRIGHT"; then
        echo -e "  ${YELLOW}Environment '$ENV_BRIGHT' already exists. Updating...${NC}"
        $CONDA run -n $ENV_BRIGHT pip install --upgrade brighteyes-ism tifffile matplotlib jupyterlab
    else
        echo -e "  ${YELLOW}Creating environment '$ENV_BRIGHT'...${NC}"
        echo -e "  ${YELLOW}python 3.10 + brighteyes-ism + tifffile + jupyter${NC}"
        echo ""
        $CONDA create -n $ENV_BRIGHT -y python=3.10 pip
        if [ $? -ne 0 ]; then echo -e "  ${RED}[ERROR] Environment creation failed.${NC}"; return; fi
        echo -e "  ${YELLOW}Installing brighteyes-ism (may take a few minutes)...${NC}"
        $CONDA run -n $ENV_BRIGHT pip install brighteyes-ism tifffile matplotlib jupyterlab
    fi
    if [ $? -ne 0 ]; then echo -e "  ${RED}[ERROR] Install failed.${NC}"; return; fi
    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}   BRIGHTEYES INSTALLATION COMPLETE!${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
    echo -e "     ${YELLOW}[5] to launch Jupyter Lab (brighteyes)${NC}"
    echo ""
}

# ── [2] Launch napari ─────────────────────────────────────────────────────────
start_napari() {
    WORKDIR=$(get_workdir)
    if [ -z "$WORKDIR" ]; then echo -e "  ${RED}[ERROR] Not installed. Choose [1].${NC}"; return; fi
    echo -e "\n  ${CYAN}Launching napari  [$ENV_COURS]...${NC}\n"
    cd "$WORKDIR"
    $(conda_exe) run -n $ENV_COURS napari
}

# ── [3] Jupyter cours ─────────────────────────────────────────────────────────
start_jupyter_cours() {
    WORKDIR=$(get_workdir)
    if [ -z "$WORKDIR" ]; then echo -e "  ${RED}[ERROR] Not installed. Choose [1].${NC}"; return; fi
    echo -e "\n  ${CYAN}Launching Jupyter Lab  [$ENV_COURS]...${NC}\n"
    cd "$WORKDIR"
    $(conda_exe) run -n $ENV_COURS jupyter lab
}

# ── [5] Jupyter brighteyes ────────────────────────────────────────────────────
start_jupyter_brighteyes() {
    WORKDIR=$(get_workdir)
    if [ -z "$WORKDIR" ]; then
        WORKDIR="$HOME/napari-cours"
        mkdir -p "$WORKDIR"
    fi
    if ! $(conda_exe) env list 2>&1 | grep -q "$ENV_BRIGHT"; then
        echo -e "  ${RED}[ERROR] brighteyes-env not installed. Choose [4].${NC}"
        return
    fi
    echo -e "\n  ${YELLOW}Launching Jupyter Lab  [$ENV_BRIGHT]...${NC}\n"
    cd "$WORKDIR"
    $(conda_exe) run -n $ENV_BRIGHT jupyter lab
}

# ── [6] Install extra plugin (cours) ─────────────────────────────────────────
install_plugins() {
    WORKDIR=$(get_workdir)
    if [ -z "$WORKDIR" ]; then echo -e "  ${RED}[ERROR] Not installed. Choose [1].${NC}"; return; fi
    echo ""
    echo -e "  ${CYAN}Install a napari plugin  [$ENV_COURS]${NC}"
    echo ""
    echo "  Examples:"
    echo "    napari-serialcellpose      (cellpose segmentation + analysis)"
    echo "    napari-animation           (make movies)"
    echo "    napari-phasors             (phasor analysis)"
    echo "    napari-skimage-regionprops (object measurements)"
    echo "    napari-segment-blobs-and-things-with-membranes"
    echo "    micro-sam"
    echo ""
    read -p "  Plugin name (or 'q' to cancel): " PLUGIN
    if [ "$PLUGIN" = "q" ] || [ -z "$PLUGIN" ]; then return; fi
    echo -e "\n  ${YELLOW}Installing $PLUGIN...${NC}"
    $(conda_exe) run -n $ENV_COURS pip install "$PLUGIN"
    if [ $? -eq 0 ]; then echo -e "  ${GREEN}[OK] $PLUGIN installed.${NC}"
    else echo -e "  ${RED}[ERROR] Failed.${NC}"; fi
}

# ── [7] Open shell ────────────────────────────────────────────────────────────
open_shell() {
    WORKDIR=$(get_workdir)
    if [ -z "$WORKDIR" ]; then echo -e "  ${RED}[ERROR] Not installed. Choose [1].${NC}"; return; fi
    echo ""
    echo -e "  ${CYAN}Which environment?${NC}"
    echo "    [1] $ENV_COURS   (cours)"
    echo "    [2] $ENV_BRIGHT  (brighteyes)"
    echo ""
    read -p "  Your choice: " CHOICE
    if [ "$CHOICE" = "2" ]; then ENV_SEL=$ENV_BRIGHT; else ENV_SEL=$ENV_COURS; fi
    echo ""
    echo -e "  ${GREEN}Opening terminal in '$ENV_SEL'...${NC}"
    echo -e "  ${YELLOW}Type 'exit' to return.${NC}"
    echo ""
    cd "$WORKDIR"
    $(conda_exe) run -n $ENV_SEL bash
}

# ── [8] Test both envs ────────────────────────────────────────────────────────
test_installation() {
    CONDA=$(conda_exe)
    echo -e "\n  ${CYAN}Testing [$ENV_COURS]...${NC}\n"
    $CONDA run -n $ENV_COURS python -c "import napari; print('  napari:', napari.__version__)"
    $CONDA run -n $ENV_COURS python -c "import torch; print('  torch:', torch.__version__)"
    $CONDA run -n $ENV_COURS python -c "
try:
    import cellpose; print('  cellpose:', cellpose.__version__)
except: print('  cellpose: not installed')"
    $CONDA run -n $ENV_COURS python -c "
try:
    import napari_serialcellpose; print('  napari-serialcellpose: OK')
except: print('  napari-serialcellpose: not installed')"
    $CONDA run -n $ENV_COURS python -c "
try:
    import napari_phasors; print('  napari-phasors: OK')
except: print('  napari-phasors: not installed')"
    $CONDA run -n $ENV_COURS python -c "
try:
    import napari_animation; print('  napari-animation: OK')
except: print('  napari-animation: not installed')"
    $CONDA run -n $ENV_COURS python -c "
try:
    import phasorpy; print('  phasorpy:', phasorpy.__version__)
except: print('  phasorpy: not installed')"

    echo ""
    echo -e "  ${YELLOW}Testing [$ENV_BRIGHT]...${NC}\n"
    if ! $CONDA env list 2>&1 | grep -q "$ENV_BRIGHT"; then
        echo -e "  ${GRAY}brighteyes-env not installed. Choose [4].${NC}"
    else
        $CONDA run -n $ENV_BRIGHT python -c "
try:
    import brighteyes_ism; print('  brighteyes-ism: OK')
except: print('  brighteyes-ism: not installed')"
        $CONDA run -n $ENV_BRIGHT python -c "import tifffile; print('  tifffile:', tifffile.__version__)"
        $CONDA run -n $ENV_BRIGHT python -c "import h5py; print('  h5py:', h5py.__version__)"
    fi
}

# ── [9] Repair cours ──────────────────────────────────────────────────────────
repair_cours() {
    echo ""
    echo -e "  ${RED}Close napari and Jupyter first.${NC}"
    read -p "  Press Enter when ready"
    echo -e "\n  ${YELLOW}Removing '$ENV_COURS'...${NC}"
    $(conda_exe) env remove -n $ENV_COURS -y
    echo -e "  ${YELLOW}Recreating...${NC}"
    $(conda_exe) create -n $ENV_COURS -y \
        python=3.11 napari pyqt pytorch scikit-image scipy \
        matplotlib pandas tifffile jupyter jupyterlab ipykernel git pip
    if [ $? -eq 0 ]; then
        echo -e "  ${YELLOW}Reinstalling plugins...${NC}"
        $(conda_exe) run -n $ENV_COURS pip install napari-serialcellpose napari-animation "$PHASORS_GIT"
        echo -e "  ${GREEN}[OK] Repair complete.${NC}"
    else
        echo -e "  ${RED}[ERROR] Repair failed.${NC}"
    fi
}

# ── [r] Repair brighteyes ─────────────────────────────────────────────────────
repair_brighteyes() {
    echo -e "\n  ${YELLOW}Removing '$ENV_BRIGHT'...${NC}"
    $(conda_exe) env remove -n $ENV_BRIGHT -y
    echo -e "  ${YELLOW}Recreating...${NC}"
    $(conda_exe) create -n $ENV_BRIGHT -y python=3.10 pip
    $(conda_exe) run -n $ENV_BRIGHT pip install brighteyes-ism tifffile matplotlib jupyterlab
    if [ $? -eq 0 ]; then echo -e "  ${GREEN}[OK] Repair complete.${NC}"
    else echo -e "  ${RED}[ERROR] Repair failed.${NC}"; fi
}

# ── [u] Uninstall everything ──────────────────────────────────────────────────
uninstall_everything() {
    echo ""
    echo -e "  ${RED}============================================================${NC}"
    echo -e "  ${RED}   UNINSTALL${NC}"
    echo -e "  ${RED}============================================================${NC}"
    echo ""
    echo -e "  ${YELLOW}This will remove:${NC}"
    echo ""
    WORKDIR=$(get_workdir)
    CONDA_EXISTS=false
    [ -f "$(conda_exe)" ] && CONDA_EXISTS=true
    if $CONDA_EXISTS; then
        echo -e "  ${YELLOW}   - Conda environments '$ENV_COURS' and '$ENV_BRIGHT'${NC}"
        echo -e "  ${YELLOW}   - Miniforge ($MINIFORGE_DIR)${NC}"
    fi
    if [ -n "$WORKDIR" ] && [ -d "$WORKDIR" ]; then
        echo -e "  ${YELLOW}   - Working directory ($WORKDIR)${NC}"
    fi
    echo -e "  ${YELLOW}   - Config file${NC}"
    echo ""
    echo -e "  ${RED}Your images and notebooks will also be deleted!${NC}"
    echo ""
    read -p "  Type 'YES' to confirm uninstall: " CONFIRM
    if [ "$CONFIRM" != "YES" ]; then echo -e "  ${GREEN}Cancelled.${NC}"; return; fi
    echo ""
    if $CONDA_EXISTS; then
        echo -e "  ${YELLOW}Removing environments...${NC}"
        $(conda_exe) env remove -n $ENV_COURS  -y 2>/dev/null
        $(conda_exe) env remove -n $ENV_BRIGHT -y 2>/dev/null
        echo -e "  ${GREEN}[OK] Environments removed.${NC}"
    fi
    if [ -d "$MINIFORGE_DIR" ]; then
        echo -e "  ${YELLOW}Removing Miniforge ($MINIFORGE_DIR)...${NC}"
        rm -rf "$MINIFORGE_DIR"
        echo -e "  ${GREEN}[OK] Miniforge removed.${NC}"
    fi
    if [ -n "$WORKDIR" ] && [ -d "$WORKDIR" ]; then
        echo -e "  ${YELLOW}Removing working directory...${NC}"
        rm -rf "$WORKDIR"
        echo -e "  ${GREEN}[OK] Working directory removed.${NC}"
    fi
    rm -f "$CONFIG_FILE"
    for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile"; do
        if [ -f "$RC" ]; then
            sed -i.bak '/miniforge3/d' "$RC" 2>/dev/null
            sed -i.bak '/conda initialize/,/conda initialize/d' "$RC" 2>/dev/null
            rm -f "${RC}.bak"
        fi
    done
    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}   UNINSTALL COMPLETE${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
    echo -e "  ${GREEN}You can delete napari.sh and NAPARI.command manually.${NC}"
    echo ""
}

# ---- Main ----
while true; do
    show_menu
    read -p "  Your choice (0-9 / r / u): " CHOICE
    case $CHOICE in
        1) install_cours ;;
        2) start_napari ;;
        3) start_jupyter_cours ;;
        4) install_brighteyes ;;
        5) start_jupyter_brighteyes ;;
        6) install_plugins ;;
        7) open_shell ;;
        8) test_installation ;;
        9) repair_cours ;;
        r) repair_brighteyes ;;
        u) uninstall_everything ;;
        0) exit 0 ;;
        *) echo -e "  ${RED}Invalid choice.${NC}" ;;
    esac
    if [ "$CHOICE" != "0" ]; then echo ""; read -p "  Press Enter to return to menu"; fi
done
