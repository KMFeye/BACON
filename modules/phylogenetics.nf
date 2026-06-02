process CREATE_SNP_ALIGNMENT {
    tag "Create Core SNP Alignment"
    errorStrategy 'retry'
    conda 'bioconda::samtools bioconda::htslib bioconda::bcftools'

    publishDir "${params.outdir}/rawresults/phylogenetics", mode: 'copy'

    input:
    path vcfs
    path ref_fasta

    output:
    path("core_snp_alignment.fasta"), emit: alignment
    path("merged.vcf.gz"), emit: merged_vcf

    script:
    """
    samtools faidx ${ref_fasta}
    bcftools merge --force-samples *.vcf.gz -Oz -o merged.vcf.gz
    tabix merged.vcf.gz
    bcftools consensus -f ${ref_fasta} merged.vcf.gz > core_snp_alignment.fasta
    """
}


process BUILD_PHYLO_TREE {
    tag "Build Phylogenetic Tree"
    conda 'bioconda::iqtree'

    publishDir "${params.outdir}/rawresults/aggregate/phylogenetics", mode: 'copy'

    input:
    path(alignment)
    output:
    path("*.treefile"), emit: treefile

    script:
    """
    num_seqs=\$(grep -c '>' ${alignment} || true)
    if [ "\$num_seqs" -gt 1 ]; then
        iqtree2 -s ${alignment} -m MFP -B 1000 --prefix iqtree_out
    else
        echo "Only one sequence in alignment. Creating empty tree file."
        touch iqtree_out.treefile
    fi
    """
}
