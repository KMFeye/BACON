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
# This section is perfect as is.
echo "--> Checking for Miniconda..."
if [ -d "$HOME/miniconda3" ]; then
    echo "Miniconda is already installed."
else
    # ... (rest of miniconda installation)
fi

echo "--> Initializing Conda for this script session..."
source "$HOME/miniconda3/etc/profile.d/conda.sh"
# ... (rest of conda initialization)

# --- NEXTFLOW & JAVA INSTALLATION ---
# This section is perfect as is.
echo "--> Installing/Verifying Java (OpenJDK 17) in base environment..."
# ... (rest of java/nextflow installation)

# =================================================================
# --- 3. CREATE ALL .YML FILES (FINAL CORRECTED VERSION) ---
# =================================================================
echo "--> Creating individual and robust Conda environment definition files..."
mkdir -p envs

# Use a simpler text block format (cat << EOF)
# This creates a separate, simple environment file for each process,
# which is the most robust strategy for your system.

cat << EOF > envs/qaqcClean.yml
name: qaqcClean
channels: [bioconda]
dependencies: [fastqc=0.11.9]
EOF

cat << EOF > envs/flyeAssembly.yml
name: flyeAssembly
channels: [bioconda]
dependencies: [flye=2.9.1]
EOF

cat << EOF > envs/quastReport.yml
name: quastReport
channels: [bioconda]
dependencies: [quast=5.0.2]
EOF

cat << EOF > envs/multiqc.yml
name: multiqc
channels: [bioconda, conda-forge]
dependencies: [multiqc=1.14]
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
# This section is perfect as is. It correctly handles the Bakta database
# and pre-builds the special mobsuite_env.

# --- BAKTA DATABASE ---
if [ -d "$BAKTA_DB_PATH/db" ]; then
    echo "--> Bakta database found. Skipping download."
else
    # ... (full, correct Bakta download logic) ...
fi

# --- MANUALLY PRE-BUILD THE MOB-SUITE ENVIRONMENT ---
echo "--> Pre-building the 'mobsuite_env' due to Conda solver issues..."
if conda info --envs | grep -q "^mobsuite_env\s"; then
    echo "'mobsuite_env' already exists. Skipping creation."
else
    # ... (full, correct mob-suite creation logic) ...
fi

echo "--> Database and special environment setup complete."

# =================================================================
# --- 5. FINAL INSTRUCTIONS ---
# =================================================================
# This section is perfect as is.
# ...
