
// This module now only contains the main genome annotation process.

echo "Starting Annotation"

process BAKTA_ANNOTATION {
    tag "Bakta annotation for ${sample_id}"
    label 'process_high'
    // Use the new, dedicated environment file
    conda 'envs/annotation.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("bakta_output"), emit: bakta_report

    script:
    """
    # This process correctly uses the pre-downloaded database path from nextflow.config
    bakta --db ${params.bakta_db} --output "bakta_output" "${fasta}"
    """
}
