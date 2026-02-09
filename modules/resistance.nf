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

    echo "Updating AMRFinderPlus database..."
    amrfinder --update

    # Step 2: Run the analysis. By REMOVING the '-d' flag, we tell amrfinder
    # to use the default database that it just successfully downloaded.
    echo "Running AMRFinder analysis..."
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt"
}

process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::plasmidfinder bioconda::kma conda-forge::git conda-forge::python=3.9'

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

// In: modules/resistance.nf

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
    conda 'bioconda::abricate>=1.0.1'

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
