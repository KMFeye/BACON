process CRISPR_TYPING {
    tag "CRISPR typing for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::cctyper conda-forge::python=3.9'

    publishDir "${params.outdir}/${sample_id}/crispr", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    // Ensures the output is a tuple for the join
    tuple val(sample_id), path("crispr_output"), emit: crispr_dir

    script:
    """
    cctyper "${fasta}" crispr_output
    """
}
