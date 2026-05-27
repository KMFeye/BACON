process FLYE_ASSEMBLY {
    tag "Flye assembly for ${sample_id} (Attempt ${task.attempt})"
    label 'process_high'
    conda 'bioconda::flye=2.9.1'

    maxRetries 1
    errorStrategy {
        if (task.attempt == 1 && task.exitStatus != 0) {
            println "Flye attempt 1 for ${sample_id} failed. Retrying with --pacbio-raw..."
            return 'retry'
        }
        else {
            println "Flye attempt 2 for ${sample_id} also failed. Ignoring sample."
            return 'ignore'
        }
    }
    
    publishDir "${params.outdir}/rawresults/flye/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)
    output:
    tuple val(sample_id), path("flye_assembly"), emit: assembly_dir
    tuple val(sample_id), path("flye_assembly/assembly.fasta"), emit: assembly_fasta, optional: true

    script:
    def command
    if (task.attempt == 1) {
        command = "flye --pacbio-hifi '${fastq}' --out-dir flye_assembly --threads ${task.cpus}"
    } else {
        command = "flye --pacbio-raw '${fastq}' --out-dir flye_assembly --threads ${task.cpus}"
    }
    """
    echo "Running command: ${command}"
    ${command}
    """
}


process QUAST_REPORT {
    tag "Running QUAST for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::quast'
   
    publishDir "${params.outdir}/rawdata/${sample_id}/quast",
        mode: 'copy',
        pattern: "quast_results/*"
    publishDir "${params.outdir}/tables",
    mode: 'copy',
    pattern: "quast_results/report.tsv",
    saveAs: { "${sample_id}.quast_report.tsv" } 
    
    input:
    tuple val(sample_id), path(assembly)
    output:
    path("quast_results"), emit: quast_report

    script:
    """
    quast.py ${assembly} -o quast_results
    """
}

process BUSCO {
    tag "Busco report for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::busco'
    publishDir "${params.outdir}/tables/bosco", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)
    output:
    tuple val(sample_id), path("busco_output"), emit: busco_report

    script:
    """
    busco -i "${fasta}" -m genome -o busco_output -l bacteria_odb12
    """
}
