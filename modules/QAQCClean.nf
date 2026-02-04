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
    # --- THIS IS THE FINAL, DEFINITIVE FIX ---
    # We are explicitly setting the Java max heap size (-Xmx) to 70g.
    # This tells the JVM to use up to 70GB of the 80GB allocated to this process,
    export _JAVA_OPTIONS="-Xmx70g"

    mkdir fastqc
    fastqc --noextract -o fastqc "${fastq}"
    """
}
