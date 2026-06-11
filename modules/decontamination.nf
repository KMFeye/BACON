process EXTRACT_TARGET_READS {
    tag "Extracting target reads for ${sample_id}"
    label 'process_medium'
    memory '16 GB' 
    cpus 4

    conda 'bioconda::kraken2 bioconda::krakentools'

    publishDir "${params.outdir}/rawresults", mode: 'copy', saveAs: { filename -> "${sample_id}/kraken2/${filename}" }

    input:
    tuple val(sample_id), path(reads), path(db_path)

    output:
    tuple val(sample_id), path("${sample_id}.target_reads.fastq.gz"), emit: target_reads

    script:
    """
    kraken2 \\
        --db "${db_path}" \\
        --threads ${task.cpus} \\
        --gzip-compressed \\
        --memory-mapping \\
        --output "${sample_id}.kraken2_output.txt" \\
        --report "${sample_id}.kraken_report.txt" \\
        "${reads}"

    extract_kraken_reads.py \\
        -k "${sample_id}.kraken2_output.txt" \\
        -s "${reads}" \\
        -t ${params.target_taxid} \\
        --include-children \\
        -r "${sample_id}.kraken_report.txt" \\
        --fastq-output \\
        -o "${sample_id}.target_reads.fastq"

    gzip "${sample_id}.target_reads.fastq"
    """
}


 
process GENERATE_CONTAMINATION_REPORT {
    tag "Generating contamination report for ${sample_id}"
    label 'process_medium'
    memory '16 GB' 
    cpus 4
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