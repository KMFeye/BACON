# C3PacBio
# A Comprehensive and Reproducible Nextflow Pipeline for Bacterial Genome Analysis using PacBio Unaligned BAM Files

Welcome!  Are you new to PacBio and struggle to manage massive data files? Do graphical user interfaces (GUI) websites lead to additional challenges due to the sheer size of PacBio files?  Do you want more opportunities to personalize your workflow with program settings that interest you?  Do you love automated figure generation but still want to pick the colors and tailor the output to your target journal?  

Hello!  In walks C3PacBio, a Nextflow pipeline developed to make massive files easier to manage and provide common analyses for Microbial Genomics in an ecosystem that hates big files.  

Of note, the views expressed on this GitHub are personal and do not reflect any other viewpoints or endorsements of any organization or entity.  

So, let's get to it!

# Key Features

 - Automated Setup: A single setup.sh script installs all dependencies and downloads    
   required databases. 
 - User-Friendly: Interactive prompts for key parameters like genome size and coverage.
 - High-Performance: Optimized for parallel execution on multi-core workstations.
 - Comprehensive Annotation: Integrates a suite of best-in-class tools for a deep  
    biological understanding of the sample or sample. 
- Can process 1 to 100 samples without modifications to the pipeli
 - If applicable, pangenomics and GWAS analyses are performe
    genomic analysis.
 - Reproducibility: All software dependencies are explicitly managed by Nextflow and    
   Conda, guaranteeing a consistent environment.

# Downloading and Installing C3PacBio with Dependencies

The program titled shell.sh in the list of files at the top of this page does the following tasks: 

 1. Installs Nextflow
    	Why: Well, how else should it run? :)
 3. Installs and Updates Javascript
        Why: Nextflow needs this
 5. Installs Conda
        Why: Because Docker can be confusing for folks, so conda is managing everything
 7. Installs R
    	Why: C3PacBio uses R for some of the work
 9. Installs R Studio
     	Why: Easy user interface!!  If modifications to the files are needed, R Studio is much friendlier
 11. Installs GitHub Dependencies
     	Why: So you can get this repository and run the program!
 14. Installs the databases and unpacks them
     	Why: So the programs can run, make sure the paths in the setup file and the nextflow.config file match.  
 16. Makes everything executable (aka you can run the program).
     	Why: We want the program to work. 

Once the setup.sh file sets up, close the terminal and reopen it.  Navigate to your desired working directory and go.
### A fair warning, if the computer is used for multiple programs, there should not be any redundency (aka the programs won't download multiple times).  But, the available memory available on your system to use this program may be reduced. This program works best on a fresh instance (virtual machine) or a scientific workstation dedicated to data analysis that has the full memory of the system avaialble to the Nextflow.  If multiple users have access to a computer, each user is usually given a piece of the memory pie.  So, check your free RAM and memory with the following command and adjust accordingly;
```
vmstat 1 2
```

# Setup the Setup file

From start to finish, on a naive (or uninstalled) system, it takes about 1 to 2 hours if there is a good internet connection.   

So how do you use the setup file (setup.sh) file?  First, you need to make sure your system has some very basic requirements satisfied prior to installing C3PacBio.  

## Program requirements are as follows:

 1. You are using an Apple Desktop or a Linux Workstation OR a cloud using a Linux operating system.  This program will not work on Windows as the computing languages used to run this program are not the same. If you need to initiate the bash language in terminal (Apple) ahead of the installation program's execution (setup.sh), the command should just be:
    ```bash```
    This should not be necessary for Linux.
 3. You have enough memory to run this program.  Most standard computing systems (Apple Desktop, Linux Workstations) have this covered as of February 2026.  But, if you use the computer for other tasks, you'll want to make sure there is enough harddrive present to analyze the massive files.  If you are using the SRA download option, the burdeon isn't as massive.  But, if you are using HiFi BAM files, you are looking at between 50 and 100 GB per file.  Your output will not come close to that (about 5 GB per file) but if you expect it to run, you need to have hard drive (at least 500 GB if you have 3 files to run (HiFi BAM)), 16 to 32 GB of memory, and 500 GB of RAM.  
 4. The setup.sh scans your system and ensures you have the necessary programs to give you complete control of your system.  Conda was chosen as it is a lot easier to manage for people new to this kind of analysis and in ecosystems where data security is scrutinized, is easier.  The file that downloads works with Linux, it does not work with Apple.  That file download will need to change.
 5. Once your setup.sh is executed, Nextflow will operate in the folder where the file is initiated.  If you don't like that, set your path. 

So, how does this work?  What do I do? 

Follow these steps precisely: 

 1. Download shell.sh or copy and paste it and save it in a text file as "shell.sh" **in the working directory you intend to work**.  If you save it as shell.txt, you will have problems. If you mess around with your working directories, you'll be unhappy. 
 2. Make the shell program executable with the following command:
    ```chmod -x shell.sh```
 3. Execute the command. 
     ```bash shell.sh ```

**IMPORTANT:** The install system is fully automated and assumes that you accept the terms and conditions of every program that is downloading.  If you do not accept the terms and conditions, you cannot use the programs.  That is a you problem, not a me problem.  So, make your choices as you make them, ensure you're following company policies with data security, and relax.  You will see a lot of stuff tick across the screen as the shell program executes.  This is normal.  So, go get some coffee, have a couple of meetings, and come back in 2 to 4 hours and be ready to work.  If an error shows up, please let me know in the QA section of this GitHub page and I'll figure something out. 


# Setup the Nextflow Program 

Make sure the directory (or file) you want to have your files created in and deposited into is the file termed as your "working directory".  Make sure your project directory is in the paths identified in the files.  The big issue is that Nextflow only puts things where it puts them based on the program that is already written.  So, if the outputs (in the nextflow.config) do not match your file path, nextflow may get confused and crash. 

The directories (files) should be ordered as follows: 

Desktop (already exists, don't add this directory the rest should be part of the repository)
-Project
--main.nf
--nextflow.config
--envs (this is where your conda environments will be housed)
--modules (this is where your modules are located that you can adjust if need be)
--asset

You will want to navigate to that directory and execute exactly this code (again assuming it is on the desktop)
```
   cd ./Desktop/Project
   mkdir inputs
  ```
  
Now, take your unaligned bam files and drop them into the inputs folder.  Do not change the names of the folders.  I know inputs seems silly but here we are. 

## Public Repository Data Mining/Scraping
Most files you get from NCBI are going to be fastq.  So, the shell file in the folder named 'getsra.sh' is geared towards doing just that.  C3PacBio will not process straight fastq files so instead that program will convert the fastq to an unaligned bam file after downloading it.  I have noticed that occasionally if the files are large that the files time out.  Get an idea of the size of the files from NCBI prior to downloading them with the sh file and if the files are not appropriately sized, redownload them one by one or manually (see the documentation inside the shell file).  

Also, don't assume the files from public repositories are well executed by the depositor.  You can read more about that here: https://pubmed.ncbi.nlm.nih.gov/32398145/

Now, you have other options besides your files from your sequencing run, mainly harvesting data from public repositories.  The example for the publication uses SRA from NCBI, but others exist.  First, if you want to mass download SRA files that result from PacBio Sequencing, please navigate to the directory at the top of the page titled "Code for Paper" and find the file labeled "GettingData" and follow the directions to get that done.   It is well annotated and allows you to also check the quality of your freshly harvested sequences. 

# Prepping for your run by modifying your Nextflow files to fit your needs

You need to get the link to download the GFF3 file and the FNA file for the reference data you will be using.  This is a *de novo* alignment.  However, for SNP analyses, you require a reference file.  You will also need to know the following information:

 1. How big is your intended genome?
 2. What do you like for sequencing depth?
 3. How powerful is your computer system?
 4. What is your desired GO analysis?
 5. Does Panther use your bacterial species or should you identify a reference species?
 6. What is your .fna.gz reference file for the SNP analyses?
 7. WHat is your strain identifier (4 digit number to ID your strain)

A note on sequencing depth.  More is not better in the world of sequencing depth when it comes to bacterial genomics.  At a certain point, and with PacBio that can vary, increased depth decreases assembly quality and the likelihood of recovering plasmids.  The default is 100x and we subsample with Rasusa.  This gives a pretty high quality assembly and is documented to do just that (plus plasmids need our love too!).    So, do what makes you happy, but having 700x or 900x depth is not ideal in this instance.   Also, go through the programs.  If you'd like to increase some of the program commands, do so.  But, first train yourself using the data from the publication so you know the program runs.  If you change everything around before validating that the program runs, life is harder to troubleshoot. 

For your computer system, run the following command:
```
lscpu  ## This tells you how many CPUs and cores you have onboard ##
free -h ## This tells you your available memory, used, and total ##
```
Now, this is important.  Your number one failure point will be memory.  In your nextflow.config file, you have code that looks like this:

```

executor {
    name = 'local'
    cpus = 36
    memory = '256GB'
}

process {
    cpus = 4
    memory = '8GB'
    time = '6h'

    withLabel: 'process_low' {
        cpus = 2
        memory = '4GB'
        time = '1h'
    }
    withLabel: 'process_medium' {
        cpus = 8
        memory = '32GB'
        time = '8h'
    }
    withLabel: 'process_high' {
        cpus = 12
        memory = '120GB'
        time = '48h'
    }
}
```
This file is optimized to run 3 large files with 12 CPUS each and consume 80 GB of memory on the high process.   You can always increase the memory and you can play with the CPUs to make it work better. 

You will also need to deposit your reference sequence in the nextflow.config file.

there are other modifications that must be made prior to starting across two separate files.  I have placeholders flanked by '###' that you need to modify.  Be sure to delete the '###' prior to starting the run.

```
params {
    input_bam             = 'inputs/*.bam'
    bakta_db              = "/home/dnanexus/databases/bakta_db/db"
    platon_db             = "/home/dnanexus/databases/pdb/db"
    kraken2_db_path       = "/home/dnanexus/databases/kraken_db"
    outdir                = "${projectDir}/results"
    genome_size           = ## '4.2m' ##
    coverage              = 100 
    target_taxid          = ## '1423' ##
    traits_file           = "${projectDir}/metadata.csv"
    tree_color_column     = 'sequence_type'
    panther_organism      = ##'BACILLUS_SUBTILIS' ##
    panther_annot_dataset = ## 'GO:0008150' ##
    rbioapi_organism_id   = ## 1423 ##
    rbioapi_annot_dataset = ## 'GO:0008150' ##
}
```

Additionally, go to IndexClean.nf and go to this process and modify it with your fna.gz link for your organism's reference genome that you can find on NCBI.

```
process DOWNLOAD_BACTERIAL_REFERENCE {
    tag "Downloading Bacterial Reference"
    label 'process_low'
    conda 'conda-forge::wget=1.21.4'
    output: path("bacterial_ref.fasta"), emit: fasta
    script:
    """
    wget --no-check-certificate -O bacterial_ref.fasta.gz ###"https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/045/GCF_000009045.1_ASM904v1/GCF_000009045.1_ASM904v1_genomic.fna.gz" ###
    gunzip bacterial_ref.fasta.gz
    """
}
```


# Running Nextflow

After you've checked your file paths, added the necessary information (and replaced the placeholders I have and deated the # symbols where I signal you to add in your information), you should be good to go. This command will execute the nextflow and let you know how your run went:

```
$nextflow run main.nf -with-report report.html -with-timeline timeline.html -with-trace trace.txt 
```

You will see this...
```
 N E X T F L O W   ~  version 25.10.4

Launching `main.nf` [shrivelled_williams] DSL2 - revision: eae8d1587e

executor >  local (6)
[89/4d79ed] DOWNLOAD_HUMAN_GENOME          | 1 of 1 
[a8/63d72f] DOWNLOAD_BACTERIAL_REFERENCE   | 1 of 1
[1e/ea6e0a] INDEX_BACTERIAL_GENOME         | 1 of 1 
[df/e7229f] BAM\u2026AM to FASTQ for SR3324231) | 1 of 1 
[76/d4e5ef] MIN\u2026g SR3324231 with minimap2) | 1 of 1 
[5b/99e0b4] SUB\u2026ing SR3324231 with Rasusa) | 0 of 1
[-        ] CLEAN_QAQC                     -
[-        ] FLYE_ASSEMBLY                  -
[-        ] QUAST_REPORT                   -
[-        ] BAKTA_ANNOTATION               -
[-        ] AMRFINDER_ANALYSIS             -
[-        ] PLASMIDFINDER_ANALYSIS         -
[-        ] MOB_SUITE_ANALYSIS             -
[-        ] RUN_ABRICATE                   -
[-        ] CRISPR_TYPING                  -
[-        ] BOSCO                          -
[-        ] ALIGN_TO_REFERENCE             -
[-        ] CALL_VARIANTS_BCFTOOLS         -
[-        ] FILTER_VARIANTS_BCFTOOLS       -
[-        ] SUMMARIZE_RESULTS              -
[-        ] MULTIQC                        -
[-        ] GENERATE_FINAL_REPORT          -
```
As the process runs, the 0% will become 100%.  You should see a working directory (work) and a results folder generate, as well as a summarize folder and a folder PER sequence you're analyzing.  At any time, you can run the following command to make sure the programs are running in a new terminal window.  If you see randomness as an output, the first thing you should do is: 

1) Check your file paths
2) Check your working directory
3) Check your downloads (fna file)
4) Make sure your inputs are unaligned bam files

If anything else happens, message me. 

To verify your work is successful, run this command:

```
htop
```

If you see python or conda or the actual programs execute, you know the system is working.  If you see a lot of 0's, not a lot is happening.  You should kill the process and restart it. 

# Pipeline Steps & Tools Used
The nextflow written herein is written using programs that already exist.  It is important to aknowledge and respect the work groups have done to create programs that significantly contribute to the world of bacterial genomics.  The pipeline performance and program use is below: 

## main.nf and nextflow.contig
Purpose: This is the master script that orchestrates the entire pipeline. It defines the order of operations, manages the data flow (channels) between all the different processes, and contains the high-level logic for handling single vs. multi-sample analyses.  It is written in Groovy
References: 
1)	https://link.springer.com/article/10.1186/s13059-025-03673-9
2)	https://www.nature.com/articles/nbt.3820
Programs: Conda was used for file management as it has fewer entry barriers for novice researchers compared to Docker.  
1)	References:
a.	https://github.com/conda/conda
b.	

## modules/QAQCClean.nf
Purpose: Handles the initial and post-filtering quality control of raw sequencing reads.
Programs Used:
1)	FastQC: A widely used tool that provides a comprehensive quality control report on raw sequence data.  It is easy, comprehensive, and has multiple ways the report can be parsed which is why it was chosen. 
a.	References
i.	https://github.com/s-andrews/fastqc
modules/decontamination.nf
Purpose: Identifies and separates target reads from contaminant reads in the raw data.  Kraken2 was specifically used as other methods tested did not identify as much contamination as Kraken2.  
Programs Used:
1)	Kraken2: A taxonomic classification system that assigns taxonomic labels to DNA sequences by matching k-mers to a database of genomes.
a.	References:
i.	https://pmc.ncbi.nlm.nih.gov/articles/PMC9725748/
ii.	https://github.com/DerrickWood/kraken2/wiki/Manual
iii.	

## modules/IndexClean.nf
Purpose: Prepares all necessary reference files and databases for the pipeline to use and indexes the reference assembly for post-assembly downstream analyses.  These programs are quick, accurate, and integrate well.
Programs Used:
1)	wget/curl: Command-line utilities to download files from the internet.
a.	References: 
i.	https://www.gnu.org/software/wget/manual/wget.html
2)	BWA/Minimap2: (Assumed) Indexing programs that prepare a reference FASTA file for fast read alignment.
a.	References BWA
i.	https://github.com/lh3/BWA
ii.	Li H. and Durbin R. (2009) Fast and accurate short read alignment with Burrows-Wheeler transform. Bioinformatics, 25, 1754-1760. [PMID: 19451168]. (if you use the BWA-backtrack algorithm)
iii.	Li H. and Durbin R. (2010) Fast and accurate long-read alignment with Burrows-Wheeler transform. Bioinformatics, 26, 589-595. [PMID: 20080505]. (if you use the BWA-SW algorithm)
iv.	Li H. (2013) Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. arXiv:1303.3997v2 [q-bio.GN]. (if you use the BWA-MEM algorithm or the fastmap command, or want to cite the whole BWA package)
b.	References for Minimap2
i.	https://github.com/lh3/minimap2
ii.	Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. Bioinformatics, 34:3094-3100. doi:10.1093/bioinformatics/bty191
iii.	Li, H. (2021). New strategies to improve minimap2 alignment accuracy.Bioinformatics, 37:4572-4574. doi:10.1093/bioinformatics/btab705

Various: Commands to format databases for tools like AMRFinderPlus and PlasmidFinder (their references are found in other .nf file descriptions)

## modules/circularizeassemblecheck.nf
Purpose: Assembles the cleaned reads into a genome, checks the assembly quality, and assesses its completeness.
Programs Used:
1)	Flye: A de novo assembler for long and error-prone reads (like Oxford Nanopore).
2)	QUAST: A tool that evaluates the quality of genome assemblies by computing various metrics.
3)	BUSCO (Busco): Assesses the completeness of a genome assembly by checking for the presence of expected single-copy orthologs.

## modules/resistance.nf
Purpose: Screens the assembled genome for known antimicrobial resistance (AMR) genes, virulence factors, and mobile genetic elements like plasmids.
Programs Used:
1)	AMRFinderPlus: A tool from NCBI to identify acquired antimicrobial resistance genes. This is a reference specific tool and the integration of this program into Nextflow required specific coding for the database to function.  The tool was chosen as it is a common program used by researchers within the federal and academic sector to identify antibiotic resistance elements.
a.	References:
i.	https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus
ii.	https://www.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000832
iii.	https://www.nature.com/articles/s41598-021-91456-0
2)	PlasmidFinder: Identifies plasmids in whole-genome data based on a database of known plasmid replicons.
3)	MOB-suite: A toolset for typing plasmids and predicting their mobility from genome assemblies.  This tool was used as it can identify plasmids de novo from WGS assemblies using replicons and reconstruct those plasmids as well as provide information link their incompatibility type.  The specific mob_suite used int his program requires the .yml file to be set up during the setup.sh program. 
a.	Reference:
i.	https://github.com/phac-nml/mob-suite
ii.	Robertson, James, and John H E Nash. ?MOB-suite: software tools for clustering, reconstruction and typing of plasmids from draft assemblies.? Microbial genomics vol. 4,8 (2018): e000206. doi:10.1099/mgen.0.000206
iii.	Robertson, James et al. ?Universal whole-sequence-based plasmid typing and its utility to prediction of host range and epidemiological surveillance.? Microbial genomics vol. 6,10 (2020): mgen000435. doi:10.1099/mgen.0.000435

4)	ABricate: A tool for mass screening of contigs for antimicrobial resistance or virulence genes and uses the VFDB and CARD databases, which are comprehensive. 
a.	Reference:
i.	https://github.com/tseemann/ABRICATE
ii.	CARD: https://pubmed.ncbi.nlm.nih.gov/36263822/
iii.	VFDB: https://www.ncbi.nlm.nih.gov/pubmed/26578559

## modules/snp_analysis.nf
Purpose: Performs SNP (Single Nucleotide Polymorphism) calling by aligning reads to a reference genome and identifying variant sites.  The method chosen was a traditional route that aligns the sequences to the previously indexed genome, identifies the SNPs and performs variant calling
Programs Used:
1)	Minimap2: A fast sequence mapping program for aligning reads to a reference genome. (See previous reference).  This program is fast, flexible for long read technologies, accurate at split reads and other challenges. 
2)	Samtools: A suite of utilities for interacting with high-throughput sequencing data and alignments (BAM/SAM files).  Specifically in this instance, Samtools converts the Minimap2 output to a binary file, sorts it by coordinates, and indexes the file
a.	Reference: 
i.	https://pmc.ncbi.nlm.nih.gov/articles/PMC2723002/
ii.	https://github.com/samtools/samtools
iii.	https://doi.org/10.1093/gigascience/giab008
3)	BCFtools: A set of utilities that manipulate variant calls in the Variant Call Format (VCF) and its binary counterpart (BCF) and is part of the samtools suite.  This pipeline is streamlined from end to end for SNP and variant calling. 
a.	Reference: 
i.	https://github.com/samtools/bcftools
ii.	http://samtools.github.io/bcftools/howtos/publications.html
iii.	https://doi.org/10.1093/gigascience/giab008

## modules/functional_analysis.nf
Purpose: Extracts gene lists based on SNP impact and performs functional enrichment analysis to see what biological roles are over-represented.
Programs Used:
1)	SnpEff: Annotates variants and predicts their effects on genes (e.g., missense, frameshift).
a.	Reference:
i.	https://pcingola.github.io/SnpEff/
ii.	https://pmc.ncbi.nlm.nih.gov/articles/PMC3679285/
2)	BCFtools: Used to filter and query VCF files to extract gene names.
3)	curl & jq: Command-line tools to directly query the PANTHER database API and parse the resulting JSON output.
a.	References: 
i.	Curl: https://curl.se/docs/manpage.html
ii.	Jq: https://docs.panther.com/search/data-explorer

## modules/phylogenetics.nf
Purpose: Creates a core SNP alignment from multiple samples and uses it to build a phylogenetic tree, showing the evolutionary relationships between the samples.
Programs Used:
1)	BCFtools: Used to merge VCF files and create a consensus FASTA sequence.
2)	FastTree/IQ-TREE: (Assumed) A program that takes a multiple sequence alignment and infers a phylogenetic tree.
a.	Referenece:
i.	https://iqtree.github.io/doc/Command-Reference
ii.	https://pmc.ncbi.nlm.nih.gov/articles/PMC4271533/
iii.	https://academic.oup.com/mbe/article/35/2/486/4644721

## modules/other_analysis.nf
Purpose: Contains miscellaneous analyses, including the identification of CRISPR arrays.
Programs Used:
1)	MinCED: A program to find CRISPRs (Clustered Regularly Interspaced Short Palindromic Repeats) in DNA sequences.
a.	Reference:
i.	https://github.com/ctSkennerton/minced
ii.	https://pmc.ncbi.nlm.nih.gov/articles/PMC10457644/
2)	matplotlib (Python): A plotting library used to generate the CRISPR summary figure.
a.	Reference: 
i.	https://matplotlib.org/
ii.	https://github.com/matplotlib/matplotlib

## modules/platon_module.nf
Purpose: A dedicated module for plasmid analysis using the Platon tool. Platon was chosen 
Programs Used:
1)	Platon: A tool for rapid plasmid identification and characterization in bacterial genomes right from the assembly.  It has the potential to identify novel plasmids through machine learning and it can determine where AMR or virulence genes are (plasmid v. chromosome).  
a.	Reference:
i.	https://github.com/oschwengers/platon
ii.	Schwengers O., Barth P., Falgenhauer L., Hain T., Chakraborty T., & Goesmann A. (2020). Platon: identification and characterization of bacterial plasmid contigs in short-read draft assemblies exploiting protein sequence-based replicon distribution scores. Microbial Genomics, 95, 295. https://doi.org/10.1099/mgen.0.000398
iii.	Carattoli A., Zankari E., Garcia-Fernandez A., Voldby Larsen M., Lund O., Villa L., Aarestrup F.M., Hasman H. (2014) PlasmidFinder and pMLST: in silico detection and typing of plasmids. Antimicrobial Agents and Chemotherapy, https://doi.org/10.1128/AAC.02412-14
iv.	Garcill�n-Barcia M. P., Redondo-Salvo S., Vielva L., de la Cruz F. (2020) MOBscan: Automated Annotation of MOB Relaxases. Methods in Molecular Biology, https://doi.org/10.1007/978-1-4939-9877-7_21
v.	Robertson J., Nash J. H. E. (2018) MOB-suite: Software Tools for Clustering, Reconstruction and Typing of Plasmids From Draft Assemblies. Microbial Genomics, https://doi.org/10.1099/mgen.0.000206
vi.	

## modules/visualization.nf, modules/final_report.nf, modules/multiqc.nf
Purpose: These modules are responsible for aggregating results from all other processes and generating the final plots, tables, and summary reports.
Programs Used:
1)	MultiQC: A tool that aggregates results from many bioinformatics analysis tools into a single, unified HTML report.
2)	2) R / ggplot2 / Python: (Assumed) Scripting languages and libraries used to generate custom plots and figures.
i.	References
1.	R: https://www.R-project.org/.
2.	Ggplot2: Wickham H (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York. ISBN 978-3-319-24277-4, https://ggplot2.tidyverse.org.
3.	Tidyverse: https://tidyverse.org/blog/2019/11/tidyverse-1-3-0/
4.	Python: https://docs.python.org/3/reference/index.html
5.	Panther: https://pmc.ncbi.nlm.nih.gov/articles/PMC6519457/
6.	PantherAPI: https://cran.r-project.org/web/packages/rbioapi/vignettes/rbioapi_panther.html

-
