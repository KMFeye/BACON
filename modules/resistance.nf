process AMRFINDER_ANALYSIS {
    tag "AMRFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::ncbi-amrfinderplus'

    publishDir "${params.outdir}/tables/amrfinder", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)
    path amrfinder_ready_signal // This now takes the signal file
    output:
    tuple val(sample_id), path("${sample_id}_amrfinder.txt"), emit: amrfinder_report

    script:
    """
    amrfinder -n "${fasta}" -o "${sample_id}_amrfinder.txt" --plus 
    """
}


process PLASMIDFINDER_ANALYSIS {
    tag "PlasmidFinder analysis for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::plasmidfinder'
    
    publishDir "${params.outdir}/tables/plasmidfinder", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta), path(plasmidfinder_db)
    output:
    tuple val(sample_id), path("plasmidfinder_output"), emit: plasmidfinder_report

    script:
    """
    mkdir -p plasmidfinder_output
    plasmidfinder.py -i "${fasta}" -o "plasmidfinder_output" -p "${plasmidfinder_db}"
    """
}


process MOB_SUITE_ANALYSIS {
    tag "MOB-suite analysis for ${sample_id}"
    label 'process_medium'
    conda "${System.getenv('HOME')}/miniconda3/envs/mobsuite_env" 
    
    publishDir "${params.outdir}/tables/mobsuite", mode: 'copy'

    input: tuple val(sample_id), path(fasta)
    output: tuple val(sample_id), path("mobsuite_output"), emit: mobsuite_report
    
    script: 
    """
    mob_recon -i '${fasta}' -o mobsuite_output
    """
}

process RUN_ABRICATE {
    tag "Screening ${sample_id} with ABRicate"
    label 'process_medium'
    conda 'bioconda::abricate'
    publishDir "${params.outdir}/rawresults/resistance", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("${sample_id}_abricate_report.tsv"), emit: report

    script:
    """
    #!/bin/bash
   
    echo "Running ABRicate with default database..."
    
    abricate --threads ${task.cpus} "${fasta}" > "${sample_id}_abricate_report.tsv"
    """
}
