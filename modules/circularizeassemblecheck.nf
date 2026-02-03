process FLYE_ASSEMBLY {
    tag "Flye assembly for ${sample_id}"
    label 'process_high'
    conda 'envs/flyeAssembly.yml'
    publishDir "${params.outdir}/flye/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("flye_assembly/assembly.fasta"), emit: assembly_fasta
    path "flye_assembly", emit: assembly_dir

    script:
    """
    echo -e "\033[38;5;81mStarting Flye assembly for ${sample_id}\033[0m"
    flye --nano-raw "${fastq}" --out-dir "flye_assembly"
    echo -e "\033[38;5;81mFlye assembly for ${sample_id} completed\033[0m"
    """
}

process QUAST_REPORT {
    tag "QUAST report for ${sample_id}"
    label 'process_medium'
    conda 'envs/quastReport.yml'
    publishDir "${params.outdir}/quast/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(assembly_fasta)

    output:
    path "quast_output", emit: quast_report

    script:
    """
    echo -e "\033[38;5;81mStarting QUAST report for ${sample_id}\033[0m"
    quast -o "quast_output" "${assembly_fasta}"
    echo -e "\033[38;5;81mQUAST report for ${sample_id} completed\033[0m"
    """
}
