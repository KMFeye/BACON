process SUBSAMPLE_RASUSA {
    label 'process_low'
    conda 'bioconda::rasusa=0.7.0'

    input:
    tuple val(sample_id), path(fastq_in)

    output:
    tuple val(sample_id), path("${sample_id}.subsampled.fastq"), emit: rasusa_fastq

    script:
    """
    rasusa \\
        -c ${params.coverage} \\
        -g ${params.genome_size} \\
	-i ${fastq_in} > ${sample_id}.subsampled.fastq
    """
}
