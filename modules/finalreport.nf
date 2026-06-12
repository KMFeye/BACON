process AGGREGATE_CSVS {
    tag "Aggregating all pipeline data into Final CSVs"
    label 'process_low'
    conda 'conda-forge::r-base conda-forge::r-tidyverse'
    
    publishDir "${params.outdir}/finalcsvs", mode: 'copy'

    input:
    path(abricate_files)
    path(amrfinder_files)
    path(plasmidfinder_files)
    path(mobsuite_files)
    path(platon_files)
    path(quast_files)
    path(busco_files)
    path(flye_files)
    path(rasusa_files)
    path(bakta_files)
    path(crispr_files)
    path(snpeff_files)
    path(panther_files)
    path(panaroo_files)
    path(pyseer_files)
    path(multiqc_files)
    path(kraken_files)

    output:
    path("*.csv")
    path("pipeline_data_audit.txt")
    path("*_raw") // NEW: Tells Nextflow to publish all the raw subdirectories we create!

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)

    audit_file <- "pipeline_data_audit.txt"
    write("========================================", file=audit_file)
    write(" BACON PIPELINE - DATA AUDIT MANIFEST", file=audit_file, append=TRUE)
    write("========================================", file=audit_file, append=TRUE)

    log_audit <- function(message) {
        write(message, file=audit_file, append=TRUE)
        print(message)
    }

    # 1. NEW: Function to copy complex raw files/folders straight into subdirectories
    copy_raw_folder <- function(files_list, dest_folder) {
        dir.create(dest_folder, showWarnings = FALSE)
        file_array <- str_split(files_list, " ")[[1]]
        file_array <- file_array[file_array != "[]" & file_array != ""]
        
        for (f in file_array) {
            if (file.exists(f)) {
                file.copy(f, dest_folder, recursive = TRUE)
            }
        }
    }

    # 2. Master Merger Function
    merge_files <- function(files_list, out_name, comment_char = "", is_folder = FALSE, folder_target = "") {
        file_array <- str_split(files_list, " ")[[1]]
        file_array <- file_array[file_array != "[]" & file_array != ""]
        
        merged_df <- list()
        for (f in file_array) {
            target_path <- f
            if (is_folder) {
                found_files <- list.files(f, pattern=folder_target, full.names=TRUE, recursive=TRUE)
                if(length(found_files) > 0) { target_path <- found_files[1] } else { target_path <- "DOES_NOT_EXIST" }
            }

            if (file.exists(target_path) && file.info(target_path)$size > 0) {
                delim <- if (str_detect(target_path, "\\\\.(tsv|txt|tab)$")) "\\t" else ","
                df <- tryCatch(read_delim(target_path, delim = delim, show_col_types = FALSE, comment = comment_char), error = function(e) NULL)
                
                if (!is.null(df) && nrow(df) > 0) {
                    if ("#FILE" %in% colnames(df)) { df <- df %>% rename(FILE = `#FILE`) }
                    
                    sample_id <- str_replace(basename(f), "_.*", "")
                    df$sample_id <- sample_id
                    merged_df[[target_path]] <- df
                }
            }
        }
        
        if (length(merged_df) > 0) {
            final_df <- bind_rows(merged_df)
            write_csv(final_df, out_name)
            log_audit(paste("[SUCCESS]", out_name, "- Merged", length(merged_df), "samples. Total rows:", nrow(final_df)))
        } else {
            file.create(out_name)
            log_audit(paste("[EMPTY]  ", out_name, "- No data found. (Zero hits or skipped due to constraints)."))
        }
    }

    log_audit("\\n--- Resistance & Plasmids ---")
    merge_files("''' + abricate_files + '''", "abricate_final.csv")
    merge_files("''' + amrfinder_files + '''", "amrfinder_final.csv")
    merge_files("''' + platon_files + '''", "platon_final.csv")
    merge_files("''' + mobsuite_files + '''", "mobsuite_final.csv", is_folder=TRUE, folder_target="contig_report\\\\.txt$")
    merge_files("''' + plasmidfinder_files + '''", "plasmidfinder_final.csv", is_folder=TRUE, folder_target="results_tab\\\\.tsv$")

    log_audit("\\n--- Assembly & Annotation QC ---")
    merge_files("''' + quast_files + '''", "quast_final.csv", is_folder=TRUE, folder_target="report\\\\.tsv$")
    merge_files("''' + busco_files + '''", "busco_final.csv", is_folder=TRUE, folder_target="short_summary.*\\\\.txt$", comment_char="#")
    merge_files("''' + flye_files + '''", "flye_info_final.csv", is_folder=TRUE, folder_target="assembly_info\\\\.txt$")
    merge_files("''' + bakta_files + '''", "bakta_summary_final.csv")

    log_audit("\\n--- Genomics & Functional ---")
    merge_files("''' + crispr_files + '''", "crispr_final.csv")
    merge_files("''' + snpeff_files + '''", "snpeff_final.csv")
    
    # NEW: Copying the complex tools in their entirety so you can use them in your Rmd!
    log_audit("\\n--- Copying Complex Raw Folders ---")
    copy_raw_folder("''' + panther_files + '''", "panther_raw")
    copy_raw_folder("''' + panaroo_files + '''", "panaroo_raw")
    copy_raw_folder("''' + pyseer_files + '''", "pyseer_raw")
    copy_raw_folder("''' + multiqc_files + '''", "multiqc_raw")
    copy_raw_folder("''' + kraken_files + '''", "kraken_raw")
    copy_raw_folder("''' + rasusa_files + '''", "rasusa_raw")
    log_audit("[SUCCESS] Raw folders preserved for Panaroo, Panther, Pyseer, and MultiQC.")

    log_audit("\\n--- Aggregation Complete ---")
    '''
}
