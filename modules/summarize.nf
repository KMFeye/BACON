process SUMMARIZE_RESULTS {
    tag "Summarizing all key outputs for ${sample_id}"
    label 'process_low'

    publishDir "${params.outdir}/summary/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id),
          path(vcf),
          path(gff),
          path(flye_dir),
          path(mob_suite_report),
          path(amr_report),
          path(abricate_report),
          path(crispr_dir),
          path(plasmid_report),
          path(rasusa_stats),
          path(busco_report) // <-- ADDED

    output:
    path "${sample_id}"

    script:
    """
    mkdir -p "${sample_id}"

    cp "${vcf}" "${sample_id}/${sample_id}.filtered.vcf.gz"
    cp "${gff}" "${sample_id}/${sample_id}.bakta.gff3"
    cp -r "${flye_dir}" "${sample_id}/flye_output"
    cp -r "${mob_suite_report}" "${sample_id}/mob_suite_output"
    cp "${amr_report}" "${sample_id}/amrfinder_report.txt"
    cp "${abricate_report}" "${sample_id}/abricate_report.tsv"
    cp -r "${crispr_dir}" "${sample_id}/crispr_output"
    cp -r "${plasmid_report}" "${sample_id}/plasmidfinder_output"
    cp "${rasusa_stats}" "${sample_id}/rasusa_stats.txt"
    cp -r "${busco_report}" "${sample_id}/busco_output" // <-- ADDED
    """
}
