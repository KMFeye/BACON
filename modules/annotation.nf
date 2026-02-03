echo "Starting Annotation"

process BAKTA_ANNOTATION {
    tag "$sample_id"
    input:
    tuple val(sample_id), path(assembly)

    // Add this block!
    publishDir "${params.outdir}/Annotation/BAKTA/${sample_id}", mode: 'copy'

    output:
    tuple val(sample_id), path("${sample_id}.*")

    script:
    """
    bakta ${assembly} --output ${sample_id} --prefix ${sample_id}
    """
}
