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
# --- 3. CREATE ALL .YML FILES (FINAL ROBUST VERSION) ---
# =================================================================
echo "--> Creating individual and robust Conda environment definition files..."
mkdir -p envs

# This function is removed as we use cat << EOF for clarity.
# Using individual .yml files is the most robust way to avoid Conda solver timeouts.

cat << EOF > envs/qaqcClean.yml
name: qaqcClean
channels: [bioconda]
dependencies: [fastqc=0.11.9]
EOF

cat << EOF > envs/flyeAssembly.yml
name: flyeAssembly
channels: [bioconda, conda-forge]
dependencies:
  - flye=2.9.1
  - python=3.9
EOF

cat << EOF > envs/quastReport.yml
name: quastReport
channels: [bioconda]
dependencies: [quast=5.0.2]
EOF

cat << EOF > envs/multiqc.yml
name: multiqc
channels: [bioconda, conda-forge]
dependencies:
  - multiqc=1.14
  - python=3.9
EOF

cat << EOF > envs/snpAnalysis.yml
name: snpAnalysis
channels: [bioconda, conda-forge]
dependencies: [minimap2=2.24, samtools=1.15, bcftools=1.15]
EOF

# --- Individual Annotation Environment Files ---

cat << EOF > envs/bakta.yml
name: bakta_env
channels: [bioconda, conda-forge]
dependencies:
  - bakta
  - python=3.9
EOF

cat << EOF > envs/amrfinder.yml
name: amrfinder_env
channels: [bioconda, conda-forge]
dependencies:
  - ncbi-amrfinderplus
EOF

cat << EOF > envs/plasmidfinder.yml
name: plasmidfinder_env
channels: [bioconda, conda-forge]
dependencies:
  - plasmidfinder
  - git
  - kma
EOF

cat << EOF > envs/abricate.yml
name: abricate_env
channels: [bioconda, conda-forge]
dependencies:
  - abricate>=1.0.1
EOF

cat << EOF > envs/cctyper.yml
name: cctyper_env
channels: [bioconda, conda-forge]
dependencies:
  - cctyper
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

# --- 5. FINAL INSTRUCTIONS ---
echo ""
echo "---!!! CRITICAL FINAL STEP !!!---"
echo "The Bakta database path MUST be correct in your 'nextflow.config' file."
echo "Please ensure it matches: params { bakta_db = '$BAKTA_DB_PATH/db' }"
echo ""
echo "--- SETUP COMPLETE ---"
echo "Remember to always run Nextflow from your 'base' conda environment."
