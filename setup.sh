#!/bin/bash

# This script sets up the complete environment for the Nextflow genomics pipelines.
# It is automated and can be safely re-run.
# Execute said script by first: chmod -x setup.sh and then; bash setup.sh

set -e # Exit immediately if any command fails.

echo "--- STARTING COMPLETE PIPELINE SETUP ---"

# --- 1. DEFINE CENTRAL DATABASE LOCATION ---
echo "Defining DB location for Bakta"
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

# --- 3. CREATE ALL .YML FILES ---
echo "--> Creating Conda environment definition files in envs/ directory so this works..."
mkdir -p envs

write_env_file() {
    local filename=$1
    local content=$2
    if [ ! -f "envs/${filename}" ]; then
        echo "Creating envs/${filename}..."
        echo -e "${content}" > "envs/${filename}"
    fi
}

# --- UNCHANGED .YML FILES FOR OTHER PROCESSES ---
write_env_file "qaqcClean.yml" "name: qaqcClean\nchannels: [bioconda]\ndependencies: [fastqc=0.11.9]"
write_env_file "flyeAssembly.yml" "name: flyeAssembly\nchannels: [bioconda]\ndependencies: [flye=2.9.1]"
write_env_file "quastReport.yml" "name: quastReport\nchannels: [bioconda]\ndependencies: [quast=5.0.2]"
write_env_file "multiqc.yml" "name: multiqc\nchannels: [bioconda, conda-forge]\ndependencies: [multiqc=1.14]"
write_env_file "snpAnalysis.yml" "name: snpAnalysis\nchannels: [bioconda, conda-forge]\ndependencies: [minimap2=2.24, samtools=1.15, bcftools=1.15]"

# --- KEY CHANGE: RESTRUCTURED ANNOTATION ENVIRONMENTS ---

# 1. New file for Bakta's environment
write_env_file "annotation.yml" "name: annotation_env\nchannels: [bioconda, conda-forge]\ndependencies: [bakta]"

# 2. New file for the resistance/virulence tools
write_env_file "resistance.yml" "name: resistance_env\nchannels: [bioconda, conda-forge]\ndependencies:\n  - ncbi-amrfinderplus\n  - plasmidfinder\n  - abricate>=1.0.1"

# 3. New file for the "other" analysis tools (only CCTyper in this case)
# You can add other tools here in the future if needed.
write_env_file "other_analysis.yml" "name: other_analysis_env\nchannels: [bioconda, conda-forge]\ndependencies:\n  - cctyper"

# NOTE: The individual files like 'amrfinder.yml', 'abricate.yml', etc., are no longer created
# as they have been consolidated into the files above.

echo "--> .yml file creation complete."

# --- DATABASE AND SPECIAL ENVIRONMENT SETUP --
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
echo "Remember to always run Nextflow from your 'base' conda environment. Happy data analyses!"
