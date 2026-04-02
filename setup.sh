#!/bin/bash
# This script provides a complete, idempotent setup for the Nextflow genomics pipeline environment.
# It can install user-level tools (Conda, databases) and optionally system-level tools (Chrome).
# It is designed to be safely re-run multiple times.

# Exit immediately if any command fails, ensuring the script doesn't continue in a broken state.
set -e

# ====================================================================================
# --- 1. CONFIGURATION ---
# All user-configurable variables are placed here for easy access and modification.
# ====================================================================================

# --- Master Switch for System Tools ---
# Set this to "true" to run the sections that require sudo (e.g., Chrome installation).
# Set to "false" if you do not have passwordless sudo access.
INSTALL_SYSTEM_TOOLS="true"

# --- Software Versions ---
# Specify the Java version to be installed in the base Conda environment.
JAVA_VERSION="21"

# --- Directory Paths ---
# Use the robust $HOME variable to build paths from the user's home directory.
DB_BASE_PATH="$HOME/databases"
BAKTA_DB_PATH="$DB_BASE_PATH/bakta_db"
PLATON_DB_PATH="$DB_BASE_PATH/pdb"
KRAKEN2_DB_PATH="$DB_BASE_PATH/kraken2db"
C3PACBIO_TARGET_DIR="C3PacBio"

# --- Download URLs ---
# !!! IMPORTANT: These URLs can change. Verify them before running if you encounter download errors. !!!
PLATON_DB_URL="https://zenodo.org/record/3949439/files/db.tar.gz"
KRAKEN2_DB_URL="https://genome-idx.s3.amazonaws.com/kraken/k2_pluspfp_08gb_20240112.tar.gz" # 8GB PlusPFP DB
C3PACBIO_REPO_URL="https://github.com/FeyeKM/C3PacBio"


# ====================================================================================
# --- 2. HELPER FUNCTIONS ---
# Small, reusable functions that keep our code clean and maintainable (DRY principle).
# ====================================================================================

# A custom logging function to provide consistent, readable output.
log_step() {
    echo "--> $1"
}

# A safe way to create a directory that doesn't fail if the directory already exists.
ensure_dir() {
    mkdir -p "$1"
}

# A reliable way to check if a command is available in the system's PATH.
command_exists() {
    command -v "$1" &> /dev/null
}

# A helper to check if a specific Conda environment exists.
conda_env_exists() {
    # Source conda functions if they aren't loaded yet.
    if ! command_exists conda; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi
    conda info --envs | grep -q "^$1\s"
}

# ====================================================================================
# --- 3. MAIN SETUP FUNCTIONS ---
# Each major task is encapsulated in its own function for clarity and organization.
# ====================================================================================

setup_workspace() {
    log_step "Setting up workspace directories and blank metadata file..."
    local required_dirs=("raw_data" "cleaned_data" "reports" "logs" "final_results/figures")
    local metadata_file="sample_sheet.tsv"

    for dir in "${required_dirs[@]}"; do
        ensure_dir "$dir"
        log_step "  - Ensured '$dir/' exists."
    done

    if [ -f "$metadata_file" ]; then
        log_step "Blank metadata file '$metadata_file' already exists."
    else
        log_step "Creating blank metadata file: '$metadata_file'..."
        touch "$metadata_file"
    fi
}

setup_system_tools() {
    log_step "Setting up System-Wide Tools (Google Chrome)..."
    if command_exists google-chrome; then
        log_step "Google Chrome is already installed. Skipping."
    else
        log_step "Installing Google Chrome. This requires passwordless sudo."
        local CHROME_DEB_FILE="google-chrome-stable_current_amd64.deb"
        sudo apt update && sudo apt upgrade -y
        wget -O "$CHROME_DEB_FILE" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
        sudo apt install -y "./$CHROME_DEB_FILE"
        sudo apt install -f -y # Fix any broken dependencies
        rm "$CHROME_DEB_FILE"  # Clean up the installer
    fi
}

setup_core_dependencies() {
    log_step "Setting up Core Dependencies (Conda & Java)..."
    if [ -d "$HOME/miniconda3" ]; then log_step "Miniconda is already installed."; else
        log_step "Miniconda not found. Downloading and installing..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
        bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
        rm /tmp/miniconda.sh
    fi
    source "$HOME/miniconda3/etc/profile.d/conda.sh"; conda init bash; export PATH="$HOME/miniconda3/bin:$PATH"
    conda config --add channels bioconda --force; conda config --add channels conda-forge --force; conda config --set channel_priority flexible
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
    log_step "Installing Java (OpenJDK $JAVA_VERSION) in base environment..."
    conda install -n base -y -c conda-forge "openjdk=$JAVA_VERSION"
}

setup_nextflow() {
    log_step "Setting up Nextflow..."
    if command_exists nextflow; then log_step "Nextflow is already installed."; else
        log_step "Nextflow not found. Installing locally in $HOME/bin..."
        ensure_dir "$HOME/bin"; curl -s https://get.nextflow.io | bash; mv nextflow "$HOME/bin"
        local PATH_LINE='export PATH="$HOME/bin:$PATH"'; touch ~/.bashrc
        if ! grep -qF "$PATH_LINE" ~/.bashrc; then
            echo '' >> ~/.bashrc; echo '# Add local bin to PATH for Nextflow' >> ~/.bashrc; echo "$PATH_LINE" >> ~/.bashrc
        fi
        export PATH="$HOME/bin:$PATH"
    fi
}

setup_bakta_database() {
    log_step "Setting up Bakta Database..."
    ensure_dir "$BAKTA_DB_PATH"
    if [ -d "$BAKTA_DB_PATH/db" ]; then log_step "Bakta database found. Skipping."; else
        log_step "Bakta database not found. Installing via temporary Conda env..."
        conda create -n setup_baktadb -y -c conda-forge -c bioconda bakta
        conda run -n setup_baktadb bakta_db download --output "$BAKTA_DB_PATH" --type full
        conda env remove -n setup_baktadb -y
    fi
}

setup_platon_database() {
    log_step "Setting up Platon Database..."
    ensure_dir "$PLATON_DB_PATH"
    if [ -f "$PLATON_DB_PATH/plasmid_sequences.fasta" ]; then log_step "Platon database found. Skipping."; else
        log_step "Platon database not found. Downloading and extracting..."
        local DB_FILE="platon_db.tar.gz"
        wget -O "$PLATON_DB_PATH/$DB_FILE" "$PLATON_DB_URL"
        tar -xzvf "$PLATON_DB_PATH/$DB_FILE" -C "$PLATON_DB_PATH/"
        rm "$PLATON_DB_PATH/$DB_FILE"
    fi
}

setup_kraken2_database() {
    log_step "Setting up Kraken2 Database..."
    ensure_dir "$KRAKEN2_DB_PATH"
    if [ -f "$KRAKEN2_DB_PATH/database.idx" ]; then log_step "Kraken2 database found. Skipping."; else
        log_step "Kraken2 database not found. Downloading and extracting..."
        local DB_FILE="kraken2_db.tar.gz"
        wget -O "$KRAKEN2_DB_PATH/$DB_FILE" "$KRAKEN2_DB_URL"
        tar -xzvf "$KRAKEN2_DB_PATH/$DB_FILE" -C "$KRAKEN2_DB_PATH/"
        rm "$KRAKEN2_DB_PATH/$DB_FILE"
    fi
}

setup_special_envs() {
    log_step "Pre-building the 'mobsuite_env'..."
    if conda_env_exists "mobsuite_env"; then log_step "'mobsuite_env
