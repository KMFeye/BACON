process BAKTA_ANNOTATION {
    tag "Running Bakta for ${sample_id}"
    label 'process_high'
    conda 'bioconda::bakta'

    publishDir "${params.outdir}/rawdata/${sample_id}/bakta",
        mode: 'copy',
        pattern: "${sample_id}/*"
    publishDir "${params.outdir}/files/assemblies_annotated",
        mode: 'copy',
        pattern: "${sample_id}/${sample_id}.fna",
        saveAs: { "${sample_id}.annotated.fna" }
    publishDir "${params.outdir}/files/annotations_gff",
        mode: 'copy',
        pattern: "${sample_id}/${sample_id}.gff3",
        saveAs: { "${sample_id}.gff3" }
    publishDir "${params.outdir}/tables",
        mode: 'copy',
        pattern: "${sample_id}/${sample_id}.tsv",
        saveAs: { "${sample_id}.bakta_summary.tsv" }

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}.gff3"),   emit: gff
    tuple val(sample_id), path("${sample_id}/${sample_id}.fna"),    emit: fasta
    tuple val(sample_id), path("${sample_id}/${sample_id}.faa"),    emit: proteins
    tuple val(sample_id), path("${sample_id}/${sample_id}.tsv"),    emit: summary_table
    tuple val(sample_id), path("${sample_id}"),                    emit: bakta_dir

    script:
    """
    bakta --db ${params.bakta_db} --output ${sample_id} --prefix ${sample_id} ${assembly}
    """
}

