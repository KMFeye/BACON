process BAKTA_ANNOTATION {
    tag "Bakta annotation for ${sample_id}"
    label 'process_high'
    // This explicit conda directive is the most robust solution for your system.
    conda 'bioconda::bakta conda-forge::python=3.9'
    publishDir "${params.outdir}/bakta/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    // --- THIS IS THE CRITICAL FIX ---
    // The `emit: bakta_report` part creates the named channel that main.nf is looking for.
    tuple val(sample_id), path("bakta_output"), emit: bakta_report

    script:
    """
    # This correctly uses the pre-downloaded database path from nextflow.config
    bakta --db ${params.bakta_db} --output "bakta_output" "${fasta}" --threads ${task.cpus}
    """
}
