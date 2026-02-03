echo "Begin AMR/Virulence Resistance Analysis"

process AMRFINDER_ANALYSIS {
    tag "AMRFinder analysis for ${sample_id}"
    label 'process_medium'
    // Uses the new, consolidated resistance environment
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "${sample_id}_amrfinder.txt", emit: amrfinder_report

    script:
    """
    # This process is self-sufficient and downloads its own database.
    amrfinder -u
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt"
    """
}

process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    // Uses the new, consolidated resistance environment
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "plasmidfinder_output", emit: plasmidfinder_report

    script:
    """
    # This process requires the output directory to be created first.
    mkdir plasmidfinder_output
    plasmidfinder.py -i "${fasta}" -o "plasmidfinder_output"
    """
}

process MOB_SUITE_ANALYSIS {
    tag "MOB-suite analysis for ${sample_id}"
    label 'process_medium'
    // This is our special case and MUST use the pre-built named environment.
    conda 'mobsuite_env'

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
    // Uses the new, consolidated resistance environment
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "abricate_report.tsv", emit: report

    script:
    """
    # This process is self-sufficient and downloads its required databases.
    abricate-get_db --db card
    abricate-get_db --db vfdb
    
    # It runs explicitly for each database and combines the results.
    abricate --db vfdb --threads ${task.cpus} "${fasta}" > abricate_vfdb.tsv
    abricate --db card --threads ${task.cpus} "${fasta}" > abricate_card.tsv
    
    head -n 1 abricate_vfdb.tsv > abricate_report.tsv
    tail -n +2 abricate_vfdb.tsv >> abricate_report.tsv
    tail -n +2 abricate_card.tsv >> abricate_report.tsv
    """
}
