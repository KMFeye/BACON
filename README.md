# C3PacBio
# A Comprehensive and Reproducible Nextflow Pipeline for Bacterial Genome Analysis using PacBio Unaligned BAM Files

This repository contains a robust, end-to-end Nextflow pipeline for the complete analysis of bacterial genomes from PacBio HiFi sequencing data. It is designed for ease of use, reproducibility, and scalability.

The workflow begins with raw, unaligned BAM files and performs host DNA decontamination, *de novo* assembly, assembly quality control, comprehensive functional annotation (including antibiotic resistance, virulence factors, plasmid typing, and CRISPR arrays), and comparative SNP analysis against a provided reference. The entire software environment is managed through Nextflow's native integration with Conda, ensuring complete reproducibility of results.

# Key Features

-   **Automated Setup:** A single `setup.sh` script installs all dependencies and downloads required databases.
-   **User-Friendly:** Interactive prompts for key parameters like genome size and coverage.
-   **High-Performance:** Optimized for parallel execution on multi-core workstations.
-   **Comprehensive Annotation:** Integrates a suite of best-in-class tools for a deep biological understanding of the assembly.
-   **Comparative Genomics:** Includes a full SNP-calling workflow for phylogenetic and outbreak analysis.
-   **Reproducibility:** All software dependencies are explicitly managed by Nextflow and Conda, guaranteeing a consistent environment.

# Installation & Setup

This pipeline is designed to be set up with a single script. This will install Miniconda (if not present), Nextflow, all required databases, and special software environments.

**1. Clone the Repository and Prepare Input Data**
Place your PacBio unaligned .bam files into the inputs/ directory.
Now you want to create your folder and move your bam files into that folder.

```bash
mkdir ./Desktop/My_Bacterial_Pipeline
cd ./Desktop/My_Bacterial_Pipeline
mkdir -p inputs
mv /path/to/your/*.bam inputs/
git clone [URL to your new GitHub repository]
cd [repository-name]
```
Your setup should match this exact layout:

~/Desktop/
+-- My_Bacterial_Pipeline/
    +-- main.nf
    +-- nextflow.config
    +-- setup.sh
    |
    +-- inputs/
    |   +-- sample_01.bam
    |   +-- sample_02.bam
    |   +-- ... (and so on)
    |
    +-- modules/
    |   +-- annotation.nf
    |   +-- bamtocleanfastq.nf
    |   +-- resistance.nf
    |   +-- ... (all other .nf files)
    |

**2. Make the Setup Script Executable**
This only needs to be done once.

```bash
chmod +x setup.sh #You can drag and drop the setup.sh file into terminal#
bash setup.sh #Runs the show#
```
# Usage
Always launch the pipeline from the base Conda environment. If you have another environment active (e.g., (mobsuite_env)), deactivate it first with conda deactivate. Setup the program where you plan to work, otherwise you'll have to
adjust your path for nextflow.  There are two modes to execute the final nextflow command (unless you use machine.sh which is a specific file for working on a VM that is available upon request). The first one will que you as to the information 
necessary to run the nextflow programs (Size of genome, species, coverage, keep to 100x if you expect to find plasmids and have a high quality annotation).  The second option is a set it and done option.  I recommend setting it and being done.

From start to finish, the setup takes about six hours and you should expect each genome to run in 1.5 to 5 hours (depending on the size).  You can adjust your nextfig.config to represent your specific setup, which you can get in terminal by writing:

```bash
lscpu
```
You can adjust your specifiC virtual or local linnux machine by going to nextflow.config and playing with the processes (high, medium, low).  This nextflow is optimized for 36 CPUS WITH 1 TB of memory on a Linus workstation.  

Interactive Mode:
The pipeline will prompt you to enter the required parameters if they are not provided on the command line.

```bash
nextflow run main.nf
```

OR

Command-Line Mode (Recommended):
Provide all parameters as flags for automated runs. This is the most reproducible method.

```bash
nextflow run main.nf --input_bam 'inputs/*.bam' --genome_size 'Size in m' --coverage 100
```

# Pipeline Steps & Tools Used
# This pipeline is composed of several key bioinformatics stages. The following tools are used and should be cited in any resulting publications

Pipeline Steps & Tools Used
This pipeline is composed of several key bioinformatics stages. The following tools are used and should be cited in any resulting publications.

1. Decontamination
Goal: Remove host (human) DNA contamination from the raw reads.

Tools:

Samtools: Converts BAM to FASTQ format for processing.

Minimap2: Aligns all reads against the human genome for filtering. Chosen for its exceptional speed with long-read data.

2. Read Subsampling
Goal: Reduce the sequencing depth to an optimal level for efficient assembly.

Tool:

Rasusa: A fast and memory-efficient tool for random subsampling of FASTQ files.

3. Assembly & Quality Control
Goal: Perform de novo assembly and assess its quality.

Tools:

Flye: A high-quality de novo assembler specifically designed for long and noisy reads.

QUAST: Generates comprehensive quality metrics for the assembly (e.g., N50, L50, number of contigs).

4. Functional Annotation
Goal: Identify genes, mobile genetic elements, and other features in the final assembly.

Tools:

Bakta: Provides comprehensive, rapid, and standardized annotation of the bacterial genome.

AMRFinderPlus: Identifies acquired antimicrobial resistance (AMR) genes using NCBI's curated database.

PlasmidFinder: Detects plasmid replicons to identify known plasmid types from assembled sequences.

MOB-suite: Characterizes plasmid mobility and reconstructs plasmid sequences from assemblies.

ABRicate: Screens contigs against multiple databases of AMR and virulence genes.

CCTyper: Identifies and types CRISPR-Cas systems within the assembly.

5. SNP Analysis
Goal: Compare each isolate to a reference genome to identify single nucleotide polymorphisms (SNPs) for phylogenetic analysis.

Tools:

Minimap2 and Samtools are used for alignment and processing.

BCFtools: Performs variant calling (identifying SNPs and indels) and filtering.

6. Reporting
Goal: Aggregate results from all tools into a single summary report.

Tool:

MultiQC: Creates a single, interactive HTML report from the logs and outputs from tools like FastQC and QUAST.

What The Citations Mean
In the text you pasted, it looks like the tool name and its citation are jumbled together. The original template was structured like this for each tool:

A line with the Tool Name and a link to its source code.

A "blockquote" (>) line containing the proper academic citation for that tool, including the authors, year, title, journal, and the DOI link.

For example:

Flye (GitHub): A high-quality de novo assembler...

Kolmogorov, M., et al. (2019). Assembly of long, error-prone reads... Nature biotechnology... DOI: 10.1038/s41587-019-0072-8
> [Your future publication details will go here!]

To ensure reproducibility, please also cite Nextflow and the individual software tools listed above.
