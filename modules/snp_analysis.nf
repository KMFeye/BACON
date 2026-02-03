echo "Let's get some good SNP Analyses completed"

process ALIGN_TO_REFERENCE {
    tag "Align reads for ${sample_id} with minimap2"
    label 'process_medium'
    conda 'envs/snpAnalysis.yml'
    publishDir "${params.outdir}/snp_analysis/aligned_bams", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)
    path reference_fasta

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: aligned_bam

    script:
    """
    minimap2 -ax sr "${reference_fasta}" "${fastq}" | samtools sort -o "${sample_id}.sorted.bam" -
    samtools index "${sample_id}.sorted.bam"
    """
}

process CALL_VARIANTS_BCFTOOLS {
    tag "Call variants for ${sample_id} with bcftools"
    label 'process_medium'
    conda 'envs/snpAnalysis.yml'

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
    conda 'envs/snpAnalysis.yml'
    publishDir "${params.outdir}/snp_analysis/final_vcfs", mode: 'copy'

    input:
    tuple val(sample_id), path(raw_vcf)

    output:
    tuple val(sample_id), path("${sample_id}.filtered.vcf.gz"), emit: filtered_vcf

    script:
    // This is a basic filter. It keeps variants with a quality score > 20.
    """
    bcftools filter -i 'QUAL > 20' -Oz -o "${sample_id}.filtered.vcf.gz" "${raw_vcf}"
    """
}
