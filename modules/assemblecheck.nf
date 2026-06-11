process FLYE_ASSEMBLY {
    tag "Flye assembly for ${sample_id} (Attempt ${task.attempt})"
    label 'process_high'
    conda 'bioconda::flye=2.9.1'
    maxRetries 2

    errorStrategy {
        if (task.attempt < 3 && task.exitStatus != 0) {
            println "Flye attempt ${task.attempt} for ${sample_id} failed. Retrying with next read type..."
            return 'retry'
        } else {
            println "CRITICAL: All Flye assembly attempts failed for ${sample_id}. See logs."
            return 'finish'
        }
    }

    publishDir "${params.outdir}/rawresults/flye", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("${sample_id}_assembly.fasta"), emit: assembly_fasta
    tuple val(sample_id), path("flye_assembly"), emit: assembly_dir

    script:
    """
    #!/bin/bash
    set -e -o pipefail

    case "${task.attempt}" in
        1)
            echo "Running Flye attempt 1 with --pacbio-hifi..."
            flye --pacbio-hifi "${fastq}" --out-dir flye_assembly --threads ${task.cpus} -g ${params.genome_size}
            ;;
        2)
            echo "Running Flye attempt 2 with --pacbio-corr..."
            flye --pacbio-corr "${fastq}" --out-dir flye_assembly --threads ${task.cpus} -g ${params.genome_size}
            ;;
        3)
            echo "Running Flye attempt 3 with --pacbio-raw..."
            flye --pacbio-raw "${fastq}" --out-dir flye_assembly --threads ${task.cpus} -g ${params.genome_size}
            ;;
    esac

    if [ -f "flye_assembly/assembly.fasta" ]; then
        mv flye_assembly/assembly.fasta "${sample_id}_assembly.fasta"
    fi

    if [ ! -s "${sample_id}_assembly.fasta" ]; then
        echo "CRITICAL ERROR: Flye attempt ${task.attempt} finished, but the final assembly file is missing or empty."
        exit 1
    fi
    """
}


process QUAST_REPORT {
    tag "Running QUAST for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::quast'

    publishDir "${params.outdir}/rawresults/quast", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("${sample_id}_quast_results"), emit: quast_report

    script:
    """
    quast.py "${assembly}" -o "${sample_id}_quast_results"
    """
}

process BUSCO {
    tag "Busco report for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::busco'

    publishDir "${params.outdir}/rawresults/busco", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("busco_output"), emit: busco_report

    script:
    """
    busco -i "${fasta}" -m genome -o busco_output -l bacteria_odb12
    """
}
