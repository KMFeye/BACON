# C3PacBio
Pacbio Nextflow for Unaligned Sequences Using a Non-SCRUM Computing System

This is your pipeline for unaligned PACBIO bam files using either a local workstation or your favorite cloud computing system.  Adjust the workflow
accordingly.  The program is automated. 

Part 1: Introduction
--------------------

Congratulations! You?re about to run an automated analysis pipeline on PrecisionFDA. This guide will walk you through every step of the process.

This program is named PacBio3P0. It is designed to take your high-quality PacBio HiFi BAM files and perform a complete genomic analysis.

When you see text indented like this:

    this is a command

...it is a command that you should type or paste directly into the terminal window on your PrecisionFDA workstation.

Let?s begin!

Part 2: Before You Start - The Checklist
---------------------------------------

Please make sure you have these four things ready:

1.  A PrecisionFDA Account with enough funds for a long job (120 hours is a safe amount).
2.  A "High Disk" Workstation (at least 500 GB).
3.  Your PacBio HiFi BAM files uploaded to a folder in your PrecisionFDA project.
4.  The pipeline code folder also uploaded to your PrecisionFDA project.
5.  Run setup.sh and check to ensure your DB is accessible
6.  Make sure you have EVERYTHING needed to process your data (genome size, reference sequences, ect.) and edit the documents appropriately 
If you need help, please contact me directly.

Part 3: The Setup Process (Do This Once Per Workstation)
-------------------------------------------------------

This section guides you through setting up your workstation.

Step 1: Launch Your Workstation

*   Log in to the PrecisionFDA website.
*   Launch a new "High Disk" VM.
*   When prompted for the runtime, choose 122 hours.
*   Wait for the workstation to be ready, then open a terminal.

Step 2: Download Your Data and the Pipeline Code

*   Run these commands in the terminal.

    cd ~/Desktop
    mkdir my_pipeline_run
    cd my_pipeline_run
    mkdir inputs

*   Download your BAM files. This can take many hours. Replace "/path/to/your/bams" with your actual folder path.

    pfda download --folder /path/to/your/bams

*   Download the pipeline code. Replace "/path/to/pipeline/code" with your actual folder path.

    pfda download --folder /path/to/pipeline/code --recursive

Step 3: Run the Automated Setup Script

This script installs all necessary software and databases. This can also take several hours.

*   First, make the script executable:

    chmod +x setup.sh

*   Now, run the script:

    ./setup.sh

Once this finishes without errors, your workstation is ready.

Part 4: Running Your Analysis
-----------------------------

Step 1: Run a Quick Test (Highly Recommended)

This test should finish in less than 5 minutes and confirms your setup is working.

*   Refresh your terminal's environment:

    source ~/.bashrc

*   Run the pipeline with the "test" profile:

    nextflow run main.nf -profile test

If this completes successfully, you are ready for the main analysis.

Step 2: Run the Full Analysis on Your Data

You must provide three key pieces of information in the command.

*   --input: The path to your BAM files. This will be 'inputs_bam/*.bam'.
*   --species_name: The scientific name of your bacterium (e.g., "Citrobacter freundii").
*   --genome_size: The estimated genome size (e.g., '5.2m').

Here is the full command. Copy it, but be sure to change the species name and genome size.

    nextflow run main.nf -resume --input_bam 'inputs/*.bam' --species_name "Citrobacter freundii" --genome_size '5.2m'

The "-resume" part is very important. If your run is interrupted, you can use this exact same command to pick up where you left off.

Part 5: What to Expect
----------------------

*   You will see a random two-word name appear for your run (like `angry_hilbert`). This is normal.
*   A single file can take 4-9 hours. A batch of 50 files can take over two weeks. This is expected.
*   A folder named "results" will be created containing all your final output files.

If you see a red ERROR message, please copy the entire message and contact me for help. Do not delete any files. Good luck!
