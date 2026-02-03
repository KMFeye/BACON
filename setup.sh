#!/bin/bash
## This file is your setup file and it is autonomous.  It downloads everything needed, sets up your conda files.  It can stop and be resumed at any time.  It may take all night to set up the files, so please be prepared for that.
## To make the file executable, navigate to your desktop and put in the code: chmod -x setup.sh, then to start it, run bash setup.sh
## Ensure your directories for your program are confirmed and updated in your main.nf file

set -e # Exit immediately if any command fails.

echo "--- STARTING COMPLETE PIPELINE SETUP, Please launch this setup and come back in the morning to run the machine ---"

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
# --- KEY CHANGE: CREATE NEW CONSOLIDATED .YML FILES ---
# =================================================================
echo "--> Creating new consolidated Conda environment definition files..."
mkdir -p envs

# --- Annotation Environment (for Bakta) ---
cat << EOF > envs/annotation.yml
name: annotation_env
channels:
  - bioconda
  - conda-forge
dependencies:
  - bakta # Let conda choose the latest compatible version
EOF

# --- Resistance/Virulence Environment ---
cat << EOF > envs/resistance.yml
name: resistance_env
channels:
  - bioconda
  - conda-forge
dependencies:
  - ncbi-amrfinderplus
  - plasmidfinder
  - abricate>=1.0.1
EOF

# --- SNP and Other Analysis Environment ---
cat << EOF > envs/analysis.yml
name: analysis_env
channels:
  - bioconda
  - conda-forge
dependencies:
  - minimap2=2.24
  - samtools=1.15
  - bcftools=1.15
  - fastqc=0.11.9
  - quast=5.0.2
  - cctyper
  - multiqc=1.14
EOF

echo "--> Consolidated .yml file creation complete."


# =================================================================
# --- CONSOLIDATED DATABASE & SPECIAL ENVIRONMENT SETUP ---
# =================================================================
# --- BAKTA DATABASE (UNCHANGED) ---
if [ -d "$BAKTA_DB_PATH/db" ]; then
    echo "--> Bakta database found. Skipping download."
else
    echo "--> Bakta database not found. Installing..."
    conda create -n setup_baktadb -y -c conda-forge -c bioconda bakta
    conda activate setup_baktadb
    bakta_db download --output "$BAKTA_DB_PATH" --type full
    conda deactivate
    conda env remove -n setup_baktadb -y --prune
    echo "--> Bakta database installation complete."
fi

# --- MANUALLY PRE-BUILD THE MOB-SUITE ENVIRONMENT (UNCHANGED) ---
echo "--> Pre-building the 'mobsuite_env' due to Conda solver issues..."
if conda info --envs | grep -q "^mobsuite_env\s"; then
    echo "'mobsuite_env' already exists. Skipping creation."
else
    conda create -n mobsuite_env -y -c bioconda mob-suite
fi

echo "--> Database and special environment setup complete."

# --- FINAL INSTRUCTIONS (UNCHANGED) ---
echo ""
echo "---!!! CRITICAL FINAL STEP !!!---"
echo "The Bakta database path MUST be correct in your 'nextflow.config' file."
echo "Please ensure it matches: params { bakta_db = '$BAKTA_DB_PATH' }"
echo ""
echo "--- SETUP COMPLETE ---"
echo "Remember to always run Nextflow from your 'base' conda environment."
