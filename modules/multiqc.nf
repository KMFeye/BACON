process MULTIQC {
    tag "Aggregating QC reports"
    label 'process_low'
    
    conda 'bioconda::multiqc=1.14 conda-forge::python=3.9'

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path '*' // This tells MultiQC to scan all input files and directories.

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data", emit: data

    script:
    """
    multiqc .
    """
}
