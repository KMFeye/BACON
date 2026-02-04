# C3PacBio
# A Comprehensive and Reproducible Nextflow Pipeline for Bacterial Genome Analysis using PacBio Unaligned BAM Files

This repository contains a robust, end-to-end Nextflow pipeline for the complete analysis of bacterial genomes from PacBio HiFi sequencing data. It is designed for ease of use, reproducibility, and scalability.

The workflow begins with raw, unaligned BAM files and performs host DNA decontamination, *de novo* assembly, assembly quality control, comprehensive functional annotation (including antibiotic resistance, virulence factors, plasmid typing, and CRISPR arrays), and comparative SNP analysis against a provided reference. The entire software environment is managed through Nextflow's native integration with Conda, ensuring complete reproducibility of results.

## Key Features

-   **Automated Setup:** A single `setup.sh` script installs all dependencies and downloads required databases.
-   **User-Friendly:** Interactive prompts for key parameters like genome size and coverage.
-   **High-Performance:** Optimized for parallel execution on multi-core workstations.
-   **Comprehensive Annotation:** Integrates a suite of best-in-class tools for a deep biological understanding of the assembly.
-   **Comparative Genomics:** Includes a full SNP-calling workflow for phylogenetic and outbreak analysis.
-   **Reproducibility:** All software dependencies are explicitly managed by Nextflow and Conda, guaranteeing a consistent environment.

## Installation & Setup

This pipeline is designed to be set up with a single script. This will install Miniconda (if not present), Nextflow, all required databases, and special software environments.

**1. Clone the Repository**
```bash
git clone [URL to your new GitHub repository]
cd [repository-name]
'''

2. Make the Setup Script Executable
This only needs to be done once.

'''bash
chmod +x setup.sh
bash setup.sh
'''

3. Run the Setup Script
This is the main installation step. It is idempotent, meaning it can be safely re-run if it fails. Note: The initial download of the Bakta database is very large and may take a significant amount of time. It is recommended to run this step overnight.

'''bash
bash setup.sh
4. Prepare Input Data
Place your PacBio unaligned .bam files into the inputs/ directory.
'''

Now you want to create your folder and move your bam files into that folder

'''bash
mkdir -p inputs
mv /path/to/your/*.bam inputs/
,,,

Usage
Always launch the pipeline from the base Conda environment. If you have another environment active (e.g., (mobsuite_env)), deactivate it first with conda deactivate.

Interactive Mode:
The pipeline will prompt you to enter the required parameters if they are not provided on the command line.

'''bash
nextflow run main.nf
'''

# OR
# Command-Line Mode (Recommended):
Provide all parameters as flags for automated runs. This is the most reproducible method.

'''bash
nextflow run main.nf --input_bam 'inputs/*.bam' --genome_size 'Size in m' --coverage 100
'''

#Pipeline Steps & Tools Used
#This pipeline is composed of several key bioinformatics stages. The following tools are used and should be cited in any resulting publications.

#1. Decontamination
Goal: Remove host (human) DNA contamination from the raw reads.

Tools:

Samtools (GitHub): Converts BAM to FASTQ format for processing.

Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. GigaScience, 10(2), giab008. DOI: 10.1093/gigascience/giab008

Minimap2 (GitHub): Aligns all reads against the human genome for filtering. Chosen for its exceptional speed with long-read data.

Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. Bioinformatics, 34(18), 3094-3100. DOI: 10.1093/bioinformatics/bty191

#2. Read Subsampling
Goal: Reduce the sequencing depth to an optimal level for efficient assembly.

Tool:

Rasusa (GitHub): A fast and memory-efficient tool for random subsampling of FASTQ files.

Hall, M. B. (2022). Rasusa: A fast tool for random subsampling of reads. Journal of Open Source Software, 7(72), 4034. DOI: 10.21105/joss.04034

#3. Assembly & Quality Control
Goal: Perform de novo assembly and assess its quality.

Tools:

Flye (GitHub): A high-quality de novo assembler specifically designed for long and noisy reads.

Kolmogorov, M., et al. (2019). Assembly of long, error-prone reads using repeat graphs. Nature biotechnology, 37(5), 540-546. DOI: 10.1038/s41587-019-0072-8

QUAST (GitHub): Generates comprehensive quality metrics for the assembly (e.g., N50, L50, number of contigs).

Gurevich, A., et al. (2013). QUAST: quality assessment tool for genome assemblies. Bioinformatics, 29(8), 1072-1075. DOI: 10.1093/bioinformatics/btt086

#4. Functional Annotation
Goal: Identify genes, mobile genetic elements, and other features in the final assembly.

Tools:

Bakta (GitHub): Provides comprehensive, rapid, and standardized annotation of bacterial genomes.

Schwengers, O., et al. (2021). Bakta: rapid and standardized annotation of bacterial genomes. Microbial Genomics, 7(11), 000685. DOI: 10.1099/mgen.0.000685

AMRFinderPlus (NCBI): Identifies acquired antimicrobial resistance (AMR) genes using NCBI's curated database.

Feldgarden, M., et al. (2019). Validating the AMRFinderPlus algorithm and database for use in prediction of antimicrobial resistance genotypes from DNA sequence data. Antimicrobial agents and chemotherapy, 63(11). DOI: 10.1128/AAC.00483-19

PlasmidFinder (CGE): Detects plasmid replicons to identify known plasmid types from assembled sequences.

Carattoli, A., et al. (2014). In silico detection and typing of plasmids using PlasmidFinder and pMLST. Antimicrobial agents and chemotherapy, 58(7), 3895-3903. DOI: 10.1128/AAC.02412-14

MOB-suite (GitHub): Characterizes plasmid mobility (e.g., conjugative, mobilizable) and reconstructs plasmid sequences from assemblies.

Robertson, J., & Nash, J. H. (2018). MOB-suite: software tools for clustering, reconstruction and typing of plasmids from draft assemblies. Microbial genomics, 4(8). DOI: 10.1099/mgen.0.000206

ABRicate (GitHub): Screens contigs against multiple databases of AMR and virulence genes (e.g., CARD, VFDB).

Seemann, T. (2018). ABRicate: mass screening of contigs for antimicrobial resistance and virulence genes. GitHub repository.

CCTyper (GitHub): Identifies and types CRISPR-Cas systems within the assembly.

Almendros, C., et al. (2022). CCTyper: a bioinformatic pipeline for computational typing of CRISPR-Cas systems. The CRISPR Journal, 5(1), 145-149. DOI: 10.1089/crispr.2021.0042

#5. SNP Analysis
Goal: Compare each isolate to a reference genome to identify single nucleotide polymorphisms (SNPs) for phylogenetic analysis.

Tools:

Minimap2 and Samtools are used for alignment and processing.

BCFtools (GitHub): Performs variant calling (identifying SNPs and indels) and filtering.

Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. GigaScience, 10(2), giab008. DOI: 10.1093/gigascience/giab008

#6. Reporting
Goal: Aggregate results from all tools into a single summary report.

Tool:

MultiQC (GitHub, multiqc.info): Creates a single, interactive HTML report from the logs and outputs of tools like FastQC and QUAST.

Ewels, P., et al. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19), 3047-3048. DOI: 10.1093/bioinformatics/btw354

How to Cite This Workflow
If you use this pipeline in your research, please cite this repository and our future publication:

> [Your future publication details will go here!]

To ensure reproducibility, please also cite Nextflow and the individual software tools listed above.
