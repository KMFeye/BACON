process RUN_PANAROO {
    tag "Panaroo pangenome analysis"
    publishDir "${params.outdir}/rawresults/aggregate/pangenome", mode: 'copy'
    conda 'bioconda::panaroo'

    input:
    path(gff_files)
    output:
    path("panaroo_output"), emit: panaroo_dir

    script:
    """    
    num_gffs=\$(ls -1 *.gff 2>/dev/null | wc -l)

    if [ "\$num_gffs" -gt 1 ]; then
        panaroo -i *.gff -o panaroo_output --threads ${task.cpus} --clean-mode strict --aligner mafft
    else
        echo "Only one genome found. Creating empty Panaroo output directory."
        mkdir panaroo_output
        touch panaroo_output/empty_run.txt
    fi
    """
}

process RUN_PYSEER {
    tag "Pyseer LMM-GWAS"
    publishDir "${params.outdir}/figures/pangenome/pyseer", mode: 'copy'
    conda 'bioconda::pyseer'

    input:
    path(panaroo_dir)
    path(traits_file)
    output:
    path("pyseer_output"), emit: pyseer_dir

    script:
    """
    #!/bin/bash
    CORE_GENE_ALIGNMENT="${panaroo_dir}/core_gene_alignment.aln"

    if [ ! -s "\${CORE_GENE_ALIGNMENT}" ]; then
        echo "Core gene alignment not found. Skipping Pyseer analysis."
        mkdir pyseer_output
        touch pyseer_output/skipped_pyseer.txt
        exit 0
    fi

    echo "Core gene alignment found. Running Pyseer."
    mkdir pyseer_output

    pyseer-make-kinship --alignment "\${CORE_GENE_ALIGNMENT}" --output pyseer_output/kinship.matrix

    pyseer --phenotypes ${traits_file} --pres ${panaroo_dir}/gene_presence_absence.Rtab --similarity pyseer_output/kinship.matrix --output-patterns pyseer_output/gene_gwas_results.txt --cpu ${task.cpus}
    """
}



process PLOT_PYSEER_MANHATTAN {
    tag "Plotting Pyseer Manhattan plot"
    publishDir "${params.outdir}/figures/pangenome/pyseer/plots", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-qqman'

    input:
    path(pyseer_results) // The gene_gwas_results.txt file
    output:
    path("*.png")
    path("*.pdf")

    script:
    """
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(qqman)

    gwas_results <- read_tsv("${pyseer_results}", col_types = cols())

    plot_data <- gwas_results %>%
      filter(FILTER == 'PASS') %>%
      mutate(
        SNP = NAME,
        CHR = 1, # Assign all to a single chromosome
        BP = row_number(),
        P = as.numeric(P_VALUE)
      )
      
    if (nrow(plot_data) > 0) {
        png("pyseer_gwas_manhattan.png", width=12, height=7, units="in", res=300)
        manhattan(plot_data, main="Pyseer GWAS Results", logp=TRUE, genomewideline=FALSE, suggestiveline=FALSE)
        dev.off()

        pdf("pyseer_gwas_manhattan.pdf", width=12, height=7)
        manhattan(plot_data, main="Pyseer GWAS Results", logp=TRUE, genomewideline=FALSE, suggestiveline=FALSE)
        dev.off()
    } else {
        # Create empty files if there are no significant results to plot
        file.create("pyseer_gwas_manhattan.png")
        file.create("pyseer_gwas_manhattan.pdf")
    }
    """
}


