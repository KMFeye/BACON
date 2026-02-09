// FINAL, DEFINITIVE, AND CORRECTED VERSION: modules/snp_analysis.nf

process ALIGN_TO_REFERENCE {
    tag "Align reads for ${sample_id} with minimap2"
    label 'process_medium'
    // CORRECTED: Using a direct, explicit Conda directive.
    conda 'bioconda::minimap2=2.24 bioconda::samtools=1.15'
    publishDir "${params.outdir}/snp_analysis/aligned_bams", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)
    path reference_fasta

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: aligned_bam

    script:
    """
    minimap2 -ax map-pb "${reference_fasta}" "${fastq}" | samtools sort -o "${sample_id}.sorted.bam" -
    samtools index "${sample_id}.sorted.bam"
    """
}

process CALL_VARIANTS_BCFTOOLS {
    tag "Call variants for ${sample_id} with bcftools"
    label 'process_medium'
    // CORRECTED: Using a direct, explicit Conda directive.
    conda 'bioconda::samtools=1.15 bioconda::bcftools=1.15'
    publishDir "${params.outdir}/snp_analysis/raw_vcfs/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference_fasta

    output:
    tuple val(sample_id), path("${sample_id}.raw.vcf.gz"), emit: raw_vcf

    script:
    """
    bcftools mpileup -Ou -f "${reference_fasta}" "${bam}" | bcftools call -mv -Oz -o "${sample_id}.raw.vcf.gz"
    """
}

process FILTER_VARIANTS_BCFTOOLS {
    tag "Filter variants for ${sample_id}"
    label 'process_low'
    // CORRECTED: Using a direct, explicit Conda directive.
    conda 'bioconda::bcftools=1.15'
    publishDir "${params.outdir}/snp_analysis/final_vcfs", mode: 'copy'

    input:
    tuple val(sample_id), path(raw_vcf)

    output:
    tuple val(sample_id), path("${sample_id}.filtered.vcf.gz"), emit: filtered_vcf

    script:
    """
    bcftools filter -i 'QUAL > 20' -Oz -o "${sample_id}.filtered.vcf.gz" "${raw_vcf}"
    """
}
