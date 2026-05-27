process PLOT_GENE_HEATMAP {
    tag "Create heatmap for ${matrix.baseName}"
    publishDir "${params.outdir}/figures/heatmaps", mode: 'copy' 
    memory '8.GB'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap'
    
    input:
    path(matrix)
    path(metadata)
    output:
    path("*.png"), emit: png
    path("*.svg"), emit: svg
    path("*.pdf"), emit: pdf

    script:
    def prefix = matrix.baseName.replaceAll('.csv', '')
    """
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(pheatmap)
    
    matrix_data <- read_csv("${matrix}") %>% column_to_rownames(var = "...1")
    metadata_data <- read_csv("${metadata}") %>% column_to_rownames(var = "strain")
    metadata_data <- metadata_data[colnames(matrix_data),, drop=FALSE]

    pheatmap(matrix_data, annotation_col = metadata_data, filename = "${prefix}.pdf", width = 15, height = 10)
    pheatmap(matrix_data, annotation_col = metadata_data, filename = "${prefix}.png")
    file.create("${prefix}.svg")
    """
}

process PLOT_PLASMID_MAPS {
    tag "Plotting plasmid map for ${fasta.baseName}"
    publishDir "${params.outdir}/figures/plasmid_maps", mode: 'copy'
    memory '8.GB'
    conda 'conda-forge::r-base conda-forge::r-tidyverse bioconda::bakta' 
    
    input:
    path(fasta)

    output:
    path("plots/*.png"), emit: plot_png
    path("plots/*.pdf"), emit: plot_pdf

    script:
    def prefix = fasta.baseName.replaceAll('.platon_plasmids', '')
    """
    if [ ! -s "${fasta}" ]; then
        echo "Input FASTA is empty, no plasmids to plot."
        mkdir -p plots
        touch "plots/${prefix}_plasmid_map.png"
        touch "plots/${prefix}_plasmid_map.pdf"
        exit 0
    fi
    bakta --db ${params.bakta_db} --output bakta_out ${fasta} --prefix ${prefix}
    R -e 'library(ggplot2); dir.create("plots"); png("plots/${prefix}_plasmid_map.png"); ggplot() + theme_void() + ggsave(filename="plots/${prefix}_plasmid_map.pdf");'
    """
}


process PLOT_RESISTANCE_HEATMAP {
    tag "Generating resistance gene summary heatmap"
    label 'process_medium'
    publishDir "${params.outdir}/figures", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'

    input:
    path(summary_csvs)

    output:
    path("resistance_gene_heatmap.png"), emit: png
    path("resistance_gene_heatmap.pdf"), emit: pdf

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(pheatmap)
    library(viridis)

    abricate_file <- file.path(summary_csvs, "all_abricate_data.csv")
    amrfinder_file <- file.path(summary_csvs, "all_amrfinder_data.csv")

    if (!file.exists(abricate_file) && !file.exists(amrfinder_file)) {
        print("Warning: Neither ABRicate nor AMRFinder summary CSV found. Cannot generate heatmap.")
        file.create("resistance_gene_heatmap.png")
        file.create("resistance_gene_heatmap.pdf")
        quit()
    }

    if (file.exists(abricate_file)) {
        abricate_data <- read_csv(abricate_file) %>% filter(DATABASE != 'vfdb') %>% select(sample_id, GENE, RESISTANCE) %>% distinct()
    } else { abricate_data <- tibble() }
    if (file.exists(amrfinder_file)) {
        amrfinder_data <- read_csv(amrfinder_file) %>% select(sample_id, GENE = `Gene symbol`, RESISTANCE = Subclass) %>% distinct()
    } else { amrfinder_data <- tibble() }

    all_resistance_data <- bind_rows(abricate_data, amrfinder_data) %>%
                            filter(!is.na(GENE) & !is.na(sample_id)) %>%
                            distinct(sample_id, GENE, .keep_all = TRUE)

    if (nrow(all_resistance_data) > 0) {
        heatmap_matrix <- all_resistance_data %>%
                            mutate(present = 1) %>%
                            pivot_wider(id_cols = sample_id, names_from = GENE, values_from = present, values_fill = 0) %>%
                            column_to_rownames("sample_id")
        gene_annotation <- all_resistance_data %>%
                            select(GENE, RESISTANCE) %>%
                            filter(!is.na(RESISTANCE)) %>%
                            distinct() %>%
                            column_to_rownames("GENE")
        if (nrow(heatmap_matrix) > 1 && ncol(heatmap_matrix) > 1) {
            heatmap_colors <- c("#212121", "#FDE725FF")
            pheatmap(t(heatmap_matrix), main = "Resistance Gene Presence/Absence", cluster_rows = TRUE, cluster_cols = TRUE, annotation_row = gene_annotation,
                     show_rownames = TRUE, show_colnames = TRUE, fontsize_row = 6, fontsize_col = 8, color = heatmap_colors,
                     legend_breaks = c(0, 1), legend_labels = c("Absent", "Present"), filename = "resistance_gene_heatmap.pdf", width = 15, height = 10)
            pheatmap(t(heatmap_matrix), color = heatmap_colors, annotation_row = gene_annotation, filename = "resistance_gene_heatmap.png", width = 15, height = 10, units = "in", res = 300)
        } else {
            print("Not enough data for resistance heatmap.")
            file.create("resistance_gene_heatmap.png"); file.create("resistance_gene_heatmap.pdf")
        }
    } else {
        print("No resistance data found."); file.create("resistance_gene_heatmap.png"); file.create("resistance_gene_heatmap.pdf")
    }
    '''
}

process PLOT_VIRULENCE_HEATMAP {
    tag "Generating ABRicate VFDB virulence heatmap"
    label 'process_medium'
    publishDir "${params.outdir}/figures", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'

    input:
    path(summary_csvs)

    output:
    path("virulence_factor_heatmap.png"), emit: png
    path("virulence_factor_heatmap.pdf"), emit: pdf

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(pheatmap)
    library(viridis)

    abricate_file <- file.path(summary_csvs, "all_abricate_data.csv")
    if (!file.exists(abricate_file)) {
        print("ABricate summary CSV not found."); file.create("virulence_factor_heatmap.png"); file.create("virulence_factor_heatmap.pdf"); quit()
    }
    abricate_data <- read_csv(abricate_file) %>% filter(DATABASE == 'vfdb') %>% select(sample_id, GENE, PRODUCT) %>% distinct()

    if (nrow(abricate_data) > 0) {
        heatmap_matrix <- abricate_data %>% mutate(present = 1) %>% pivot_wider(id_cols = sample_id, names_from = GENE, values_from = present, values_fill = 0) %>% column_to_rownames("sample_id")
        gene_annotation <- abricate_data %>% select(GENE, PRODUCT) %>% distinct() %>% column_to_rownames("GENE")
        if (nrow(heatmap_matrix) > 1 && ncol(heatmap_matrix) > 1) {
            heatmap_colors <- c("#212121", "#440154FF")
            pheatmap(t(heatmap_matrix), main = "Virulence Factor Presence/Absence (VFDB)", cluster_rows = TRUE, cluster_cols = TRUE, annotation_row = gene_annotation,
                     show_rownames = TRUE, show_colnames = TRUE, fontsize_row = 6, fontsize_col = 8, color = heatmap_colors,
                     legend_breaks = c(0, 1), legend_labels = c("Absent", "Present"), filename = "virulence_factor_heatmap.pdf", width = 15, height = 10)
            pheatmap(t(heatmap_matrix), color = heatmap_colors, annotation_row = gene_annotation, filename = "virulence_factor_heatmap.png", width = 15, height = 10, units = "in", res = 300)
        } else {
            print("Not enough data for virulence heatmap."); file.create("virulence_factor_heatmap.png"); file.create("virulence_factor_heatmap.pdf")
        }
    } else {
        print("No VFDB data found."); file.create("virulence_factor_heatmap.png"); file.create("virulence_factor_heatmap.pdf")
    }
    '''
}

process PLOT_PLASMID_SUMMARY {
    tag "Generating plasmid distribution plots"
    label 'process_medium'
    publishDir "${params.outdir}/figures", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'

    input:
    path(summary_csvs)

    output:
    path("plasmid_dot_plot.png"), emit: dot_plot_png
    path("plasmid_inc_class_heatmap.png"), emit: heatmap_png

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(pheatmap)
    library(viridis)

    mobsuite_file <- file.path(summary_csvs, "all_mobsuite_data.csv")
    if (!file.exists(mobsuite_file)) {
        print("MOB-suite summary CSV not found."); file.create("plasmid_dot_plot.png"); file.create("plasmid_inc_class_heatmap.png"); quit()
    }
    mob_data <- read_csv(mobsuite_file) %>% select(sample_id, plasmid_id = primary_cluster_id, inc_types, mobility) %>% filter(!is.na(plasmid_id))

    dot_plot <- ggplot(mob_data, aes(x = plasmid_id, y = sample_id)) + geom_point(aes(color = mobility), size = 4, alpha = 0.8) +
                scale_color_viridis_d(option = "D", name = "Predicted Mobility") + labs(title = "Distribution of Predicted Plasmids", x = "Plasmid Cluster ID", y = "Sample") +
                theme_bw() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), plot.title = element_text(hjust = 0.5))
    ggsave("plasmid_dot_plot.png", plot = dot_plot, width = 14, height = 10, dpi = 300)

    inc_class_data <- mob_data %>% filter(!is.na(inc_types)) %>% separate_rows(inc_types, sep = ",") %>% mutate(inc_types = str_trim(inc_types), present = 1) %>% distinct(sample_id, inc_types, .keep_all = TRUE)
    inc_heatmap_matrix <- inc_class_data %>% pivot_wider(id_cols = sample_id, names_from = inc_types, values_from = present, values_fill = 0) %>% column_to_rownames("sample_id")
    
    if (nrow(inc_heatmap_matrix) > 1 && ncol(inc_heatmap_matrix) > 1) {
        heatmap_colors <- c("#212121", "#FDE725FF")
        pheatmap(inc_heatmap_matrix, main = "Presence of Plasmid Incompatibility (Inc) Classes", cluster_rows = TRUE, cluster_cols = TRUE,
                 color = heatmap_colors, legend_breaks = c(0, 1), legend_labels = c("Absent", "Present"), filename = "plasmid_inc_class_heatmap.png",
                 width = 12, height = 8, units = "in", res = 300)
    } else {
        print("Not enough data for Inc Class heatmap."); file.create("plasmid_inc_class_heatmap.png")
    }
    '''
}

process PLOT_PANTHER_DOTPLOT {
    tag "Generating PANTHER enrichment dot plot"
    label 'process_medium'
    publishDir "${params.outdir}/figures", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-viridis'

    input:
    path(summary_csvs)

    output:
    path("panther_enrichment_dotplot.png"), emit: png
    path("panther_enrichment_dotplot.pdf"), emit: pdf

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(viridis)

    panther_file <- file.path(summary_csvs, "panther_significant_enrichment.csv")
    if (!file.exists(panther_file) || file.info(panther_file)$size == 0) {
        print("PANTHER summary file not found or is empty. Skipping plot."); file.create("panther_enrichment_dotplot.png"); file.create("panther_enrichment_dotplot.pdf"); quit()
    }
    plot_data <- read_csv(panther_file)

    if (nrow(plot_data) > 0) {
        dot_plot <- ggplot(plot_data, aes(x = fold_enrichment, y = fct_reorder(term_label, fold_enrichment))) +
            geom_point(aes(size = gene_count, color = q_value)) + facet_wrap(~sample_id, scales = "free_y") +
            scale_color_viridis_c(option = "C", direction = -1, name = "Q-value") + scale_size_continuous(name = "Gene Count") +
            labs(title = "PANTHER Functional Enrichment Results (q < 0.05)", x = "Fold Enrichment", y = "Enriched Term") +
            theme_bw() + theme(plot.title = element_text(hjust = 0.5), strip.text = element_text(face = "bold"), axis.text.y = element_text(size=8))
        ggsave("panther_enrichment_dotplot.png", plot = dot_plot, width = 12, height = 9, dpi = 300)
        ggsave("panther_enrichment_dotplot.pdf", plot = dot_plot, width = 12, height = 9)
    } else {
        print("No significant enrichment terms to plot."); file.create("panther_enrichment_dotplot.png"); file.create("panther_enrichment_dotplot.pdf")
    }
    '''
}

process PLOT_ANNOTATED_TREE {
    tag "Generating annotated phylogenetic tree"
    label 'process_high'
    publishDir "${params.outdir}/figures", mode: 'copy'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis bioconductor-ggtree bioconductor-ggtreeextra'

    input:
    path(treefile)
    path(summary_csvs)
    path(metadata)

    output:
    path("annotated_phylogenetic_tree.png"), emit: png
    path("annotated_phylogenetic_tree.pdf"), emit: pdf

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(ggtree)
    library(ggtreeExtra)
    library(viridis)

    tree <- read.tree("${treefile}")
    sample_metadata <- read_csv("${metadata}")
    plasmid_data_file <- file.path(summary_csvs, "all_platon_data.csv")
    resistance_data_file <- file.path(summary_csvs, "all_abricate_data.csv")

    if (!file.exists(plasmid_data_file) || !file.exists(resistance_data_file)) {
        print("Missing summary CSVs."); file.create("annotated_phylogenetic_tree.png"); file.create("annotated_phylogenetic_tree.pdf"); quit()
    }
    
    plasmid_counts <- read_csv(plasmid_data_file) %>% group_by(sample_id) %>% summarise(plasmid_count = n())
    resistance_matrix <- read_csv(resistance_data_file) %>% mutate(present = 1) %>% select(sample_id, GENE, present) %>%
                         pivot_wider(id_cols = sample_id, names_from = GENE, values_from = present, values_fill = 0) %>% column_to_rownames("sample_id")
    annotation_data <- sample_metadata %>% left_join(plasmid_counts, by = "sample_id") %>%
                       mutate(plasmid_count = ifelse(is.na(plasmid_count), 0, plasmid_count)) %>% column_to_rownames("sample_id")
    
    color_by_column <- "${params.tree_color_column}"
    p <- ggtree(tree, layout = "circular") %<+% annotation_data
    p <- p + geom_tippoint(aes_string(color = color_by_column), size = 1.5) +
             scale_color_viridis_d(option="D", name = str_to_title(str_replace_all(color_by_column, "_", " ")))
    p <- p + geom_fruit(geom = geom_point, mapping = aes(size = plasmid_count), offset = 0.1, pwidth = 0.2) +
            scale_size_continuous(name = "Plasmid Count")
    if (ncol(resistance_matrix) > 0) {
        p <- p + new_scale_fill() +
             geom_fruit(data = resistance_matrix, geom = geom_tile, mapping = aes(fill = value), offset = 0.2, pwidth = 0.6) +
             scale_fill_viridis_c(option="C", name="Gene Presence")
    }
    p <- p + labs(title = "Annotated Phylogeny of Samples") + theme(plot.title = element_text(hjust = 0.5), legend.position = "right")
    
    ggsave("annotated_phylogenetic_tree.pdf", plot = p, width = 14, height = 12)
    ggsave("annotated_phylogenetic_tree.png", plot = p, width = 14, height = 12, dpi = 300)
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
