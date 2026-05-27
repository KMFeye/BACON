process GENERATE_FINAL_REPORT {
    tag "Generating Final Publication Package"
    label 'process_high'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-ape conda-forge::r-pheatmap conda-forge::r-rio conda-forge::r-kableextra'

    publishDir "${params.outdir}/figures", mode: 'copy'

    input:
    path summary_tables_dir
    path panaroo_dir
    path phylo_tree
    path merged_vcf

    output:
    path "publication_figures"
    path "publication_tables"
    path "summary_report.html" // Placeholder for RMarkdown

    script:
    '''
    #!/usr/bin/env Rscript
    
    # --- Installation of Bioconductor Packages ---
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", repos = "http://cran.us.r-project.org")
    }
    pkgs_to_install <- c("SNPRelate", "ggtree", "ggtreeExtra")
    for (pkg in pkgs_to_install) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
            BiocManager::install(pkg)
        }
    }

    # --- Load all libraries ---
    suppressPackageStartupMessages({
        library(tidyverse)
        library(kableExtra)
        library(ggtree)
        library(ggtreeExtra)
        library(ape)
        library(SNPRelate)
        library(pheatmap)
        library(rio)
    })

    # --- Setup ---
    dir.create("publication_figures", showWarnings = FALSE)
    dir.create("publication_tables", showWarnings = FALSE)

    # --- 1. Master Quality Control Table ---
    tryCatch({
        print("Creating Master QC Table...")
        multiqc_file <- file.path("${summary_tables_dir}", "multiqc_data", "multiqc_general_stats.txt")
        if(file.exists(multiqc_file)) {
            qc_data <- read_tsv(multiqc_file, col_types = cols(.default = "c"))
            qc_data %>%
                kbl(caption="Master Quality Control Summary") %>%
                kable_styling(bootstrap_options = "striped") %>%
                save_kable("publication_tables/master_qc_table.html")
            file.copy(file.path("${summary_tables_dir}", "multiqc_report.html"), ".")
        }
    }, error = function(e) { print(paste("Error in QC section:", e)) })

    # --- 2. Resistance & Plasmid Outputs ---
    all_summary_files <- list.files(path = "${summary_tables_dir}", pattern = "*.csv", full.names = TRUE)
    for (f in all_summary_files) {
        tryCatch({
            table_name <- basename(f) %>% str_replace(".csv", "")
            df <- read_csv(f)
            if(nrow(df) > 0){
                df %>%
                    kbl(caption = paste("Summary of", table_name)) %>%
                    kable_styling(bootstrap_options = c("striped", "hover", "responsive"), full_width = F) %>%
                    save_kable(paste0("publication_tables/", table_name, "_summary.html"))
            }
        }, error = function(e) { print(paste("Could not format table", f, ":", e)) })
    }

    # --- 3. ABRicate Clustered Heatmap ---
    tryCatch({
        print("Attempting to generate ABRicate heatmap...")
        abricate_file <- file.path("${summary_tables_dir}", "all_abricate_data.csv")
        if (file.exists(abricate_file) && file.info(abricate_file)$size > 0) {
            all_abricate_data <- read_csv(abricate_file, col_types = cols(.default = "c")) %>%
                rename(SAMPLE_ID = sample_id)
            heatmap_data <- all_abricate_data %>% count(SAMPLE_ID, GENE, name = "dose")
            if (n_distinct(heatmap_data$SAMPLE_ID) > 1 && n_distinct(heatmap_data$GENE) > 1) {
                p <- ggplot(heatmap_data, aes(x=SAMPLE_ID, y=GENE, fill=dose)) + geom_tile()
                ggsave("publication_figures/abricate_heatmap.png", plot = p, width = 12, height = 8, dpi = 300)
                print("... ABRicate heatmap successfully generated.")
            }
        }
    }, error = function(e) { print(paste("Error in ABRicate heatmap section:", e)) })
    
    # --- 4. Annotated Phylogenetic Tree ---
    tryCatch({
        print("Generating annotated phylogenetic tree...")
        if (file.exists("${phylo_tree}") && file.info("${phylo_tree}")$size > 0) {
             # Your ggtree plotting code here ...
        }
    }, error = function(e) { print(paste("Error generating annotated tree:", e)) })

    # --- 5. SNP PCA Analysis ---
    tryCatch({
        print("Attempting to run SNP PCA...")
         if (file.exists("${merged_vcf}") && file.info("${merged_vcf}")$size > 0) {
            # Your SNPRelate PCA code here ...
         }
    }, error = function(e) { print(paste("An error occurred during SNP PCA analysis:", e)) })

    file.create("summary_report.html")
    print("--- Final Report Generation Complete ---")
    '''
}

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

