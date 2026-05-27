process BAM_TO_FASTQ {
    tag "BAM to FASTQ for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::samtools=1.19.2 conda-forge::pigz'

    input:
    tuple val(sample_id), path(unaligned_bam)

    output:
    tuple val(sample_id), path("${sample_id}.raw.fastq.gz"), emit: raw_fastq

    script:
    """
    samtools fastq -@ ${task.cpus} ${unaligned_bam} | pigz > "${sample_id}.raw.fastq.gz"
    """
}

