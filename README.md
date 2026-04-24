# BACON (Bacterial Analysis Comprehensive Nextflow) 
# A Comprehensive and Reproducible Nextflow Pipeline for Bacterial Genome Analysis using PacBio Unaligned BAM Files and Downloaded SRA Files
https://doi.org/10.5281/zenodo.19743813

Hello!  Welcome to BACON, a Nextflow pipeline developed to make massive files produced by PacBio sequencers simpler to manage.  The BACON sizzles and provides detailed analyses for Microbial Genomics from heterologous sources with limited resources and outputs concatenated and cleaned CSV files, figures, and tables. 

Of note, the views expressed on this GitHub are personal and do not reflect any other viewpoints or endorsements of any organization or entity.  

# Key Features

 - Automated Setup: A single setup.sh script installs all dependencies and downloads required databases
 - User-Friendly: Interactive prompts for key parameters like genome size and coverage
 - High-Performance: Optimized for parallel execution on multi-core scientific workstations
 - Comprehensive Annotation: Integrates a suite of best-in-class tools for a deep biological understanding of the sample or sample
 - High-Throughput: Processes 1 to 100 samples without modifications to the pipeline provided the computer has the power to do the work 
 - Easy to manage: All software dependencies are explicitly managed by Nextflow and    Conda, guaranteeing a consistent environment
 
 # Best Practices ?
 - While not mandatory nor standard practice, run this pipeline with the sample data provided in the original files pulled from this repository.  Make sure it works for your system
 -  A control is always a good idea.  Either process one file first in the batch and compare it to the output of that file plus the other files, or find some sort of reference file to use.
 -  If any modifications to the pipeline are conducted, this will help track whether or not the output improves or not. f you have a question, post it in the Discussions section of this github.
 -  Don't try to manipulate the file names, tulpes, or any of that code.  Data inputs/outputs are super tricky and can cause the whole thing to crash.
 -  If BACON doesn't work, the first thing to check is whether or not the path is set, the terminal was closed and re-opened, and if the paths in the configuration file (nextflow.config) are accurate.
 -  If the program drops off, the first thing to check is memory availability (time specifically).
 -  Cite the pipeline (see the end of the readme file!)

# Getting Started: Start to Finish 

## Program requirements are as follows:

 - **Operating System Requirements:** This program works best on a Linux Workstation or a virtual machine using a Linux operating system.  If an Apple computer is being used, that is great but the directions herein will need to be modified to satisfy the requirements of an Apple ecosystem. 
    
	 - **Memory Requirements:** 16 to 32 GB
    
	 - **Minimum Harddrive:** 1 TB (smaller if you have a smaller dataset but
   don't go below 500 GB)
 
 - **Program dependencies:**  Have a working Operating System (Linux). 



## Self-Installing Dependencies 

The shell file named "setup.sh" in the list of files in the git repository pull will scan the system it is downloaded to upon execution and ensure the following dependencies are available: 

 1. Installs Nextflow 
 2. Installs and Updates Javascript 
 3. Installs Conda 
 4. Installs R 
 5. Installs R Studio 
 6. Installs GitHub Dependencies and BACON 
 7. Installs the databases and unpacks them 
 8. Makes everything executable (aka you can run the program) 
  

## Let's Go: Downloading and Running the Setup File and Modifying Nextflow Documents for Success

Using a fresh virtual machine, the setup.sh program takes about 1 to 4 hours.  The program automatically accepts the user agreements, downloads and unpacks databases, pulls the GIT repository, and downloads everything needed for a successful run as described above. 
   
### 1. Download: setup.sh 

Follow these steps precisely: 

 1. Download shell.sh or copy and paste it and save it in a text file as "startup.sh" **in the working directory you intend to work**.   I like to see my files, so I typically navigate to my working directory as follows:
 ```
 cd Desktop
 mkdir project
 cd project 
 ```
 
 3. Make the shell program executable with the following command:
    ```chmod -x shell.sh```
 4. Execute the command. 
     ```bash shell.sh ```

**IMPORTANT:** The install system is fully automated and assumes that you accept the terms and conditions of every program that is downloading.  You will see a lot of stuff tick across the screen as the shell program executes.  This is normal.  So, go get some coffee or tea, have a couple of meetings, and come back in 1 to 4 hours and be ready to work.  If an error shows up, please let me know in the QA section of this GitHub page and I'll figure something out.  

The shell will automatically download BACON.

Once the setup.sh file sets up, close the terminal and reopen it for the changes to take effect.  

Another shell file is downloaded with the git repository, called check.sh.  This program ensures that everything is set up properly.  

Pro Tip: Run this program twice!

 1. After the setup.sh
 2. After the modifications to Nextflow files
 
 ```
chmod -x check.sh 
bash check.sh
```

Everything should pass.  If not, let me know on the discussion board after troubleshooting your files, paths, and syntax. 

### 2. Modify the Nextflow Program Files
The following steps set up the nextflow program once the setup.sh file completes its tasks.  There are modifications that will need to be made so they are listed below by document

#### nextflow.config
The nextflow.config file is below.  The areas that need to be adjusted have a [BRACKET].  An example of a complete NEXTFLOW.CONFIG file is the one downloaded by setup.sh. 

##### 1. Determine the computational power of your system:
```
lscpu  ## This tells you how many CPUs and cores you have onboard ##
free -h ## This tells you your available memory, used, and total ##
vmstat 12  ## Another way to tell how much memory a computer has
```
Use this information provided by the output in your terminal to modify the computing resources

Pro Tip: Take the total memory and divide it by a comfortable number.  If there are 32 GB of RAM and there are 20 samples to process, find a comfortable number like 4 and divide the total RAM available by that number (in our case 8 GB).  That number will become your **MAX** memory useage per sample for the high demand process.  Then, taper off similar to what was done in the example file for the medium and low level processes.  For time, think about how many samples need to run and give your program time to run.  

##### 2. Directories are set by the user
The setup.sh file will start from your root directory and download the databases and other files there.  Ahead of executing startup.sh, ensures the working directory is where everything is downloading and fully accessible by the user.  Copy and paste the directory path for the missing directories below (don't forget the ') 

##### 3.  Microbial information is provided by the user
PantherDB: https://pantherdb.org/validateHuman.jsp
NCBI Taxonomy Browser: https://www.ncbi.nlm.nih.gov/taxonomy
These databases will help you identify all of the information below specific to your bug of interest.  

```
conda.enabled = true
conda.cacheDir = "${projectDir}/conda"

executor {
    name = 'local'
    cpus = [DETERMINE]
    memory = [MAX MEMORY DETERMINED]
}


params {
    input_bam             = 'inputs/*.bam'
    bakta_db              = [SET DIRECTORY]
    platon_db             = [SET DIRECTORY]
    kraken2_db_path       = [SET DIRECTORY]
    outdir                = "${projectDir}/results"
    genome_size           = [DETERMINE AND WRITE IT LIKE THIS...'SIZE m']
    coverage              = 100 
    target_taxid          = [LOOK UP AT THIS SITE: https://www.ncbi.nlm.nih.gov/taxonomy]
    traits_file           = "${projectDir}/metadata.csv"
    tree_color_column     = 'sequence_type'
    panther_organism      = [NAME OF ORGANISM, VALIDATE ON PANTHER THAT IT IS THERE]
    panther_annot_dataset = 'GO:0008150' [YOU CAN CHANGE THIS IF YOU WANT]
    rbioapi_organism_id   = [LOOK THIS UP]
    rbioapi_annot_dataset = 'GO:0008150' [YOU CAN CHANGE THIS IF YOU WANT]
}

process {
    // --- Default Resources ---
    cpus   = 4
    memory = '8 GB'
    time   = '122h'

    // --- Resource Labels ---
    withLabel: 'process_low'    { cpus = 2;  memory = '4 GB';   time = '48h'  } [ADJUST IF YOU NEED TO, THIS IS OPTIMIZED FOR 32 GB RAM AND 1 TB HD]
    withLabel: 'process_medium' { cpus = 8;  memory = '32 GB';  time = '48h'  } [ADJUST IF YOU NEED TO, THIS IS OPTIMIZED FOR 32 GB RAM AND 1 TB HD]
    withLabel: 'process_high'   { cpus = 12; memory = '120 GB'; time = '122h' } [ADJUST IF YOU NEED TO, THIS IS OPTIMIZED FOR 32 GB RAM AND 1 TB HD]
}

// --- Reporting ---
report.overwrite   = true
timeline.overwrite = true
trace.overwrite    = true
dag.overwrite      = true

// --- Tool-specific configs ---
multiqc {
    files_ignore = ['work', '.nextflow', 'nextflow.config']
}
```





#### The Module File Changes
The BACON is modularized, which makes the Nextflow program easier to manage.  All modular files have the file extension `nf` and are in the `./modules` directory.  

Because each program that the system uses is unique, changes may need to occur within the nf files.  The files listed below are the only ones that require a change.  At any time, users can modify the code within each process to satisfy their needs.  

**Modify:** **IndexClean.nf**
Go to ncbi and find a reference genome for the bacterial species BACON will analyze.  Copy the .fna.gz link and replace the link in the process file.  For visualizaiton purposes, the brackets are displayed below but an example of the link is included in the real IndexClean.nf file downloaded with the repository. 
```
process DOWNLOAD_BACTERIAL_REFERENCE {
    tag "Downloading Bacterial Reference"
    label 'process_low'
    conda 'conda-forge::wget=1.21.4'
    output: path("bacterial_ref.fasta"), emit: fasta
    script:
    """
    wget --no-check-certificate -O bacterial_ref.fasta.gz ["FNA.GZ_LINK"]
    gunzip bacterial_ref.fasta.gz
    """
}
```
**Modify**: **Circularizeassemble.nf**
Busco has a general bacteria database called in the program.  If you want a more specific database, please feel free to update it. 

```
process BUSCO {
    tag "Busco report for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::busco'
    publishDir "${params.outdir}/tables/bosco", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)
    output:
    tuple val(sample_id), path("busco_output"), emit: busco_report
    script:
    """
    busco -i "${fasta}" -m genome -o busco_output -l [bacteria_odb12]
    """
}
```

#### Working Directory File Structure

Make sure the directory (or folder) you want to have your files created in is your "working directory".  Make sure your project directory is in the paths identified in the files.  The big issue is that Nextflow only puts things where it puts them based on the program that is already written.  So, if the outputs (in the nextflow.config) do not match your file path, nextflow may get confused and crash. 

The directories (files) should be ordered as follows: 

Project/
--- main.nf
-- nextflow.config
-- envs/
-- modules/
-- asset/
-- databases/

A directory is missing!  The inputs directory needs to be created.  
```
   cd ./Desktop/Project
   mkdir inputs
  ```  

Drop the unaligned bam files and drop them into the inputs folder.  

Pro Tip: Do not change the names of the folders or mess with anything not specifically defined in the setup directions. 


#### OPTIONS: Data from Public Repositories

NCBI files will either download as raw bam files or fastq files.  BACON will not process fastq files directly.  

Don't assume the files from public repositories are well executed by the depositor.  You can read more about that here: https://pubmed.ncbi.nlm.nih.gov/32398145/,  Make sure that any file you receive goes through the full QAQC protocol delineated in the script included with this repository named "CodeForPaperValidation".  This markdown details the work for one vs. multiple SRA files, validation, and conversion of said files so BACON can analyze the data.  

## 3. Running Nextflow: The Main Event 

After you've checked your file paths, added the necessary information, made sure any syntax meant to signal a change ([Example]) is gone, BACON should be ready to sizzle!  The following command will execute the Nextflow and output metrics for the run:

```
$nextflow run main.nf -with-report report.html -with-timeline timeline.html -with-trace trace.txt 
```
Of course, leaving off the  `-with-report report.html -with-timeline timeline.html -with-trace trace.txt ` is fine, but then the run metrics will not print. 

If successful, something like this will appear...
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
As the process runs, the 0% will become 100%.  A "work" and a "results" folder will generate, as well as a summarize folder and a folder PER sequence you're analyzing.  At any time, the following command can be executed in a separate terminal to determine whether or not the program is running.
```
htop
```
 If you see randomness as an output or lots of "0"s, the first thing you should do is: 

1) Check your file paths
2) Check your working directory
3) Check your downloads (fna file)
4) Make sure your inputs are unaligned bam files

A healthy output looks like this: 
```
    0]   3]   6]   9]  12]  15]          18]  21]  24]  27]  30]  33]
    1]   4]   7]  10]  13]  16]          19]  22]  25]  28]  31]  34]
    2]   5]   8]  11]  14]  17]          20]  23]  26]  29]  32]  35]
  Mem[|||||||||||||||||||||4.52G/68.7G] Tasks: 149, 888 thr, 0 kthr; 6 running
  Swp[                           0K/0K] Load average: 4.28 4.55 4.33 
                                        Uptime: 2 days, 05:59:27

  [Main] [I/O]
    PID USER       PRI  NI  VIRT   RES   SHR S  CPU%\u25bdMEM%   TIME+  Command
1471768 dnanexus    18  -2 5039M  109M  6820 R 100.2  0.2  4h14:43 bcftools mpil
1499352 dnanexus    18  -2 5029M 99.3M  6912 R 100.2  0.1  3h45:18 bcftools mpil
1653161 dnanexus    18  -2 5006M 77720  6924 R 100.2  0.1  4:11.57 bcftools mpil
1331235 dnanexus    18  -2 5038M  108M  6816 R  99.5  0.2  7h35:42 bcftools mpil
1657772 dnanexus    18  -2 10332  6128  3564 R   3.9  0.0  0:02.97 htop
```
It goes on and on and on and updates all the time. 

If you see python or conda or the actual programs execute, you know the system is working.  In this instance, bcftools is currently running, taking up 100.2% x 3 CPUS plus 99.5% CPUS, as is htop and other prgrams below.  So, it is running! If there are a lot of 0's, the program is hung up somewhere.  In that event, kill the process and restart it. 


# Understanding the BACON Pipeline  

This section is dedicated  BACON pipeline works, step-by-step. Imagine BACON as a highly organized factory for analyzing bacterial DNA. Each section below describes a "station" in this factory:

*  **What it does**: The main goal of that station.

*  **The tools it uses**: Which specialized "machines" are working there.

*  **The `*.nf` file**: Think of this as the instruction manual for that specific station within our Nextflow factory.

*  **What you can do next**: How the results from this station can be used for further exploration, even beyond what BACON automatically provides.

We built BACON to be easy to follow and troubleshoot, especially for those who are new to these kinds of analyses. Unlike some other complex systems (like `nf-core`), BACON aims to be straightforward, with clear instructions and support if you need it.

We highly recommend using the practice pipeline (you'll find it linked in this GitHub) to get comfortable with BACON and make sure it runs smoothly on your computer.

---

## Getting Started & Finding Your Data: `setup.sh` and other `sh` files

These shell files are where you start.  Each script helps you gather and prepare your bacterial DNA sequencing data.

**What they do**:

1.  **Download public data**: They can fetch publicly available DNA sequencing datasets (from places like SRA) that you want to analyze.

2.  **Check and convert**: They make sure the downloaded files are complete and then convert them into a specific format (`unaligned BAM files`) that BACON needs to start its work. Think of it as getting all your ingredients in the right packaging for the factory.

These scripts also include special tips learned from experience to address common hiccups, ensuring your analysis starts on the right foot.

**Your action**: You just need to run these scripts. But **before you do**, quickly look them over to make sure they won't accidentally put files in places on your computer where you don't want them.

---

### The Brains of the Operation: `main.nf` and `nextflow.config`

These two files are like the central control system and the settings panel for your BACON pipeline. They tell the entire factory how to run.

*  **`main.nf` (The Director)**: This script is the "director" of the whole pipeline. It decides the order of all the steps, makes sure data flows correctly from one process to the next, and figures out if you're analyzing just one sample or many, adjusting the workflow automatically. It's written in a programming language called Groovy.

*  **Where to learn more**:

1.  <https://link.springer.com/article/10.1186/s13059-025-03673-9>

2.  <https://www.nature.com/articles/nbt.3820>

*  **`nextflow.config` (The Settings Panel)**: This is your personal control panel! Here, you can easily tweak things like:

*  How much computer memory (RAM) and processing power (CPU) BACON can use.

*  Where BACON should find your input files and save its results.

*  Where to find the specialized "toolkits" (called Conda environments) that BACON needs.

*  **Good to know**: While Conda is used because it's easier for beginners, if you're an advanced user familiar with Docker, you could potentially set up BACON to use that instead.

*  **Conda explained**: Conda helps manage all the different software BACON uses, making sure they all work together without issues.

1.  <https://github.com/conda/conda>

---

###  Stage 1: Setting Up Your Data Foundation (`Indexclean.nf`)

Before we can start the deep analysis, BACON needs to build its reference library and organize its "knowledge bases" (databases). This stage is all about preparing those essential resources.

**Before running this stage, you need to**:

*  **Update `nextflow.config`**: Make sure you've told BACON where your main reference genome file is, where all the files should go, and how much computer power it can use.

*  **Specify your species**: If your bacteria has a unique identifying code (like "1423" in the example), ensure you've updated it in `nextflow.config` to match your specific organism.

**What `Indexclean.nf` does**:

Once you run the pipeline, this module jumps into action:

1.  **Downloads and Prepares References**: It downloads the main reference genome sequence and then "indexes" it. Think of indexing as creating a super-fast search catalog for the genome, so BACON can quickly find specific DNA sections later. Tools like `wget` (for downloading) and `bwa index` (for creating the catalog) are used here.

2.  **Organizes Databases**: BACON uses many specialized databases (collections of biological information). This step sets them all up. Some databases are prepared here because each one has its own preferred way of being managed. Others might have been set up earlier during the `setup.sh` stage, depending on what works best for that particular database. This ensures all the "knowledge" BACON needs is in the right place and ready to be accessed efficiently.

---

### Stage 2: Your First Quality Check-up (`QAQClean.nf`)

Even the best ingredients need a quick check before you start cooking! This stage is all about making sure your raw DNA sequencing data is of good quality right from the start.

**What `QAQClean.nf` does**:

1.  **Individual Read Quality**: Your raw sequencing files first go through **FastQC**. Imagine FastQC as a detailed health report for each batch of DNA reads, telling you if they're healthy and robust.

2.  **Summary Report**: All these individual FastQC reports are then gathered and summarized by **MultiQC**. This creates one easy-to-read, comprehensive report that shows you the overall quality of *all* your starting data at a glance.

This step helps you quickly spot any issues with your raw DNA data early on. You can also see how much difference later processing steps make to your reads.

**The Tools We Use Here**:

*  **FastQC**: This is like a thorough doctor's check-up for your raw DNA sequences. It gives you a detailed report on their quality, and it's chosen because it's easy to use and provides clear insights.

*  **Reference**:

1.  <https://github.com/s-andrews/fastqc>

*  **Understanding Your Results**:

1.  How to read your FastQC results: <https://bioinfo.cd-genomics.com/quality-control-how-do-you-read-your-fastqc-results.html>

2.  FastQC tutorial: <https://www.youtube.com/watch?v=qPbIlO_KWN0>

*  **MultiQC**: Think of MultiQC as the manager who collects all the individual FastQC reports and combines them into one clear, easy-to-understand summary.

*  **References**:

1.  <https://multiqc.info/>

2.  Ewels, P., Magnusson, M., Lundin, S., & K�ller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, **32**(19), 3047?3049. [doi:10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

---

###  Stage 3: Cleaning Up Your Data: Removing "Junk," Trimming, & Sampling (`modules/decontamination.nf`)

Raw DNA data, especially from advanced long-read sequencers, often comes with extra "noise" ? things like contamination (human DNA, leftover lab chemicals) or too much data that can actually make things harder. This stage is all about cleaning up that raw data to get it perfect for the next steps.

**What `modules/decontamination.nf` does**:

1.  **Spotting and Removing Contamination**: We use a tool called **Kraken2** to act like a detective, finding and separating any unwanted DNA (like human or viral DNA) from your bacterial DNA. Kraken2 is great at this, even with mixed samples. We'll eventually show you what contamination was found, but only the "clean" bacterial DNA moves forward.

2.  **Smart Sub-sampling**: After cleaning, we use **Rasusa** to intelligently "sub-sample" your DNA reads down to a very specific amount (typically 100 times coverage). Why? Because with bacterial DNA, too much data isn't always better! Especially for smaller DNA circles called plasmids, too much sequencing can actually make them harder to find. This step makes sure we have just the right amount of high-quality data to get the best results.

3.  **Final Quality Check (Pre-Assembly)**: After all this cleaning and subsampling, we do *another* quick quality check with **FastQC** and **MultiQC**. This is a crucial step to confirm that the DNA reads are in excellent shape just before we send them off for assembly.

**The Tools We Use Here**:

*  **Kraken2**: This tool classifies DNA sequences, helping us identify and filter out any contaminating DNA.

*  **References**:

1.  <https://pmc.ncbi.nlm.nih.gov/articles/PMC9725748/>

2.  <https://github.com/DerrickWood/kraken2/wiki/Manual>

*  **Rasusa**: This smart tool helps us create an ideal set of DNA reads by carefully choosing a representative sample, ensuring we don't have too much or too little data.

*  **References**:

1.  <https://github.com/sanger-pathogens/rasusa>

2.  Hall, M. B., et al. (2020). Rasusa: Randomly subsample reads to a specified coverage. *Journal of Open Source Software*, 5(52), 2410. [doi:10.21105/joss.02410](https://doi.org/10.21105/joss.02410)

*  **FastQC**: Gives a detailed quality report for the cleaned and subsampled DNA reads.

*  **Reference**:

1.  <https://github.com/s-andrews/fastqc>

*  **MultiQC**: Gathers all the individual FastQC reports into one easy-to-read summary, confirming the quality of the data going into assembly.

*  **References**:

1.  <https://multiqc.info/>

2.  Ewels, P., Magnusson, M., Lundin, S., & K�ller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, **32**(19), 3047?3049. [doi:10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

*  **wget/curl**: These are basic internet tools commonly used throughout the pipeline to download various files, including databases or reference genomes needed for different stages.

*  **Reference**:

1.  <https://www.gnu.org/software/wget/manual/wget.html>

*  **BWA/Minimap2**: These are general-purpose indexing and alignment tools that prepare reference FASTA files for fast read alignment, which can be useful for various sub-steps within the pipeline.

*  **References for BWA**:

1.  <https://github.com/lh3/BWA>

2.  Li H. and Durbin R. (2009) Fast and accurate short read alignment with Burrows-Wheeler transform. *Bioinformatics*, **25**, 1754-1760. [PMID: 19451168](http://www.ncbi.nlm.nih.gov/pubmed/19451168).

3.  Li H. and Durbin R. (2010) Fast and accurate long-read alignment with Burrows-Wheeler transform. *Bioinformatics*, **26**, 589-595. [PMID: 20080505](http://www.ncbi.nlm.nih.gov/pubmed/20080505).

4.  Li H. (2013) Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. [arXiv:1303.3997v2](http://arxiv.org/abs/1303.3997) [q-bio.GN].

*  **References for Minimap2**:

1.  <https://github.com/lh3/minimap2>

2.  Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*, **34**:3094-3100. [doi:10.1093/bioinformatics/bty191](https://doi.org/10.1093/bioinformatics/bty191)

3.  Li, H. (2021). New strategies to improve minimap2 alignment accuracy. *Bioinformatics*, **37**:4572-4574. [doi:10.1093/bioinformatics/btab705](https://doi.org/10.1093/bioinformatics/btab705)

---

###  Stage 4: Building & Labeling Your Bacterial Blueprint (`assembly.nf`, `annotation.nf`)

Now that your DNA reads are super clean, it's time for some serious construction! This stage takes all those tiny DNA pieces and puts them together like a puzzle to build the complete bacterial genome (assembly). Then, it labels all the important parts of that genome (annotation).

**What happens in this stage**:

1.  **Genome Assembly**: We use a powerful tool called **Flye** to assemble your bacterial genome. Think of Flye as a master architect that takes all your DNA reads and stitches them into a complete blueprint. A really cool thing about BACON is that Flye can **automatically recognize and adjust its building strategy based on the type of PacBio data you provide**. This means whether you have super-accurate 'HiFi' reads or longer, slightly more error-prone reads, Flye knows how to make the best possible assembly.

2.  **Genome Annotation**: Once the genome is assembled, it's still just a long string of letters. We use **Bakta** to act like a genetic dictionary, going through the genome and identifying all the important features:

*  **Genes**: Where are the instructions for making proteins?

*  **tRNAs/rRNAs**: Other important genetic components.

*  **Special features**: Anything else noteworthy about the bacterial DNA.

Bakta labels everything clearly so you can understand what each part of the genome does.

3.  **Quality Control of the Blueprint**: Just like a builder needs to check their work, we rigorously assess the quality of the assembled genome using two tools:

*  **QUAST**: This tool gives us a report card on the overall quality of the assembly (e.g., how complete it is, how many gaps there are).

*  **BUSCO**: This tool checks how complete your new bacterial blueprint is by looking for a set of essential genes that *every* bacterium should have. If many are missing, it might mean the assembly isn't as complete as it could be. (You can even tell BUSCO which specific group of bacteria to compare against for a more accurate check!).

**The Tools We Use Here**:

*  **Flye**: Your master architect for assembling long and challenging DNA reads into a complete genome.

*  **References**:

1.  <https://github.com/mikolmogorov/Flye>

2.  Kolmogorov, M., Bickhart, D. M., Behsaz, B., Gurevich, A., Rayko, M., Shin, S. B., ... & Pevzner, P. A. (2020). metaFlye: scalable long-read metagenome assembly using repeat graphs. *Nature Methods*, **17**(12), 1188-1191. [doi:10.1038/s41592-020-00971-x](https://doi.org/10.1038/s41592-020-00971-x)

3.  Kolmogorov, M., Yuan, J., Lin, Y., & Pevzner, P. (2019). Assembly of long error-prone reads using repeat graphs. *Nature Biotechnology*, **37**(5), 540-546. [doi:10.1038/s41587-019-0072-8](https://doi.org/10.1038/s41587-019-0072-8)

4.  Lin, Y., Yuan, J., Kolmogorov, M., Shen, M. W., Chaisson, M., & Pevzner, P. A. (2016). Assembly of long error-prone reads using de Bruijn graphs. *Proceedings of the National Academy of Sciences*, **113**(47), E7629-E7638. [doi:10.1073/pnas.1604560113](https://www.doi.org/10.1073/pnas.1604560113)

*  **Bakta**: Your genetic dictionary and annotator, labeling all the functional parts of the bacterial genome.

*  **References**:

1.  <https://github.com/oschwengers/bakta>

2.  Schwengers O., Jelonek L., Dieckmann MA, Beyvers S., Blom J., Goesmann A. (2021). Bakta: rapid and standardized annotation of bacterial genomes via alignment-free sequence identification. *Microbial Genomics*, **7**(11). [doi:10.1099/mgen.0.000685](https://doi.org/10.1099/mgen.0.000685)

3.  <https://bakta.readthedocs.io/>

*  **QUAST**: The quality control specialist for your genome assembly, providing a detailed report on its overall quality.

*  **References**:

1.  <https://github.com/ablab/quast>

2.  <https://quast.sourceforge.net/docs/manual.html>

3.  Gurevich, A., Saveliev, V., Slesarev, N., & Tesler, G. (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, **29**(8), 1072-1075. [PMID: 23422033](https://pmc.ncbi.nlm.nih.gov/articles/PMC3624806/)

*  **Understanding Your Results**:

1.  QUAST Genome Assembly Quality Assessment: <https://www.biobam.com/quast-genome-assembly-quality-assessment/>

*  **BUSCO (Benchmarking Universal Single-Copy Orthologs)**: The completeness checker, making sure your assembled genome has all the essential genes it should.

*  **References**:

1.  <https://academic.oup.com/bioinformatics/article/31/19/3210/211866>

2.  <https://busco.ezlab.org/busco_userguide.html>

*  **Understanding Your Results**:

1.  Genome Completeness Assessment with BUSCO: <https://www.biobam.com/genome-completeness-assessment-with-busco/>

---

### Stage 5: Discovering Bacterial Defenses & Traits (`resistance.nf`)

This stage is all about finding out what special abilities your bacteria might have. We screen the assembled bacterial blueprint for genes that contribute to antibiotic resistance, virulence (what makes them harmful), and important mobile genetic elements called plasmids.

**What `resistance.nf` does**:

1.  **Antibiotic Resistance (AMR) Genes**: We look for specific genes that can make bacteria resistant to antibiotics. We use highly curated databases with tools like **AMRFinderPlus** (from NCBI) and **Abricate** (using VFDB and CARD databases). These tools are trusted by many researchers to identify these critical elements.

2.  **Plasmid Identification**: Plasmids are small, circular pieces of DNA that can carry important genes (like resistance genes!) and can move between bacteria. We look for them in three ways, with two primary methods used here:

*  **PlasmidFinder**: Scans for known plasmids by comparing them to a database of previously identified plasmids.

*  **MOB_Recon**: Identifies potential new plasmids by looking for specific genetic markers (like replicons and relaxases) and can even reconstruct their sequences. This tool can also tell you about 'incompatibility families,' which are like a plasmid's family tree. This means you could potentially discover new plasmids and explore them further! (Note: Another tool, Platon, will also identify plasmids in a later stage.)

*  **What you can do next**: If MOB_Recon finds potential new plasmids, you could take those sequences and use other tools (like Bakta, which we used in Stage 4) to annotate them even more deeply, or even do lab experiments to confirm their existence.

3.  **Virulence Factors**: We also look for genes that help bacteria cause disease, giving insights into how harmful a particular strain might be.

**The Tools We Use Here**:

*  **AMRFinderPlus**: A tool from the NCBI specifically designed to identify known antibiotic resistance genes. It's widely used in research and public health for its reliability.

*  **References**:

1.  <https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus>

2.  Feldgarden, M., et al. (2019). AMRFinderPlus: a protein homology- and k-mer-based tool for identification of antimicrobial resistance genes in protein or nucleotide sequence data. *Microbial Genomics*, **5**(11). [doi:10.1099/mgen.0.000271](https://www.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000271)

3.  Feldgarden, M., et al. (2021). AMRFinderPlus: An Updated Toolkit for Antimicrobial Resistance Gene Identification and Characterization. *Nature Scientific Reports*, **11**(1), 11823. [doi:10.1038/s41592-021-91456-0](https://www.nature.com/articles/s41592-021-91456-0)

*  **PlasmidFinder**: Helps identify known plasmids in your genome by comparing them against a database of previously found plasmids.

*  **References**:

1.  <https://github.com/genomicepidemiology/plasmidfinder>

2.  Carattoli, A., et al. (2014). PlasmidFinder and pMLST: in silico detection and typing of plasmids. *Antimicrobial Agents and Chemotherapy*, **58**(7), 3895?3903. [doi:10.1128/AAC.02412-14](https://doi.org/10.1128/AAC.02412-14)

3.  Camacho, C., et al. (2009). BLAST+: architecture and applications. *BMC Bioinformatics*, **10**(1), 421.

4.  Clausen, P. T. L. C., et al. (2018). Rapid and precise alignment of raw reads against redundant databases with KMA. *BMC Bioinformatics*, **19**(1), 307.

*  **MOB-suite**: A comprehensive toolset for identifying, reconstructing, and typing plasmids. It's particularly good at finding new plasmids based on key genetic signatures and provides details like 'incompatibility type.'

*  **References**:

1.  <https://github.com/phac-nml/mob-suite>

2.  Robertson, J., & Nash, J. H. E. (2018). MOB-suite: software tools for clustering, reconstruction and typing of plasmids from draft assemblies. *Microbial Genomics*, **4**(8), e000206. [doi:10.1099/mgen.0.000206](https://doi.org/10.1099/mgen.0.000206)

3.  Robertson, J., et al. (2020). Universal whole-sequence-based plasmid typing and its utility to prediction of host range and epidemiological surveillance. *Microbial Genomics*, **6**(10), mgen000435. [doi:10.1099/mgen.0.000435](https://doi.org/10.1099/mgen.0.000435)

4.  Garcill�n-Barcia, M. P., et al. (2020). MOBscan: Automated Annotation of MOB Relaxases. *Methods in Molecular Biology*, **2271**, 271-285. [doi:10.1007/978-1-4939-9877-7_21](https://doi.org/10.1007/978-1-4939-9877-7_21)

5.  Robertson, J., & Nash, J. H. E. (2018). MOB-suite: Software Tools for Clustering, Reconstruction and Typing of Plasmids From Draft Assemblies. *Microbial Genomics*, **4**(8), e000206. [doi:10.1099/mgen.0.000206](https://doi.org/10.1099/mgen.0.000206)

*  **ABricate**: A tool used for quickly screening your assembled genome for a wide range of antibiotic resistance or virulence genes, leveraging comprehensive databases like VFDB (Virulence Factor Database) and CARD (Comprehensive Antibiotic Resistance Database).

*  **References**:

1.  <https://github.com/tseemann/ABRICATE>

2.  Jia, B., et al. (2017). CARD 2017: expanded reference database and web-portal for antimicrobial resistance informatics. *Nucleic Acids Research*, **45**(D1), D566-D573. [PMID: 27924040](https://pubmed.ncbi.nlm.nih.gov/36263822/)

3.  Liu, B., et al. (2019). VFDB 2019: a comparative pathogenomic analysis platform with an updated database. *Nucleic Acids Research*, **47**(D1), D669-D673. [PMID: 26578559](https://www.ncbi.nlm.nih.gov/pubmed/26578559)

---

### Stage 6: Pinpointing Genetic Differences (SNP Analysis)

This stage is all about finding tiny, single-letter changes in the bacterial DNA (called Single Nucleotide Polymorphisms, or SNPs). These SNPs are like genetic "fingerprints" that can help us understand how different bacterial strains are related or what might be causing their unique traits.

**What happens in this stage**:

**SNP Discovery and Annotation**:

1.  **Aligning Reads**: We take your cleaned DNA reads and precisely line them up (align them) against a reference genome using **Minimap2**. This is like overlaying your bacterial "text" onto a known "textbook" to spot differences.

2.  **Finding Differences (Variant Calling)**: Once aligned, **Samtools** and **BCFtools** work together to pinpoint exactly where your bacterial DNA differs from the reference, identifying all the SNPs.

3.  **Understanding the Impact (Annotation)**: We use **SnpEff** to figure out what these SNPs *mean*. Does a SNP change a gene? Does it affect a protein? SnpEff tells us the potential consequences of each genetic change.

4.  **Functional Enrichment**: If a SNP affects a gene, we pull out that gene and use the **PANTHER DB** (accessed via `curl` & `jq`) to see if certain types of genes or biological pathways are unusually common among the affected genes. This helps us understand what biological processes might be impacted by the genetic changes.

**Phylogenetic Analysis (Tracing Relationships)**:

1.  **Building a Family Tree**: For analyses with multiple bacterial samples, **BCFtools** helps create a "core SNP alignment." This alignment is then used by **FastTree/IQ-TREE** to build a phylogenetic tree.

2.  **Revealing Evolutionary History**: This tree is like a family tree for your bacteria, showing how they've evolved and how closely related different samples are to each other.

**The Tools We Use Here**:

*  **Minimap2**: An extremely fast and flexible tool for aligning your DNA reads (especially long ones) to a reference genome, even if there are complex differences.

*  **Reference**: (See Stage 3 for full references)

*  **Samtools**: A essential suite of tools for managing and processing large DNA sequencing data files. Here, it helps convert, sort, and index the aligned reads so we can easily find SNPs.

*  **References**:

1.  <https://pmc.ncbi.nlm.nih.gov/articles/PMC2723002/>

2.  <https://github.com/samtools/samtools>

3.  Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. *GigaScience*, **10**(2), giab008. [doi:10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008)

*  **BCFtools**: Part of the Samtools suite, this tool is specifically designed to work with SNP data, helping us filter, analyze, and combine SNP information.

*  **References**:

1.  <https://github.com/samtools/bcftools>

2.  <http://samtools.github.io/bcftools/howtos/publications.html>

3.  Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. *GigaScience*, **10**(2), giab008. [doi:10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008)

*  **SnpEff**: This tool "annotates" your SNPs, predicting what biological effect each genetic change might have (e.g., if it changes a protein's function).

*  **References**:

1.  <https://pcingola.github.io/SnpEff/>

2.  Cingolani, P., et al. (2012). SnpEff: Variant effects and annotation. *F1000Research*, **1**, 60. [PMID: 23678076](https://pmc.ncbi.nlm.nih.gov/articles/PMC3679285/)

*  **curl & jq**: These are command-line tools that let BACON talk directly to online databases (like PANTHER) to get extra information about the genes impacted by SNPs.

*  **References**:

1.  Curl: <https://curl.se/docs/manpage.html>

2.  Jq: <https://docs.pantherdb.org/search/data-explorer>

*  **FastTree/IQ-TREE**: These programs are specialized for building phylogenetic "family trees" from genetic data, helping visualize the evolutionary relationships between your bacterial samples.

*  **References**:

1.  <https://iqtree.github.io/doc/Command-Reference>

2.  Price, M. N., Dehal, P. S., & Arkin, A. P. (2010). FastTree 2 ? Approximately Maximum-Likelihood Trees for Large Alignments. *PLoS ONE*, **5**(3), e9490. [PMID: 20224823](https://pmc.ncbi.nlm.nih.gov/articles/PMC4271533/)

3.  Minh, B. Q., et al. (2020). IQ-TREE 2: New Models and Efficient Strategies to Govern Phylogenetic Information Flow. *Molecular Biology and Evolution*, **37**(5), 1530?1534. [doi:10.1093/molbev/msaa077](https://academic.oup.com/mbe/article/35/2/486/4644721)

---

### Stage 7: Discovering Bacterial Immune Systems (CRISPR Identifications)

This stage focuses on identifying CRISPR (Clustered Regularly Interspaced Short Palindromic Repeats) systems within your bacterial genomes. CRISPRs are like a bacterial immune system, helping them defend against viruses and other invaders by remembering past infections.

**What `modules/crispr_identification.nf` does**:

1.  **CRISPR Detection**: We use a tool called **MinCED** to scan the bacterial DNA for these unique CRISPR regions.

2.  **Visual Summary**: Once identified, BACON generates a summary figure using **Matplotlib**. This figure graphically displays the CRISPR regions found in your genome.

**What you can do next**:

The information from this stage can be very valuable. For example, if you're studying bacteria like *Salmonella*, CRISPR patterns can help distinguish different types (serovars). It can also help researchers discover entirely new CRISPR-Cas systems, which are of great interest for biomedical research and gene editing technologies.

**The Tools We Use Here**:

*  **MinCED**: A specialized program designed to find CRISPR arrays (Clustered Regularly Interspaced Short Palindromic Repeats) within DNA sequences.

*  **References**:

1.  <https://github.com/ctSkennerton/minced>

2.  Bland, C., & Novick, R. P. (2014). MinCED: a fast and accurate tool for CRISPR identification. *F1000Research*, **3**, 145. [PMID: 25436154](https://pmc.ncbi.nlm.nih.gov/articles/PMC10457644/)

*  **matplotlib (Python)**: A popular and powerful library in Python used for creating static, interactive, and animated visualizations. Here, it's used to generate the summary figures for CRISPR identifications.

*  **References**:

1.  <https://matplotlib.org/>

2.  Hunter, J. D. (2007). Matplotlib: A 2D Graphics Environment. *Computing in Science & Engineering*, **9**(3), 90?95. [doi:10.1109/MCSE.2007.55](https://github.com/matplotlib/matplotlib)

---

### Stage 8: Advanced Plasmid Hunting with Machine Learning (`plasmid_discovery.nf`)

While we looked for plasmids earlier with traditional methods (in Stage 5), this stage brings in the power of Machine Learning to find even more, including potentially *novel* plasmids that haven't been seen before!

**What `plasmid_discovery.nf` does**:

1.  **Machine Learning for Plasmids**: We use a sophisticated tool called **Platon**. Even though Platon is typically used for shorter DNA reads, it's very capable of identifying plasmids from the long reads we're using.

2.  **Novel Plasmid Discovery**: Platon analyzes your assembled genome, looking for specific protein patterns and other clues that suggest the presence of a plasmid. It can even tell you if an antibiotic resistance gene or virulence gene (which we looked for in Stage 5) is located on a plasmid or on the main bacterial chromosome.

**Important Note & What you can do next**:

*  **Size matters**: Be aware that during the initial DNA preparation in the lab, very small plasmids (less than 10,000 base pairs) might get lost. So, Platon won't be able to find those.

*  **Validation**: If Platon identifies a brand new plasmid, it's exciting! However, the next step would be to confirm its existence and characteristics in a real lab experiment (on the "bench").

**The Tool We Use Here**:

*  **Platon**: A cutting-edge tool that uses machine learning to quickly find and describe plasmids in bacterial genomes. It's especially useful for identifying new plasmids and determining where important genes (like resistance genes) are located.

*  **References**:

1.  <https://github.com/oschwengers/platon>

2.  Schwengers, O., Barth, P., Falgenhauer, L., Hain, T., Chakraborty, T., & Goesmann, A. (2020). Platon: identification and characterization of bacterial plasmid contigs in short-read draft assemblies exploiting protein sequence-based replicon distribution scores. *Microbial Genomics*, **6**(9), 295. [doi:10.1099/mgen.0.000398](https://doi.org/10.1099/mgen.0.000398)

---

### Stage 9: Bringing It All Together: Reports, Figures, and Final Data (`visualization.nf`, `final_report.nf`, `multiqc.nf`)

This is the grand finale! After all the complex analysis, this stage is where BACON gathers all the insights, numbers, and findings from the previous steps and presents them in easy-to-understand reports, beautiful figures, and organized data files.

**What happens in this stage**:

1.  **Interactive Summary Reports**: **MultiQC** plays a crucial role here. It takes all the individual reports generated throughout the pipeline (from quality checks, assemblies, and analyses) and combines them into one interactive, user-friendly HTML report. This single report gives you a quick overview of everything BACON has done.

*  **Important Note**: If a particular section of the report is empty, it just means no relevant results were found for that specific analysis, and the program is designed to only output directories if there's something to put in them.

2.  **Organized Data Files (CSV)**: BACON generates clear and well-structured data files (in CSV format) for each part of the analysis. These are organized in a way that makes it super easy for you to take them to other programs (like R) for even deeper exploration and custom analyses.

3.  **Publication-Ready Figures**: This stage also produces a suite of useful figures. These are not just basic charts; they are designed to be "publication-ready" ? meaning you can use them directly in your scientific papers or presentations with minimal tweaking. Examples include visualizations of contamination (from Kraken2), CRISPRs, genomic alignments, antibiotic resistance and virulence genes, and plasmids.

4.  **Clean Output Directories**: All your final results are neatly organized into easy-to-navigate folders like `figures/`, `tables/`, and `files/`. There's also a comprehensive `raw_outputs/` directory. This is important for "traceability" (you can see exactly where every piece of data came from) and for any custom analyses you might want to perform later that are beyond BACON's direct scope.

**The Tools We Use Here**:

*  **MultiQC**: The ultimate summarizer! It collects all the reports from different tools and creates a single, interactive, easy-to-read web report for a quick overview.

*  **References**:

1.  <https://multiqc.info/>

2.  Ewels, P., Magnusson, M., Lundin, S., & K�ller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, **32**(19), 3047?3049. [doi:10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

*  **R / ggplot2 / Python**: These are powerful programming languages and libraries that BACON uses behind the scenes to create those custom plots, figures, and process data.

*  **References**:

1.  **R**: <https://www.R-project.org/> (A free software environment for statistical computing and graphics.)

2.  **ggplot2**: Wickham H (2016). *ggplot2: Elegant Graphics for Data Analysis*. Springer-Verlag New York. ISBN 978-3-319-24277-4, <https://ggplot2.tidyverse.org/> (A system for declaratively creating graphics, based on The Grammar of Graphics.)

3.  **Tidyverse**: <https://tidyverse.org/blog/2019/11/tidyverse-1-3-0/> (A collection of R packages designed for data science, all sharing a common design philosophy.)

4.  **Python**: <https://docs.python.org/3/reference/index.html> (A popular programming language, often used for data analysis and scripting.)

5.  **Panther**: <https://pmc.ncbi.nlm.nih.gov/articles/PMC6519457/> (A large biological database that classifies proteins and genes to analyze and interpret genomic data.)

6.  **PantherAPI**: <https://cran.r-project.org/web/packages/rbioapi/vignettes/rbioapi_panther.html> (An R package that provides an interface to various bioinformatics web services, including PANTHER.)

---

# Conclusion

You've now walked through the entire BACON pipeline! From initial data preparation to the final reports and figures, BACON automates complex bacterial genome analysis, making it accessible and reproducible. We hope this guide helps you understand each step and confidently use the pipeline for your research. If you have any questions or need further assistance, please don't hesitate to reach out!

# CITING BACON 
[THIS IS WHERE THE PUBLICATION WILL GO]
[THIS IS WHERE REPOSITORY WILL BE POSTED]
