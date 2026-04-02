process CLEAN_QAQC {
    tag "FastQC on ${sample_id} (${publish_dir_name})"
    label 'process_high'
    conda 'bioconda::fastqc=0.11.9'

    publishDir "${params.outdir}/rawresults/${publish_dir_name}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq), val(publish_dir_name)

    output:
    tuple val(sample_id), path("${sample_id}_${publish_dir_name}_fastqc.html"), emit: html
    tuple val(sample_id), path("${sample_id}_${publish_dir_name}_fastqc.zip"), emit: zip

    script:
    """
    export _JAVA_OPTIONS="-Xmx70g"
    fastqc --noextract -o . "${fastq}"

    fastqc_prefix=\$(basename "${fastq}" .gz)
    fastqc_prefix=\${fastqc_prefix%.fastq}

    mv "\${fastqc_prefix}_fastqc.html" "${sample_id}_${publish_dir_name}_fastqc.html"
    mv "\${fastqc_prefix}_fastqc.zip"  "${sample_id}_${publish_dir_name}_fastqc.zip"
    """
}
