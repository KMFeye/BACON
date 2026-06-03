#!/bin/bash
# This script sets up the complete environment for the Nextflow pipelines
# Make it executable with the command: chmod +x setup.sh
# Execute it with: bash setup.sh

set -e -o pipefail # Exit immediately if any command fails.

echo "--- STARTING BACON SETUP ---"

# --- 1. DEFINE PATHS ---
# Tools like Conda go to $HOME
export TOOL_BASE="$HOME"

# Everything else goes inside this cloned repository!
export REPO_DIR=$(pwd)
export DB_BASE_PATH="$REPO_DIR/databases"
export BAKTA_DB_PATH="$DB_BASE_PATH/bakta_db"
export PLATON_DB_PATH="$DB_BASE_PATH/platon_db"
export KRAKEN_DB_PATH="$DB_BASE_PATH/kraken_db"
export LOCAL_BIN="$REPO_DIR/bin"

# Create necessary folders inside the repo
mkdir -p "$BAKTA_DB_PATH" "$PLATON_DB_PATH" "$KRAKEN_DB_PATH" "$LOCAL_BIN" "$REPO_DIR/inputs"

echo "Tools will be installed in: $TOOL_BASE/miniconda3"
echo "Databases and config files will be in: $REPO_DIR"
echo "Please place your raw .bam files in: $REPO_DIR/inputs"

# --- 2. INSTALL CORE DEPENDENCIES ---
echo "--> Checking for Miniconda..."
if [ -d "$TOOL_BASE/miniconda3" ]; then
    echo "Miniconda is already installed."
else
    if [ ! -f "miniconda.sh" ]; then
        echo "Miniconda installer not found. Downloading..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    fi
    echo "Running Miniconda installer..."
    bash miniconda.sh -b -p "$TOOL_BASE/miniconda3"
    rm miniconda.sh
fi

echo "--> Initializing Conda for this script session..."
source "$TOOL_BASE/miniconda3/etc/profile.d/conda.sh"
conda init bash
export PATH="$TOOL_BASE/miniconda3/bin:$PATH"
conda config --add channels bioconda --force
conda config --add channels conda-forge --force
conda config --set channel_priority flexible

echo "--> Accepting Anaconda Terms of Service..."
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true

# --- 3. NEXTFLOW & JAVA INSTALLATION ---
echo "--> Installing/Verifying Java (OpenJDK 17) in base environment..."
conda install -n base -y -c conda-forge openjdk=17

echo "--> Installing/Verifying Nextflow..."
if ! command -v nextflow &> /dev/null; then
    echo "Nextflow not found. Installing to local bin..."
    curl -s https://get.nextflow.io | bash
    mv nextflow "$LOCAL_BIN/"
    PATH_LINE="export PATH=\"$LOCAL_BIN:\$PATH\""
    if ! grep -qF "$PATH_LINE" ~/.bashrc; then
        echo "Adding local bin to your PATH in .bashrc..."
        echo '' >> ~/.bashrc; echo '# Add BACON bin to PATH for Nextflow' >> ~/.bashrc; echo "$PATH_LINE" >> ~/.bashrc
    fi
    export PATH="$LOCAL_BIN:$PATH"
    echo "Nextflow has been installed to $LOCAL_BIN."
else
    echo "Nextflow is already installed."
fi 

# --- 4. Google, Git, and R/R-Studio Setup ---
echo "--> Scanning the system for Google Chrome, Git, and R/R-Studio"

if ! command -v google-chrome &> /dev/null; then
    echo "Google Chrome not found. Installing..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
else
    echo "Google Chrome is already installed."
fi

if ! command -v git &> /dev/null; then
    echo "Git not found system-wide. Installing via apt..."
    sudo apt-get update
    sudo apt-get install -y git
else
    echo "Git is already installed system-wide."
fi

if command -v rstudio &> /dev/null; then
    echo "RStudio Desktop is already installed."
else
    echo "--> Installing system R and prerequisites for RStudio..."
    sudo apt-get update
    sudo apt-get install -y r-base gdebi-core 
    RSTUDIO_DEB_URL="https://download1.rstudio.org/electron/jammy/amd64/rstudio-2023.12.1-402-amd64.deb" 
    RSTUDIO_DEB_FILE="rstudio-desktop.deb"
    wget -q "$RSTUDIO_DEB_URL" -O "$RSTUDIO_DEB_FILE"
    echo "--> Installing RStudio Desktop. This step will require your sudo password."
    sudo gdebi -n "$RSTUDIO_DEB_FILE"
    rm -f "$RSTUDIO_DEB_FILE"
fi

# --- 5. DATABASE INSTALLATION ---
echo "--> Downloading necessary databases into the repository"

# --- BAKTA DATABASE ---
if [ -d "$BAKTA_DB_PATH/db" ] && [ -n "$(ls -A "$BAKTA_DB_PATH/db" 2>/dev/null)" ]; then
    echo "--> Bakta database found. Skipping download."
else
    echo "--> Bakta database not found. Installing..."
    echo "--> Searching for Bakta Database"
    cd "$BAKTA_DB_PATH" || exit 1
    # Use -O to save a clean filename, then -xJf for .xz extraction
    wget -O db.tar.xz "https://zenodo.org/records/14916843/files/db.tar.xz?download=1"
    tar -xJf db.tar.xz
    rm db.tar.xz
    cd "$REPO_DIR"
    echo "--> Bakta database installation complete."
fi

# --- MANUALLY PRE-BUILD MOB-SUITE ENVIRONMENT ---
echo "--> Pre-building the 'mobsuite_env' due to Conda solver issues..."
if conda info --envs | grep -q "^mobsuite_env\s"; then
    echo "'mobsuite_env' already exists. Skipping creation."
else
    conda create -n mobsuite_env -y
    conda activate mobsuite_env
    conda install -c bioconda mob_suite -y
    conda deactivate
    echo "'mobsuite_env' successfully created."
fi

# --- PLATON DATABASE ---
echo "--> Searching for PLATON Database"
if [ -f "$PLATON_DB_PATH/db/orit.nhr" ] || [ -f "$PLATON_DB_PATH/db/plasmids_db.fasta" ]; then
    echo "--> Platon database found. Skipping download."
else
    echo "--> Platon database not found. Installing..."
    cd "$PLATON_DB_PATH" || exit 1
    # Use -O to save a clean filename
    wget -O db.tar.gz "https://zenodo.org/records/4066768/files/db.tar.gz?download=1"
    tar -xzf db.tar.gz
    rm db.tar.gz
    cd "$REPO_DIR"
    echo "--> Platon database installation complete."
fi

# --- KRAKEN DATABASE ---
echo "--> Searching for KRAKEN database"
if [ -f "$KRAKEN_DB_PATH/hash.k2d" ]; then
    echo "--> KRAKEN database found. Skipping download."
else
    echo "--> KRAKEN database not found. Installing..."
    cd "$KRAKEN_DB_PATH" || exit 1
    wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08_GB_20260226.tar.gz
    echo "--> Unpacking KRAKEN database (this may take a while)..."
    tar -xzf k2_standard_08_GB_20260226.tar.gz
    echo "--> Cleaning up..."
    rm k2_standard_08_GB_20260226.tar.gz
    cd "$REPO_DIR"
    echo "--> KRAKEN database installation complete."
fi

echo "All done setting up the databases."

# --- 6. Final Directions ---
echo ""
echo "---!!! CRITICAL FINAL STEP !!!---"
echo "The Bakta database path MUST be correct in your 'nextflow.config' file."
echo "Please ensure it matches: params { bakta_db = '$BAKTA_DB_PATH/db' }"
echo ""
echo "--- SETUP COMPLETE ---"
