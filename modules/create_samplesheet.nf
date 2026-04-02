process CREATE_SAMPLESHEET {
    tag "Creating SnpEff samplesheet"
    label 'process_low'
    
    publishDir "${params.outdir}/snpEff_db", mode: 'copy'

    input:
    val(bakta_signal)
    val(results_dir)

    output:
    path("snpeff_samplesheet.csv"), emit: samplesheet

    script:
    """
    #!/bin/bash
    OUTPUT_CSV="snpeff_samplesheet.csv"
    
    # This is the path to the real results directory, as seen from the launch directory
    RESULTS_DIR_BASE="${results_dir}"

    echo "sample_id,gff,reference_fasta" > "\${OUTPUT_CSV}"

    # We find the files inside the staged directory, but we will reconstruct the
    # path for the samplesheet using the original base path.
    find . -type f -name "*.gff3" | while read gff_file_relative; do
        
        # Make the path absolute to the workdir for manipulation
        gff_file_abs=\$(readlink -f "\${gff_file_relative}")
        
        # Get the part of the path that is *relative* to the staged 'results' dir
        # This is the key step to remove the temporary work/HASH part.
        gff_path_suffix=\$(echo "\${gff_file_abs}" | sed "s|.*/results/||")

        # Reconstruct the true, persistent path
        persistent_gff_path="\${RESULTS_DIR_BASE}/\${gff_path_suffix}"
        
        # Now proceed with the original logic using the persistent path
        base_name=\$(basename "\${persistent_gff_path}")
        dir_name=\$(dirname "\${persistent_gff_path}")
        sample_id="\${base_name%.gff3}"
        persistent_fasta_path="\${dir_name}/\${sample_id}.fasta"
        
        # We check for the file using its persistent path
        if [[ -f "\${persistent_fasta_path}" ]]; then
            echo "\${sample_id},\${persistent_gff_path},\${persistent_fasta_path}" >> "\${OUTPUT_CSV}"
        else
            echo "Warning: No corresponding FASTA file found for \${sample_id} at \${persistent_fasta_path}" >&2
        fi
    done
    """
 }
