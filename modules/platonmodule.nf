process RUN_PLATON {
    tag "Platon plasmid prediction for ${assembly_fasta.baseName}"
    memory '16.GB'
    conda 'bioconda::platon'

    publishDir: {"${params.outdir}/rawresults/plasmid_discovery/platon/${sample_id}", mode: 'copy'}

    input:
    tuple val(sample_id), path(assembly_fasta)
    output:
    tuple val(sample_id), path("${sample_id}.platon_plasmids.fasta"), emit: plasmid_fasta
    tuple val(sample_id), path("${sample_id}.platon.tsv"), emit: report

    script:
    """
    platon ${assembly_fasta} --output ${sample_id}.platon --db ${params.platon_db} --threads ${task.cpus}

    if [ -f "${sample_id}.platon/${sample_id}.platon.fasta" ]; then
        cp ${sample_id}.platon/${sample_id}.platon.fasta ${sample_id}.platon_plasmids.fasta
    else
        touch ${sample_id}.platon_plasmids.fasta
    fi
    
    if [ -f "${sample_id}.platon/${sample_id}.platon.tsv" ]; then
        cp ${sample_id}.platon/${sample_id}.platon.tsv ${sample_id}.platon.tsv
    else
        touch ${sample_id}.platon.tsv
    fi
    """
}
