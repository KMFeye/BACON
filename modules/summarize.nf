// In: modules/summarize.nf

process SUMMARIZE_RESULTS {
    tag "Summarizing all key outputs for ${sample_id}"
    label 'process_low'
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    // This process takes a "package" for each sample: the ID and all its key files
    tuple val(sample_id),
          path(vcf),
          path(gff),
          path(assembly_fasta),
          path(assembly_gfa),
          path(mob_suite_report)

    output:
    // We will output a manifest and a dedicated directory for each sample
    path "summary_manifest.csv"
    path "${sample_id}"

    script:
    """
    # Create a dedicated directory for this sample's final outputs
    mkdir -p "${sample_id}"

    # Copy all the key files into this directory with clean, consistent names
    cp "${vcf}" "${sample_id}/${sample_id}.vcf.gz"
    cp "${gff}" "${sample_id}/${sample_id}.gff3"
    cp "${assembly_fasta}" "${sample_id}/${sample_id}.assembly.fasta"
    cp "${assembly_gfa}" "${sample_id}/${sample_id}.assembly.gfa"

    # Copy the entire mob_suite output directory recursively
    cp -r "${mob_suite_report}" "${sample_id}/mob_suite_output"

    # Create a manifest line for this sample, which will be combined later
    echo "${sample_id},${sample_id}/${sample_id}.vcf.gz,${sample_id}/${sample_id}.gff3,${sample_id}/${sample_id}.assembly.fasta,${sample_id}/${sample_id}.assembly.gfa" > summary_manifest.csv
    """
}
