process BAKTA_ANNOTATION {
    tag "Running Bakta for ${sample_id}"
    label 'process_high'
    conda 'bioconda::bakta'

    publishDir "${params.outdir}/rawresults/bakta", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}.gff3"),   emit: gff
    tuple val(sample_id), path("${sample_id}/${sample_id}.fna"),    emit: fasta
    tuple val(sample_id), path("${sample_id}/${sample_id}.faa"),    emit: proteins
    tuple val(sample_id), path("${sample_id}/${sample_id}.tsv"),    emit: summary_table
    tuple val(sample_id), path("${sample_id}"),                     emit: bakta_dir

    script:
    """
    bakta --db ${params.bakta_db} --output ${sample_id} --prefix ${sample_id} ${assembly}
    """
}
