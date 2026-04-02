process SUMMARIZE_AND_ORGANIZE {
    tag "Consolidating all results and organizing final files"
    label 'process_low'
    
    publishDir "${params.outdir}/files", mode: 'copy'

    input:
    val(done_signal)
    path(assemblies)
    path(raw_results_dir)
    path(tables_dir)

    output:
    path "final_files"

    script:
    '''
    #!/usr/bin/env python
    import pandas as pd
    import glob
    import os
    import shutil

    print("--- Starting Final Summary and Organization ---")
    
    os.makedirs('final_files/summary_csvs', exist_ok=True)
    os.makedirs('final_files/assemblies', exist_ok=True)

    # 1. Organize Final Assembly Files
    print("Organizing final assembly files...")
    for f in glob.glob("*.fasta"):
        if os.path.isfile(f):
            try:
                shutil.copy(f, "final_files/assemblies/")
            except Exception as e:
                print(f"Could not copy assembly {f}: {e}")
    
    # 2. Consolidate Summary Tables into CSVs
    def safe_read_and_concat(search_dir, glob_pattern, out_name, id_level, sep='\\t', comment=None, header=0):
        files = glob.glob(f"{search_dir}/**/{glob_pattern}", recursive=True)
        if not files:
            print(f"Warning: No files found for pattern '{glob_pattern}' in '{search_dir}'")
            return
        
        dfs = []
        for f in files:
            try:
                if os.path.getsize(f) > 0:
                    sample_id = f.split('/')[id_level]
                    df = pd.read_csv(f, sep=sep, comment=comment, low_memory=False, header=header)
                    df['sample_id'] = sample_id
                    dfs.append(df)
            except Exception as e:
                print(f"Warning: Could not read or process file {f}: {e}")
        
        if dfs:
            out_path = os.path.join('final_files/summary_csvs', out_name)
            pd.concat(dfs, ignore_index=True).to_csv(out_path, index=False)
            print(f"Successfully created {out_path}")

    # --- Call the function for all reports ---
    print("Consolidating analysis reports into summary CSVs...")
    safe_read_and_concat(str(tables_dir), 'abricate/*.tsv', 'all_abricate_data.csv', 2)
    safe_read_and_concat(str(tables_dir), 'amrfinder/*.txt', 'all_amrfinder_data.csv', 2)
    safe_read_and_concat(str(tables_dir), 'mobsuite/contig_report.txt', 'all_mobsuite_data.csv', 3)
    safe_read_and_concat(str(tables_dir), 'quast/report.tsv', 'all_quast_metrics.csv', 2)
    safe_read_and_concat(str(tables_dir), 'bosco/short_summary.specific.*.txt', 'all_busco_summaries.csv', 2, comment='#', header=None)
    safe_read_and_concat(str(raw_results_dir), '*/platon/*.tsv', 'all_platon_data.csv', 3)
    safe_read_and_concat(str(raw_results_dir), '*/crispr/crispr_output/spacers.tab', 'all_crispr_spacers.csv', 3)
    safe_read_and_concat(str(raw_results_dir), '*/flye/assembly_info.txt', 'all_flye_info.csv', 2)
    safe_read_and_concat(str(raw_results_dir), '*/subsampling/*.rasusa_stats.txt', 'all_rasusa_stats.csv', 3, header=None)
    safe_read_and_concat(str(raw_results_dir), '*/functional_analysis/panther_results/*.tsv', 'all_panther_results.csv', 4)
    
    print("--- Final Organization Complete ---")
    '''
}
