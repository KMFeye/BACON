process EXTRACT_TARGET_READS {
    tag "Extracting target reads for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::kraken2'

    publishDir "${params.outdir}/rawresults", mode: 'copy', saveAs: { filename -> "${sample_id}/kraken2/${filename}" }

    input:
    tuple val(sample_id), path(reads), path(db_path)

    output:
    tuple val(sample_id), path("${sample_id}.target_reads.fastq.gz"), emit: target_reads

    script:
    """
    kraken2 \
        --db "${db_path}" \
        --threads ${task.cpus} \
        --gzip-compressed \
        --classified-out /dev/stdout \
        --report /dev/null \
        --output /dev/null \
        --include-children \
        --taxa ${params.target_taxid} \
        "${reads}" | gzip -c > "${sample_id}.target_reads.fastq.gz"
    """
}

process GENERATE_CONTAMINATION_REPORT {
    tag "Generating contamination report for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::kraken2'

    publishDir "${params.outdir}/rawresults", mode: 'copy', saveAs: { filename -> "${sample_id}/kraken2/${filename}" }

    input:
    tuple val(sample_id), path(reads), path(db_path)

    output:
    tuple val(sample_id), path("${sample_id}.kraken2_report.txt"), emit: report

    script:
    """
    kraken2 \
        --db "${db_path}" \
        --threads ${task.cpus} \
        --gzip-compressed \
        --report "${sample_id}.kraken2_report.txt" \
        "${reads}" > /dev/null
    """
}

