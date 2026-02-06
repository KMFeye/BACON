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
    // This environment is correct.
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "plasmidfinder_output", emit: plasmidfinder_report

    script:
    """
    echo "Downloading PlasmidFinder database..."
    download_plasmidfinder_db.sh -d .
    mkdir plasmidfinder_output
    plasmidfinder.py -i "${fasta}" -o "plasmidfinder_output"
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
