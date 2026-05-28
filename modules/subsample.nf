process SUBSAMPLE_RASUSA {
    tag "Subsampling ${sample_id}"
    label 'process_low'
    conda 'bioconda::rasusa=0.7.0'

    publishDir: {"${params.outdir}/rawresults/rasusa/${sample_id}/subsampling", mode: 'copy'}

    input:
    tuple val(sample_id), path(fastq_in), val(genome_size), val(coverage)

    output:
    tuple val(sample_id), path("${sample_id}.subsampled.fastq.gz"), emit: fastq
    tuple val(sample_id), path("${sample_id}.rasusa_stats.txt"), emit: stats

    script:
    """
    if [[ "${genome_size}" == "false" || "${coverage}" == "false" ]]; then
        echo "Genome size or coverage not specified. Skipping subsampling."
        cp ${fastq_in} ${sample_id}.subsampled.fastq.gz
        touch ${sample_id}.rasusa_stats.txt
    else
        echo "Subsampling reads to ${coverage}x coverage..."
        rasusa -c ${coverage} -g ${genome_size} -i ${fastq_in} | gzip > ${sample_id}.subsampled.fastq.gz 2> ${sample_id}.rasusa_stats.txt
    fi
    """
}
