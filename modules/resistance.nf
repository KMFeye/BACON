process AMRFINDER_ANALYSIS {
    tag "AMRFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::ncbi-amrfinderplus conda-forge::wget'

    publishDir "${params.outdir}/${sample_id}/amrfinder", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("${sample_id}_amrfinder.txt"), emit: amrfinder_report

    script:
    """
    echo "Updating AMRFinderPlus database..."
    amrfinder --update
    echo "Running AMRFinder analysis..."
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt"
    """
}

process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::plasmidfinder bioconda::kma conda-forge::git conda-forge::python=3.9'

    publishDir "${params.outdir}/${sample_id}/plasmidfinder", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("plasmidfinder_output"), emit: plasmidfinder_report

    script:
    """
    echo "Cloning PlasmidFinder database..."
    git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git
    cd plasmidfinder_db
    echo "Indexing PlasmidFinder database..."
    python3 INSTALL.py kma_index
    cd ..
    mkdir plasmidfinder_output
    plasmidfinder.py -i "${fasta}" -o "plasmidfinder_output" -p plasmidfinder_db
    """
}

process MOB_SUITE_ANALYSIS {
    tag "MOB-suite analysis for ${sample_id}"
    label 'process_med'
    conda "$HOME/miniconda3/envs/mobsuite_env"

    publishDir "${params.outdir}/${sample_id}/mobsuite", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("mobsuite_output"), emit: mobsuite_report

    script:
    """
    mob_recon -i "${fasta}" -o "mobsuite_output"
    """
}

process RUN_ABRICATE {
    tag "Screening ${sample_id} with ABRicate"
    label 'process_medium'
    conda 'bioconda::abricate>=1.0.1'

    publishDir "${params.outdir}/${sample_id}/abricate", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("abricate_report.tsv"), emit: report

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
