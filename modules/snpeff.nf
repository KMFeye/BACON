process SNPEFF_ANNOTATE {
    tag "Annotate variants for ${sample_id} with SnpEff"
    label 'process_medium'
    conda 'bioconda::snpeff=5.1d bioconda::htslib'
    
    publishDir "${params.outdir}/rawresults/variant_annotation/annotated_vcfs", mode: 'copy'

    input:
    tuple val(sample_id), path(vcf), path(snpeff_config), path(snpeff_db_dir)
    output:
    tuple val(sample_id), path("${sample_id}.ann.vcf.gz"), emit: annotated_vcf
    path "snpEff_summary.genes.txt", emit: genes_report
    path "snpEff_summary.html", emit: summary_report

    script:
    def genome_id = sample_id
    """
    snpEff ann -v -stats snpEff_summary.html -config ${snpeff_config} -dataDir ${snpeff_db_dir} ${genome_id} ${vcf} | bgzip -c > "${sample_id}.ann.vcf.gz"
    """
}

