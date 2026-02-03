
process CRISPR_TYPING {
    tag "CRISPR typing for ${sample_id}"
    label 'process_medium'
    // Uses its new, dedicated environment file
    conda 'envs/other_analysis.yml'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "crispr_output", emit: crispr_dir

    script:
    """
    # This command correctly uses positional arguments instead of flags.
    cctyper \\
        "${fasta}" \\
        crispr_output \\
        --threads ${task.cpus}
    """
}
