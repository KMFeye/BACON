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

process PLOT_KRAKEN_REPORTS {
    tag "Generating Kraken2 summary plot"
    label 'process_medium'

    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-ggplot2'
    publishDir "${params.outdir}/figures", mode: 'copy'

    input:
    path kraken_reports

    output:
    path "kraken2_stacked_barplot.png"

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)

    files <- Sys.glob('*.txt')
    
    kraken_data <- files %>%
      set_names(.) %>%
      map_dfr(~ read_tsv(., col_names = c('percentage', 'reads_total', 'reads_level', 'rank', 'taxid', 'name'), col_types = cols(.default = "c")), .id = "filepath") %>%
      mutate(sample_id = basename(filepath) %>% str_replace(".kraken2_report.txt", "")) %>%
      mutate(
        percentage = as.numeric(percentage),
        name = str_trim(name)
      ) %>%
      filter(rank %in% c('G', 'S'))

    top_taxa <- kraken_data %>%
      group_by(name) %>%
      summarise(mean_abundance = mean(percentage)) %>%
      filter(name != 'unclassified') %>%
      top_n(10, wt = mean_abundance) %>%
      pull(name)

    plot_data <- kraken_data %>%
      mutate(taxon_plot = ifelse(name %in% top_taxa, name, 'Other')) %>%
      group_by(sample_id, taxon_plot) %>%
      summarise(total_percentage = sum(percentage))

    kraken_plot <- ggplot(plot_data, aes(x = sample_id, y = total_percentage, fill = taxon_plot)) +
        geom_bar(stat = "identity", position = "stack") +
        scale_fill_brewer(palette = "Paired") +
        labs(
            title = "Taxonomic Composition of Samples (Kraken2)",
            x = "Sample ID",
            y = "Percentage of Reads",
            fill = "Taxon"
        ) +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))

    ggsave("kraken2_stacked_barplot.png", plot = kraken_plot, width = 12, height = 8, dpi = 300)
    '''
}
