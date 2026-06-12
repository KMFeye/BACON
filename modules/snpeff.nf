process SNPEFF_ANNOTATE {
    tag "Annotate variants for ${sample_id} with SnpEff"
    label 'process_medium'
    conda 'bioconda::snpeff=5.1d bioconda::htslib'
    
    publishDir "${params.outdir}/rawresults/variant_annotation/annotated_vcfs", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf), path(tbi)
    path snpeff_config
    path snpeff_db_dir
    val ref_genome_name

    output:
    tuple val(sample_id), path("*.vcf.gz"), emit: annotated_vcf
    tuple val(sample_id), path("snpEff_summary.html"), emit: summary_html
    tuple val(sample_id), path("snpEff_summary.csv"), emit: summary_csv

    script:
    """
    snpEff ann -v \\
        -stats snpEff_summary.html \\
        -csvStats snpEff_summary.csv \\
        -config snpEff.config \\
        -dataDir data \\
        bacterial_ref \\
        ${vcf} | bgzip -c > "${sample_id}.ann.vcf.gz"
    """
}
