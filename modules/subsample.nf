process SUBSAMPLE_RASUSA {
    label 'process_low'
    conda 'bioconda::rasusa=0.7.0'

    input:
    tuple val(sample_id), path(fastq_in)

    output:
    tuple val(sample_id), path("${sample_id}.subsampled.fastq"), emit: rasusa_fastq
    // --- THIS IS THE CRITICAL FIX ---
    // This new output channel makes the 'rasusa_stats' file available to the workflow.
    tuple val(sample_id), path("${sample_id}.rasusa_stats.txt"), emit: rasusa_stats

    script:
    """
    # --- THIS IS THE CRITICAL FIX ---
    # The `2>` operator redirects the statistics (which rasusa prints to standard error)
    # into a text file, capturing the information we need.
    rasusa \\
        -c ${params.coverage} \\
        -g ${params.genome_size} \\
        -i ${fastq_in} > ${sample_id}.subsampled.fastq 2> ${sample_id}.rasusa_stats.txt
    """
}
