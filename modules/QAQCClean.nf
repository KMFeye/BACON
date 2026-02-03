process CLEAN_QAQC {
    tag "FastQC on ${sample_id}"
    label 'process_medium'
    conda 'envs/qaqcClean.yml'
    publishDir "${params.outdir}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    path "*.html", emit: html
    path "*.zip", emit: zip

    script:
    """
    echo -e "\033[38;5;81mStarting FastQC for ${sample_id}\033[0m"
    fastqc -o . "${fastq}"
    echo -e "\033[38;5;81mFastQC for ${sample_id} completed\033[0m"
    """
}
