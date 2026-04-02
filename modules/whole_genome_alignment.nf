process RUN_PROGRESSIVE_MAUVE {
    tag "Running ProgressiveMauve on ${assemblies.size()} genomes"
    label 'process_high'
    publishDir "${params.outdir}/rawoutputs/whole_genome_alignment/mauve", mode: 'copy'
    conda 'bioconda::progressivemauve'

    input:
    path(assemblies)

    output:
    path("alignment.xmfa"), emit: xmfa

    script:
    """
    progressiveMauve --output=alignment.xmfa *.fasta
    """
}


process PLOT_GENOME_SYNTENY {
    tag "Generating genome synteny plot"
    label 'process_medium'

    publishDir "${params.outdir}/figures", mode: 'copy'

    conda 'bioconda::bioconductor-genoplotr'

    input:
    path(xmfa)

    output:
    path("genome_synteny_plot.png"), emit: png
    path("genome_synteny_plot.pdf"), emit: pdf

    script:
    """
    #!/usr/bin/env R
    library(genoPlotR)

    dna_segs <- read_dna_seg_from_xmfa("${xmfa}")

    # Prepare comparisons if there's more than one genome
    comparisons <- list()
    if (length(dna_segs) > 1) {
        for(i in 2:length(dna_segs)){
            comparisons[[i-1]] <- comparison(dna_segs[[1]], dna_segs[[i]])
        }
    }

    plot_lims <- lapply(dna_segs, function(seg) c(min(seg\$Start), max(seg\$End)))

    pdf("genome_synteny_plot.pdf", width=12, height=8)
    plot_gene_map(dna_segs=dna_segs,
                  comparisons=comparisons,
                  xlims = plot_lims,
                  main="Whole Genome Synteny Comparison",
                  gene_type="arrows")
    dev.off()

    png("genome_synteny_plot.png", width=12, height=8, units="in", res=300)
    plot_gene_map(dna_segs=dna_segs,
                  comparisons=comparisons,
                  xlims = plot_lims,
                  main="Whole Genome Synteny Comparison",
                  gene_type="arrows")
    dev.off()
    """
}
