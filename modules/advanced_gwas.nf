process RUN_PANAROO {
    tag "Panaroo pangenome analysis on ${gff_files.size()} genomes"
    publishDir "${params.outdir}/rawresults/pangenome/panaroo", mode: 'copy'

    cpus = 16
    memory = '64.GB'
    time = '12.h'

    input:
    path(gff_files) 

    output:
    path("panaroo_output"), emit: panaroo_dir

    script:
    """
    panaroo \
        -i *.gff3 \
        -o panaroo_output \
        --threads ${task.cpus} \
        --clean-mode strict \
        --aligner mafft
    """
}

/**
 * 2. Runs Pyseer, a powerful linear mixed model GWAS tool.
 * This requires a kinship/similarity matrix to control for population structure.
 * We will generate it from Panaroo's core gene alignment.
 */
process RUN_PYSEER {
    tag "Pyseer LMM-GWAS"
    publishDir "${params.outdir}/rawresults/pangenome/pyseer", mode: 'copy'

    input:
    path(panaroo_dir)
    path(traits_file) 

    output:
    path("pyseer_output"), emit: pyseer_dir

    script:
    """
    # Pyseer step-by-step
    mkdir pyseer_output

    # A) Generate the kinship matrix from Panaroo's core genome alignment
    #    This is the key to controlling for population structure.
    pyseer-make-kinship \
        --alignment ${panaroo_dir}/core_gene_alignment.aln \
        --output pyseer_output/kinship.matrix

    # B) Run the GWAS on the gene presence/absence data
    pyseer \
        --phenotypes ${traits_file} \
        --pres ${panaroo_dir}/gene_presence_absence.Rtab \
        --similarity pyseer_output/kinship.matrix \
        --output-patterns pyseer_output/gene_gwas_results.txt \
        --cpu ${task.cpus}
    """
}


process PLOT_PYSEER_MANHATTAN {
    tag "Plotting Pyseer Manhattan plot"
    publishDir "${params.outdir}/figures", mode: 'copy' 

    input:
    path(pyseer_results) // The gene_gwas_results.txt file

    output:
    path("*.png")
    path("*.pdf")

    script:
    """
    plot_pyseer.R \
        --input ${pyseer_results} \
        --prefix "pyseer_gwas_manhattan"
    """
}
