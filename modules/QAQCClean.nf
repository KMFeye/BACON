process CLEAN_QAQC {
    tag "FastQC on ${sample_id}"
    label 'process_high'
    conda 'envs/qaqcClean.yml'

    publishDir "${params.outdir}/qc/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    path "fastqc/*.html", emit: html
    path "fastqc/*.zip", emit: zip

    script:
    """
    export _JAVA_OPTIONS="-Xmx70g"

    mkdir fastqc
    fastqc --noextract -o fastqc "${fastq}"
    """
}
