process RUN_PROGRESSIVE_MAUVE {
    tag "Running ProgressiveMauve on ${assemblies.size()} genomes"
    label 'process_high'
    conda 'bioconda::progressivemauve'

    publishDir "${params.outdir}/rawoutputs/whole_genome_alignment/mauve", mode: 'copy'

    input:
    path(assemblies)
    
    output:
    path("*.backbone"), emit: backbone

    script:
    """
    progressiveMauve --output=alignment.xmfa *.fasta
    """
}
 