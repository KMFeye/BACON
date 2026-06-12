process RUN_PLATON {
    tag "Platon plasmid prediction for ${sample_id}"
    label 'process_medium' // Added a label for consistency
    conda 'bioconda::platon'

    publishDir "${params.outdir}/rawresults/platon", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(assembly_fasta)

    output:
    tuple val(sample_id), path("*.fasta"), emit: plasmid_fasta
    tuple val(sample_id), path("*.tsv"), emit: platon_tsv

    script:
    """
    platon "${assembly_fasta}" --output "${sample_id}_platon_results" --db "${params.platon_db}" --threads ${task.cpus}

    # Check for the output files and copy them to the main directory for capture
    if [ -f "${sample_id}_platon_results/${sample_id}.platon.fasta" ]; then
        cp "${sample_id}_platon_results/${sample_id}.platon.fasta" "${sample_id}.platon_plasmids.fasta"
    else
        touch "${sample_id}.platon_plasmids.fasta"
    fi
    
    if [ -f "${sample_id}_platon_results/${sample_id}.platon.tsv" ]; then
        cp "${sample_id}_platon_results/${sample_id}.platon.tsv" "${sample_id}.platon.tsv"
    else
        touch "${sample_id}.platon.tsv"
    fi
    """
}
