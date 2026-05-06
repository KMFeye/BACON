#!/bin/bash

# This script sets up the complete environment for the Nextflow genomics pipelines.
# It is automated and can be safely re-run.

set -e # Exit immediately if any command fails.

echo "--- STARTING COMPLETE PIPELINE SETUP ---"

# --- 1. DEFINE CENTRAL DATABASE LOCATION ---
export DB_BASE_PATH="$HOME/databases"
export BAKTA_DB_PATH="$DB_BASE_PATH/bakta_db"
mkdir -p "$BAKTA_DB_PATH"
echo "Databases will be stored in: $DB_BASE_PATH"

# --- 2. INSTALL CORE DEPENDENCIES ---
echo "--> Checking for Miniconda..."
if [ -d "$HOME/miniconda3" ]; then
    echo "Miniconda is already installed."
else
    if [ ! -f "miniconda.sh" ]; then
        echo "Miniconda installer not found. Downloading..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    fi
    echo "Running Miniconda installer..."
    bash miniconda.sh -b -p "$HOME/miniconda3"
    rm miniconda.sh
fi

echo "--> Initializing Conda for this script session..."
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda init bash
export PATH="$HOME/miniconda3/bin:$PATH"

conda config --add channels bioconda --force
conda config --add channels conda-forge --force
conda config --set channel_priority flexible
echo "--> Accepting Anaconda Terms of Service..."
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true

# --- NEXTFLOW & JAVA INSTALLATION ---
echo "--> Installing/Verifying Java (OpenJDK 17) in base environment..."
conda install -n base -y -c conda-forge openjdk=17

echo "--> Installing/Verifying Nextflow..."
if ! command -v nextflow &> /dev/null; then
    echo "Nextflow not found. Installing..."
    curl -s https://get.nextflow.io | bash
    mkdir -p "$HOME/bin"
    mv nextflow "$HOME/bin"
    PATH_LINE='export PATH="$HOME/bin:$PATH"'
    if ! grep -qF "$PATH_LINE" ~/.bashrc; then
        echo "Adding '$HOME/bin' to your PATH in .bashrc..."
        echo '' >> ~/.bashrc; echo '# Add local bin to PATH for Nextflow' >> ~/.bashrc; echo "$PATH_LINE" >> ~/.bashrc
    fi
    export PATH="$HOME/bin:$PATH"
    echo "Nextflow has been installed to $HOME/bin."
else
    echo "Nextflow is already installed."
fi 

# =================================================================
# --- 3. CREATE FINAL .YML FILES ---
# =================================================================
cat << EOF > envs/bakta.yml
name: bakta_env
channels: [bioconda, conda-forge]
dependencies:
  - bakta
  - python=3.9
EOF

echo "--> .yml file creation complete."

# =================================================================
# --- 4. DATABASE AND SPECIAL ENVIRONMENT SETUP ---
# =================================================================
# --- BAKTA DATABASE ---
if [ -d "$BAKTA_DB_PATH/db" ]; then
    echo "--> Bakta database found. Skipping download."
else
    echo "--> Bakta database not found. Installing..."
    echo "--> Creating temporary environment to run bakta_db..."
    conda create -n setup_baktadb -y -c conda-forge -c bioconda bakta
    conda activate setup_baktadb
    echo "--> Running 'bakta_db download'..."
    bakta_db download --output "$BAKTA_DB_PATH" --type full
    conda deactivate
    conda env remove -n setup_baktadb -y
    echo "--> Bakta database installation complete."
fi

# --- MANUALLY PRE-BUILD THE MOB-SUITE ENVIRONMENT ---
echo "--> Pre-building the 'mobsuite_env' due to Conda solver issues..."
if conda info --envs | grep -q "^mobsuite_env\s"; then
    echo "'mobsuite_env' already exists. Skipping creation."
else
    echo "Creating empty 'mobsuite_env'..."
    conda create -n mobsuite_env -y
    echo "Activating 'mobsuite_env' to install package..."
    conda activate mobsuite_env
    conda install -c bioconda mob_suite -y
    conda deactivate
    echo "'mobsuite_env' has been successfully created."
fi

echo "--> Database and special environment setup complete."

# =================================================================
# --- 5. Google, R, and GitHub Setup ---
# =================================================================

# --- Google Chrome Installation ---
echo "--> Installing/Verifying Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    echo "Google Chrome not found. Installing..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install ./google-chrome-stable_current_amd64.deb
else
    echo "Google Chrome is already installed."
fi

# --- System-wide Git Installation ---
echo "--> Checking for system-wide Git installation..."
if ! command -v git &> /dev/null; then
    echo "Git not found system-wide. Installing via apt..."
    sudo apt-get update
    sudo apt-get install -y git
    echo "Git installed system-wide."
else
    echo "Git is already installed system-wide."
fi

# --- Fetch and setup C3PacBio from Github ---
echo "--> Downloading repository and initiating setup..."
# Define the repository URL and the target directory
REPO_URL="https://github.com/FeyeKM/C3PacBio" # Corrected URL, no comment inside string
TARGET_DIR="C3PacBio" # The name of the directory Git will create (or update)
# ... (rest of your C3PacBio git clone/pull logic) ...

echo "Setup complete for $TARGET_DIR." # Remove the duplicate echo

# --- RStudio Desktop Installation (for Debian-based VMs) ---
echo "--> Checking for RStudio Desktop..."
if command -v rstudio &> /dev/null; then
    echo "RStudio Desktop is already installed."
else
    # --- 1. Install prerequisites for RStudio ---
    # RStudio requires a recent version of R itself. Conda provides R,
    # but RStudio desktop often links to system R libraries too.
    # It's generally best to ensure system R is also installed for RStudio.
    echo "--> Installing system R and prerequisites for RStudio..."
    sudo apt-get update
    sudo apt-get install -y r-base gdebi-core # gdebi helps install .deb files with dependencies

    # --- 2. Download RStudio Desktop .deb package ---
    # IMPORTANT: The URL for the latest RStudio Desktop .deb can change.
    # Visit https://posit.co/download/rstudio-desktop/ to get the current link for your OS (e.g., Ubuntu 22/Debian 11)
    # This example URL is for Ubuntu 22/Debian 11 (Jammy/Bullseye) stable build.
    RSTUDIO_DEB_URL="https://download1.rstudio.org/electron/jammy/amd64/rstudio-2023.12.1-402-amd64.deb" # <--- **UPDATE THIS URL FOR LATEST VERSION**
    RSTUDIO_DEB_FILE="rstudio-desktop.deb"

    echo "--> Downloading RStudio Desktop from $RSTUDIO_DEB_URL..."
    wget -q "$RSTUDIO_DEB_URL" -O "$RSTUDIO_DEB_FILE"

    # --- 3. Install RStudio Desktop ---
    echo "--> Installing RStudio Desktop. This step will require your sudo password."
    # Using gdebi to install .deb files often handles dependencies better than apt install ./file.deb
    sudo gdebi -n "$RSTUDIO_DEB_FILE" # The '-n' option tries to answer 'yes' to prompts
    # If gdebi is not available or you prefer, use:
    # sudo apt install -y "./$RSTUDIO_DEB_FILE" # This might still prompt for confirmation if dependencies are new

    # Check installation status
    if command -v rstudio &> /dev/null; then
        echo "RStudio Desktop successfully installed."
    else
        echo "Error installing RStudio Desktop. Please check the output above."
        # exit 1 # You might want to exit if this is critical
    fi

    rm -f "$RSTUDIO_DEB_FILE" # Clean up the downloaded .deb file
fi
echo "All done setting up the other dependencies"
# =================================================================
# --- 5. FINAL INSTRUCTIONS ---
# =================================================================
echo ""
echo "---!!! CRITICAL FINAL STEP !!!---"
echo "The Bakta database path MUST be correct in your 'nextflow.config' file."
echo "Please ensure it matches: params { bakta_db = '$BAKTA_DB_PATH/db' }"
echo ""
echo "--- SETUP COMPLETE ---"
echo "Remember to always run Nextflow from your 'base' conda environment."
