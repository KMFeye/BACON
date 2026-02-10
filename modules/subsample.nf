process SUBSAMPLE_RASUSA {
    tag "Subsampling ${sample_id} with Rasusa"
    label 'process_low'
    conda 'bioconda::rasusa=0.7.0'

    publishDir "${params.outdir}/${sample_id}/rasusa", mode: 'copy', pattern: "*.rasusa_stats.txt"

    input:
    tuple val(sample_id), path(fastq_in)

    output:
    tuple val(sample_id), path("${sample_id}.subsampled.fastq"), emit: rasusa_fastq
    tuple val(sample_id), path("${sample_id}.rasusa_stats.txt"), emit: rasusa_stats

    script:
    """
    rasusa \\
        -c ${params.coverage} \\
        -g ${params.genome_size} \\
        -i ${fastq_in} > ${sample_id}.subsampled.fastq 2> ${sample_id}.rasusa_stats.txt
    """
}
