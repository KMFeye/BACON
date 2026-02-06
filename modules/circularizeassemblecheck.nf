process FLYE_ASSEMBLY {
    tag "Flye assembly for ${sample_id}"
    label 'process_high'
    
    // --- THIS IS THE KEY FIX ---
    // We are abandoning the .yml file and creating a clean, explicit environment.
    // By specifying the python version, we help the conda solver make better choices.
    conda 'bioconda::flye=2.9.1 conda-forge::python=3.9'

    publishDir "${params.outdir}/flye/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("flye_assembly/assembly.fasta"), emit: assembly_fasta
    path "flye_assembly", emit: assembly_dir

    script:
    """
    echo -e "\\033[38;5;81mStarting Flye assembly for ${sample_id}\\033[0m"
    
    flye --pacbio-hifi "${fastq}" --out-dir "flye_assembly" --threads ${task.cpus}

    echo -e "\\033[38;5;81mFlye assembly for ${sample_id} completed\\033[0m"
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
