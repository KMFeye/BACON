#!/bin/bash

# This script sets up the complete environment for the Nextflow genomics pipelines.
# It is automated and can be safely re-run.
# Before running the program, change to your desired working directory and execute the file.  Otherwise, you'll run everything from $Home and need to set your WD for nextflow.  

echo "Remember, don't change your working directory from hereon out and make sure you add the necessary changes to Rasusa and grab the correct reference assembly and change the wget function.  If you have yet to do so, please hit control and C
at the same time, make the necessary changes as per the read me file, and then resume this setup when the tasks are complete.  A failure to do so will end in a weird subsampling experience and confusion.  No one wants that. Also, there are 
specific changes that need to be made IF you have an aligned bam vs. the unaligned (this specific pipeline) or a raw HIFI.  If you have those files, contact FeyeKM for the modified Nextflow if it hasn't already been posted as an option.  If you
do not know your species epithet nor your genome size, you'll need to pull the fastq and blast it manually on NCBI unless I already have a nextflow developed for that purpose.  But yeah, here we go!  This is a de novo alignment (the reference
is for downstream work like SNP analysis and it is the NCBI suggested reference. May the science be with you!"


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

# --- 3. CREATE ALL .YML FILES ---

echo "--> Creating consolidated Conda environment definition files..."
mkdir -p envs

# Use a simpler text block format (cat << EOF) which is easier to read and edit.
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

cat << EOF > envs/annotation.yml
name: annotation_env
channels: [bioconda, conda-forge]
dependencies: [bakta]
EOF

cat << EOF > envs/resistance.yml
name: resistance_env
channels: [bioconda, conda-forge]
dependencies:
  - ncbi-amrfinderplus
  - plasmidfinder
  - abricate>=1.0.1
EOF

cat << EOF > envs/other_analysis.yml
name: other_analysis_env
channels: [bioconda, conda-forge]
dependencies:
  - cctyper
EOF

echo "--> .yml file creation complete."

# --- 4. DATABASE AND SPECIAL ENVIRONMENT SETUP ---
   echo "Setting up Bakta and the other databases!"
   
# --- BAKTA DATABASE ---
if [ -d "$BAKTA_DB_PATH/db" ]; then
    echo "--> Bakta database found. Skipping download."
else
    echo "--> Bakta database not found. Installing..."
    # Create a temporary environment just for the download command
    echo "--> Creating temporary environment to run bakta_db..."
    conda create -n setup_baktadb -y -c conda-forge -c bioconda bakta
    
    # Activate the environment to make the command available
    conda activate setup_baktadb
    
    # Run the download command
    echo "--> Running 'bakta_db download'..."
    bakta_db download --output "$BAKTA_DB_PATH" --type full
    
    # Deactivate and clean up the temporary environment
    conda deactivate
    conda env remove -n setup_baktadb -y
    
    echo "--> Bakta database installation complete."
fi

# --- MANUALLY PRE-BUILD THE MOB-SUITE ENVIRONMENT (CRITICAL FIX) ---
echo "--> Pre-building the 'mobsuite_env' due to Conda solver issues..."
if conda info --envs | grep -q "^mobsuite_env\s"; then
    echo "'mobsuite_env' already exists. Skipping creation."
else
    conda create -n mobsuite_env  -y
    conda activate mobsuite_env
    conda install -c bioconda mob_suite -y
    conda deactivate
fi


echo "--> Database and special environment setup complete."

# --- 5. FINAL INSTRUCTIONS ---
echo ""
echo "---!!! CRITICAL FINAL STEP !!!---"
echo "The Bakta database path MUST be correct in your 'nextflow.config' file. If you did what I told you, you should be fine"
echo "Please ensure it matches: params { bakta_db = '$BAKTA_DB_PATH' }"
echo ""
echo "--- SETUP COMPLETE ---CONTACT FeyeKM if you have challenges, happy data hunting!!"
echo "Remember to always run Nextflow from your 'base' conda environment."
