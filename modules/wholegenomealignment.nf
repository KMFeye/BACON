process RUN_PROGRESSIVE_MAUVE {
    tag "Running ProgressiveMauve on ${assemblies.size()} genomes"
    label 'process_high'
    conda 'bioconda::progressivemauve'

    publishDir: {"${params.outdir}/rawoutputs/whole_genome_alignment/mauve", mode: 'copy'}

    input:
    path(assemblies)
    output:
    path("alignment.xmfa"), emit: xmfa

    script:
    """
    progressiveMauve --output=alignment.xmfa *.fasta
    """
}

######################switch to html vs. pdf ###########################
process PLOT_GENOME_SYNTENY {
    tag "Generating genome synteny plot"
    label 'process_medium'
    conda 'bioconda::bioconductor-genoplotr'

    publishDir: {"${params.outdir}/figures", mode: 'copy'}

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
