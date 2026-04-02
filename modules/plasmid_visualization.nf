process PLOT_PLASMID_MAPS {
    tag "Plotting plasmid map for $fasta.baseName"
    publishDir "${params.outdir}/figures/plasmid_maps", mode: 'copy'
    memory = '8.GB'

    input:
    path(fasta) // A single .gplas_plasmids.fasta file

    output:
    path("*.png"), emit: plot_png
    path("*.pdf"), emit: plot_pdf
    path("bakta/*.gff3"), emit: annotations

    script:
    def prefix = fasta.baseName.replaceAll('.gplas_plasmids', '')

    """
    # 1. First, annotate the newly discovered plasmid(s) with Bakta
    bakta --db /path/to/bakta/db/ --output bakta ${fasta} --prefix ${prefix}

    # 2. Now, create a circular plot using the plasmid sequence and its new annotation
    plot_plasmid.R \
        --fasta ${fasta} \
        --gff bakta/${prefix}.gff3 \
        --prefix ${prefix}
    """
}
