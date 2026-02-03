echo "Converting BAM to FASTQ and decontaminating human reads with Minimap2"

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

process MINIMAP2_DECONTAMINATE {
    tag "Decontaminating ${sample_id} with minimap2"
    label 'process_high'
    conda 'bioconda::minimap2 bioconda::samtools=1.19.2 conda-forge::pigz'

    input:
    tuple val(sample_id), path(raw_fastq)
    path human_ref_fasta

    output:
    tuple val(sample_id), path("${sample_id}.cleaned.fastq.gz"), emit: cleaned_fastq

    script:
    """
    zcat ${raw_fastq} | \\
    minimap2 -ax map-pb -t ${task.cpus} ${human_ref_fasta} - | \\
    samtools view -b -f 4 -@ ${task.cpus} - | \\
    samtools fastq -@ ${task.cpus} - | \\
    pigz > ${sample_id}.cleaned.fastq.gz
    """
}
