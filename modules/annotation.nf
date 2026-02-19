process BAKTA_ANNOTATION {
    tag "Bakta annotation for ${sample_id}"
    label 'process_high'
    conda 'bioconda::bakta'

    publishDir "${params.outdir}/${sample_id}/bakta", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("${sample_id}.gff3"), emit: gff_file
    tuple val(sample_id), path("bakta_output"), emit: bakta_report

    script:
    // This is the fix: It now uses the 'params.bakta_db' value
    // from your nextflow.config file.
    """
    bakta --db ${params.bakta_db} --output bakta_output --prefix ${sample_id} ${fasta}
    
    cp bakta_output/${sample_id}.gff3 .
    """
}
