// In: modules/other_analysis.nf (or wherever CRISPR_TYPING is)

process CRISPR_TYPING {
    tag "CRISPR typing for ${sample_id}"
    label 'process_medium'
    
    // --- THIS IS THE KEY FIX ---
    // We are abandoning the simple directive and creating a clean, explicit environment.
    // By specifying the python version, we help the conda solver make better choices.
    conda 'bioconda::cctyper conda-forge::python=3.9'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path "crispr_output", emit: crispr_dir

    script:
    """
    # This command is already correct and uses positional arguments.
    cctyper \\
        "${fasta}" \\
        crispr_output \\
        --threads ${task.cpus}
    """
}
