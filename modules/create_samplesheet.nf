process CREATE_SAMPLESHEET {
    tag "Creating SnpEff samplesheet"
    label 'process_low'
    
    publishDir: {"${params.outdir}/snpEff_db", mode: 'copy'}

    input:
    val(bakta_signal)
    val(results_dir)

    output:
    path("snpeff_samplesheet.csv"), emit: samplesheet

    script:
    """
    #!/bin/bash
    OUTPUT_CSV="snpeff_samplesheet.csv"
    RESULTS_DIR_BASE="${results_dir}"

    echo "sample_id,gff,reference_fasta" > "\${OUTPUT_CSV}"
    find . -type f -name "*.gff3" | while read gff_file_relative; do
    gff_file_abs=\$(readlink -f "\${gff_file_relative}")
    gff_path_suffix=\$(echo "\${gff_file_abs}" | sed "s|.*/results/||")
    persistent_gff_path="\${RESULTS_DIR_BASE}/\${gff_path_suffix}"
        
    base_name=\$(basename "\${persistent_gff_path}")
    dir_name=\$(dirname "\${persistent_gff_path}")
    sample_id="\${base_name%.gff3}"
    persistent_fasta_path="\${dir_name}/\${sample_id}.fasta"

        if [[ -f "\${persistent_fasta_path}" ]]; then
            echo "\${sample_id},\${persistent_gff_path},\${persistent_fasta_path}" >> "\${OUTPUT_CSV}"
        else
            echo "Warning: No corresponding FASTA file found for \${sample_id} at \${persistent_fasta_path}" >&2
        fi
    done
    """
 }
