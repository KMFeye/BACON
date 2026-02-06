process AMRFINDER_ANALYSIS {
    tag "AMRFinder analysis for ${sample_id}"
    label 'process_medium'
    // The environment needs wget now. We'll add it to the yml file later.
    // For now, let's define it here to be certain.
    conda 'bioconda::ncbi-amrfinderplus conda-forge::wget'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "${sample_id}_amrfinder.txt", emit: amrfinder_report

    script:
    """
    echo "Downloading AMRFinderPlus database manually..."
    wget --no-check-certificate -O amrfinderplus.tar.gz "https://ftp.ncbi.nlm.nih.gov/pathogen/Antimicrobial_resistance/AMRFinderPlus/database/latest/amrfinderplus.tar.gz"
    mkdir amr_db
    tar -xzf amrfinderplus.tar.gz -C amr_db
    echo "Running AMRFinder analysis..."
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt" -d amr_db/latest
    """
}

process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "plasmidfinder_output", emit: plasmidfinder_report

    script:
    """
    # --- THIS IS THE FINAL, CORRECTED SCRIPT ---

    # Step 1: Clone the database repository.
    echo "Cloning PlasmidFinder database..."
    git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git

    # Step 2: Change into the database directory before running the installer.
    # THIS IS THE CRITICAL FIX.
    cd plasmidfinder_db

    # Step 3: Run the database installation script from within its own folder.
    echo "Indexing PlasmidFinder database..."
    python3 INSTALL.py kma_index
    
    # Step 4: Change back to the main work directory before running the analysis.
    cd ..

    # Step 5: Create the output directory.
    mkdir plasmidfinder_output

    # Step 6: Run the analysis, pointing to the database we just prepared.
    plasmidfinder.py -i "${fasta}" -o "plasmidfinder_output" -p plasmidfinder_db
    """
}


process MOB_SUITE_ANALYSIS {
    tag "MOB-suite analysis for ${sample_id}"
    label 'process_med'
    conda "$HOME/miniconda3/envs/mobsuite_env"

    input:
    tuple val(sample_id), path(fasta)
    output:
    path "mobsuite_output", emit: mobsuite_report
    script:
    """
    mob_recon -i "${fasta}" -o "mobsuite_output"
    """
}

process RUN_ABRICATE {
    tag "Screening ${sample_id} with ABRicate"
    label 'process_medium'
    // CORRECT: Uses the consolidated environment for stable tools.
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)
    output:
    path "abricate_report.tsv", emit: report
    script:
    """
    abricate-get_db --db card
    abricate-get_db --db vfdb
    abricate --db vfdb --threads ${task.cpus} "${fasta}" > abricate_vfdb.tsv
    abricate --db card --threads ${task.cpus} "${fasta}" > abricate_card.tsv
    head -n 1 abricate_vfdb.tsv > abricate_report.tsv
    tail -n +2 abricate_vfdb.tsv >> abricate_report.tsv
    tail -n +2 abricate_card.tsv >> abricate_report.tsv
    """
}
