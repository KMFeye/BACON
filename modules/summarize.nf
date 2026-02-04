process SUMMARIZE_RESULTS {
    tag "Summarizing all key outputs for ${sample_id}"
    label 'process_low'
    publishDir "${params.outdir}/summary", mode: 'copy'

    input:
    tuple val(sample_id),
          path(vcf),
          path(gff),
          path(flye_dir), // <-- CHANGED
          path(mob_suite_report)

    output:
    path "summary_manifest.csv"
    path "${sample_id}"

    script:
    """
    mkdir -p "${sample_id}"

    # Now we find the files inside the flye_dir
    cp "${vcf}" "${sample_id}/${sample_id}.vcf.gz"
    cp "${gff}" "${sample_id}/${sample_id}.gff3"
    cp "${flye_dir}/assembly.fasta" "${sample_id}/${sample_id}.assembly.fasta"
    cp "${flye_dir}/assembly_graph.gfa" "${sample_id}/${sample_id}.assembly.gfa" // Correct filename is assembly_graph.gfa
    cp -r "${mob_suite_report}" "${sample_id}/mob_suite_output"

    # Update manifest accordingly
    echo "${sample_id},${sample_id}/${sample_id}.vcf.gz,${sample_id}/${sample_id}.gff3,${sample_id}/${sample_id}.assembly.fasta,${sample_id}/${sample_id}.assembly.gfa" > summary_manifest.csv
    """
}
