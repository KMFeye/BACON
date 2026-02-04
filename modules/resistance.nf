// modules/resistance.nf
// This is the final, corrected version of this module file.

process AMRFINDER_ANALYSIS {
    tag "AMRFinder analysis for ${sample_id}"
    label 'process_medium'
    // CORRECT: Uses the consolidated environment for stable tools.
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)
    output:
    path "${sample_id}_amrfinder.txt", emit: amrfinder_report
    script:
    """
    amrfinder -u
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt"
    """
}

process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    // CORRECT: Uses the consolidated environment for stable tools.
    conda 'envs/resistance.yml'

    input:
    tuple val(sample_id), path(fasta)
    output:
    path "plasmidfinder_output", emit: plasmidfinder_report
    script:
    """
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
