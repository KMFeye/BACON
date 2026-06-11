process SUMMARIZE_AND_ORGANIZE {
    tag "Consolidating all results and organizing final files"
    label 'process_low'
    conda 'conda-forge::r-base conda-forge::r-tidyverse'
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
    #!/usr/bin/env Rscript
    library(tidyverse)

    dir.create("final_files/summary_csvs", recursive = TRUE, showWarnings = FALSE)
    dir.create("final_files/assemblies", recursive = TRUE, showWarnings = FALSE)

    fasta_files <- list.files(pattern = "\\\\.fasta$")
    for (f in fasta_files) {
        tryCatch({ file.copy(f, "final_files/assemblies/") }, error = function(e) {})
    }

    safe_read_and_concat <- function(search_dir, glob_pattern, out_name, id_level, comment_char = "") {
        cmd <- paste0("find -L ", search_dir, " -type f")
        all_files <- system(cmd, intern = TRUE)
        regex_pattern <- glob_pattern %>% str_replace_all("\\\\.", "\\\\.")
        matched_files <- all_files[str_detect(all_files, regex_pattern)]
        
        if (length(matched_files) == 0) return(NULL)
        
        merged_df <- list()
        for (f in matched_files) {
            tryCatch({
                if (file.info(f)$size > 0) {
                    path_parts <- str_split(f, "/")[[1]]
                    sample_id <- path_parts[id_level]
                    delim <- if (str_detect(f, "\\\\.(tsv|txt|tab)$")) "\\t" else ","
                    
                    df <- read_delim(f, delim = delim, show_col_types = FALSE, comment = comment_char)
                    
                    if (nrow(df) > 0) {
                        df$sample_id <- sample_id
                        merged_df[[f]] <- df
                    }
                }
            }, error = function(e) {})
        }
        
        if (length(merged_df) > 0) {
            final_df <- bind_rows(merged_df)
            out_path <- file.path("final_files/summary_csvs", out_name)
            write_csv(final_df, out_path)
        }
    }

    safe_read_and_concat("rawresults", "resistance/.*/.*_abricate_report\\\\.tsv$", "all_abricate_data.csv", 3)
    safe_read_and_concat("tables", "amrfinder/.*_amrfinder\\\\.txt$", "all_amrfinder_data.csv", 3)
    safe_read_and_concat("tables", "mobsuite/.*contig_report\\\\.txt$", "all_mobsuite_data.csv", 3)
    safe_read_and_concat("rawresults", "quast/.*_quast_results/report\\\\.tsv$", "all_quast_metrics.csv", 3)
    safe_read_and_concat("rawresults", "busco/.*short_summary.*\\\\.txt$", "all_busco_summaries.csv", 3, comment_char="#")
    safe_read_and_concat("rawresults", ".*platon/.*\\\\.tsv$", "all_platon_data.csv", 3)
    safe_read_and_concat("rawresults", "crispr/crispr_output/spacers\\\\.tab$", "all_crispr_spacers.csv", 3)
    safe_read_and_concat("rawresults", "flye/.*/assembly_info\\\\.txt$", "all_flye_info.csv", 3)
    safe_read_and_concat("rawresults", ".*/rasusa/.*rasusa_stats\\\\.txt$", "all_rasusa_stats.csv", 3)
    safe_read_and_concat("rawresults", "functional_analysis/panther_results/.*\\\\.tsv$", "all_panther_results.csv", 3)
    '''
}


process GENERATE_FINAL_REPORT {
    tag "Generating Final Publication Package"
    label 'process_high'
    
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-ape conda-forge::r-pheatmap conda-forge::r-rio conda-forge::r-kableextra'
    
    publishDir "${params.outdir}/figures", mode: 'copy'

    input:
    path("summary_tables_dir")
    path("panaroo_dir")
    path("phylo_tree")
    path("merged_vcf")

    output:
    path "publication_figures"
    path "publication_tables"
    path "summary_report.html"

    script:
    '''
    #!/usr/bin/env Rscript

    suppressPackageStartupMessages({
        library(tidyverse)
        library(kableExtra)
        library(ape)
        library(pheatmap)
        library(rio)
    })

    dir.create("publication_figures", showWarnings = FALSE)
    dir.create("publication_tables", showWarnings = FALSE)

    tryCatch({
        print("Creating Master QC Table...")
        multiqc_file <- file.path("summary_tables_dir", "multiqc_data", "multiqc_general_stats.txt")
        if(file.exists(multiqc_file)) {
            qc_data <- read_tsv(multiqc_file, col_types = cols(.default = "c"))
            qc_data %>%
                kbl(caption="Master Quality Control Summary") %>%
                kable_styling(bootstrap_options = "striped") %>%
                save_kable("publication_tables/master_qc_table.html")
            file.copy(file.path("summary_tables_dir", "multiqc_report.html"), ".")
        }
    }, error = function(e) { print(paste("Error in QC section:", e)) })

    all_summary_files <- list.files(path = "summary_tables_dir", pattern = "\\\\.csv$", full.names = TRUE)
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

    tryCatch({
        print("Attempting to generate ABRicate heatmap...")
        abricate_file <- file.path("summary_tables_dir", "all_abricate_data.csv")
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

    file.create("summary_report.html")
    print("--- Final Report Generation Complete ---")
    '''
}
