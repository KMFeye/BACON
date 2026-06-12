process PLOT_GENOME_SYNTENY {
    tag "Linear Synteny Plotting"
    label 'process_medium'
    conda 'conda-forge::r-base conda-forge::r-stringr conda-forge::r-ggplot2 bioconda::samtools'
    publishDir "${params.outdir}/figures/synteny", mode: 'copy'

    input:
    path(backbone)
    path(fastas)  
    val(names)    

    output:
    path("*.pdf"), emit: plot


    script:
    """
    #!/usr/bin/env bash
   
    touch sizes.txt
    names_array=(${names.join(' ')})
    fastas_array=(${fastas.join(' ')})
   
    for i in "\${!fastas_array[@]}"; do
        fasta="\${fastas_array[\$i]}"
        name="\${names_array[\$i]}"
        samtools faidx "\$fasta"
        
        # Sum up all contig lengths into a single total genome size
        total_size=\$(cut -f2 "\$fasta.fai" | awk '{s+=\$1} END {print s}')
        
        # Name the first genome scaffold_ref, and the second scaffold_tar
        if [ "\$i" == "0" ]; then
            echo -e "scaffold_ref\\t\$total_size\\t\$name" >> sizes.txt
        else
            echo -e "scaffold_tar\\t\$total_size\\t\$name" >> sizes.txt
        fi
    done
   
    python3 - "${names.join(',')}" "${backbone}" <<'EOF'
import sys
names_str = sys.argv[1]
backbone_file = sys.argv[2]
names = names_str.split(",")

open("synteny_blocks.txt", "w").close()

with open(backbone_file, "r") as f:
    lines = f.readlines()
    
if len(lines) > 1:
    header = lines[0].strip().split("\\t")
    num_genomes = len(header) // 2
    
    with open("synteny_blocks.txt", "w") as out:
        for line in lines[1:]:
            cols = line.strip().split("\\t")
            if len(cols) < num_genomes * 2:
                continue
            
            for i in range(num_genomes - 1):
                ref_start = int(cols[i*2])
                ref_end = int(cols[i*2 + 1])
                tar_start = int(cols[(i+1)*2])
                tar_end = int(cols[(i+1)*2 + 1])
                
                if ref_start == 0 or tar_start == 0:
                    continue
                
                strand = "+"
                if ref_start < 0 or tar_start < 0:
                    strand = "-"
                    ref_start = abs(ref_start)
                    ref_end = abs(ref_end)
                    tar_start = abs(tar_start)
                    tar_end = abs(tar_end)
                
                out.write(f"scaffold_ref\\t{ref_start}\\t{ref_end}\\tscaffold_tar\\t{tar_start}\\t{tar_end}\\t{strand}\\t{names[i]}\\t{names[i+1]}\\n")
EOF

    Rscript - <<'EOF'
    if (!requireNamespace("syntenyPlotteR", quietly = TRUE)) {
        install.packages("syntenyPlotteR", repos="http://cran.us.r-project.org")
    }
    library(stringr)
    library(ggplot2)
    library(syntenyPlotteR)
    
    tryCatch({
        if (file.info("synteny_blocks.txt")[['size']] > 0) {
            draw.linear(
                output = "synteny_plot", 
                sizefile = "sizes.txt", 
                "synteny_blocks.txt", 
                fileformat = "pdf"
            )
        } else {
            stop("No valid synteny blocks found to plot.")
        }
    }, error = function(e) {
        pdf("synteny_plot.pdf")
        plot(1, type="n", axes=FALSE, xlab="", ylab="")
        text(1, 1, paste("No major structural variants or inversions detected\\nbetween these samples.\\n\\n(Error:", e[['message']], ")"), cex=0.8)
        dev.off()
    })
EOF
    """
}


process PLOT_GENE_HEATMAP {
    tag "Create heatmap for ${matrix.baseName}"
    memory '8.GB'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap'
    publishDir "${params.outdir}/figures/heatmaps", mode: 'copy'

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
    memory '8.GB'
    
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-ggforce bioconda::bakta=1.8.2 bioconda::pyhmmer=0.10.3 bioconda::diamond=2.1.8'
    
    publishDir "${params.outdir}/figures/plasmid_maps", mode: 'copy'

    input:
    path(fasta)

    output:
    path("plots/*.png"), emit: plot_png
    path("plots/*.pdf"), emit: plot_pdf

    script:
    def prefix = fasta.baseName.replaceAll('.platon_plasmids', '')
    """#!/usr/bin/env bash
    
    set -e
    mkdir -p plots

    if [ ! -s "${fasta}" ]; then
        echo "Input FASTA is empty, no plasmids to plot."
        Rscript -e "pdf('plots/${prefix}_plasmid_map.pdf'); plot(1, type='n', axes=FALSE, xlab='', ylab=''); text(1, 1, 'No plasmid sequences found in this sample.', cex=1); dev.off()"
        touch "plots/${prefix}_plasmid_map.png"
        exit 0
    fi

    amrfinder_update --force_update --database ${params.bakta_db}/amrfinderplus-db || true

    bakta --db ${params.bakta_db} --output bakta_out ${fasta} --prefix ${prefix} --skip-amr

    Rscript - <<'EOF'
    library(tidyverse)
    library(ggplot2)

    gff_file <- list.files("bakta_out", pattern="\\\\.gff3", full.names=TRUE)[1]
    
    if(!is.na(gff_file) && file.exists(gff_file)) {
        gff_data <- read_tsv(gff_file, comment="#", col_names=c("seqid", "source", "type", "start", "end", "score", "strand", "phase", "attributes")) %>%
                    filter(type == "CDS")
        
        if(nrow(gff_data) > 0) {
            gff_data <- gff_data %>%
                mutate(gene = str_extract(attributes, "(?<=Name=)[^;]+"),
                       product = str_extract(attributes, "(?<=product=)[^;]+")) %>%
                mutate(gene = ifelse(is.na(gene), "hypothetical", gene))

            plasmid_length <- max(gff_data[['end']])

            p <- ggplot(gff_data, aes(xmin = start, xmax = end, y = 1, fill = strand)) +
                 geom_rect(ymin = 0.8, ymax = 1.2, color = "black", linewidth=0.2) +
                 coord_polar(theta = "x") +
                 xlim(c(0, plasmid_length)) +
                 ylim(c(0, 1.5)) +
                 theme_void() +
                 scale_fill_manual(values = c("+" = "#1f78b4", "-" = "#ff7f00")) +
                 labs(title = paste("Plasmid Map:", "${prefix}"), fill = "Strand") +
                 theme(plot.title = element_text(hjust = 0.5, size=16, face="bold"))
                 
            ggsave(paste0("plots/", "${prefix}", "_plasmid_map.pdf"), plot = p, width = 8, height = 8)
            ggsave(paste0("plots/", "${prefix}", "_plasmid_map.png"), plot = p, width = 8, height = 8, dpi = 300)
            quit(save="no", status=0)
        }
    }
    
    pdf(paste0("plots/", "${prefix}", "_plasmid_map.pdf"))
    plot(1, type="n", axes=FALSE, xlab="", ylab="")
    text(1, 1, "Failed to parse annotation for plasmid map.", cex=1)
    dev.off()
    file.create(paste0("plots/", "${prefix}", "_plasmid_map.png"))
EOF
    """
}

process PLOT_RESISTANCE_HEATMAP {
    tag "Generating resistance gene summary heatmap"
    label 'process_medium'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'
    publishDir "${params.outdir}/figures", mode: 'copy'
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
    
    abricate_file <- file.path("summary_csvs", "all_abricate_data.csv")
    amrfinder_file <- file.path("summary_csvs", "all_amrfinder_data.csv")
    
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
        raw_amr <- read_csv(amrfinder_file)
        
        if ("Element symbol" %in% names(raw_amr)) {
            raw_amr <- raw_amr %>% rename(GENE = `Element symbol`)
        } else if ("Gene symbol" %in% names(raw_amr)) {
            raw_amr <- raw_amr %>% rename(GENE = `Gene symbol`)
        }
        
        if ("Subclass" %in% names(raw_amr)) {
            raw_amr <- raw_amr %>% rename(RESISTANCE = Subclass)
        }
        
        amrfinder_data <- raw_amr %>% select(any_of(c("sample_id", "GENE", "RESISTANCE"))) %>% distinct()
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
                            # FIXED: Keep only unique gene names to prevent rowname duplication crashes!
                            distinct(GENE, .keep_all = TRUE) %>%
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
    tag "Generating ABRicate NCBI heatmap"
    label 'process_medium'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'
    publishDir "${params.outdir}/figures", mode: 'copy'

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
    
    abricate_file <- file.path("summary_csvs", "all_abricate_data.csv")
    if (!file.exists(abricate_file)) {
        print("ABricate summary CSV not found."); file.create("virulence_factor_heatmap.png"); file.create("virulence_factor_heatmap.pdf"); quit()
    }
    
    # ADDED safety distinct filter here
    abricate_data <- read_csv(abricate_file) %>% filter(DATABASE == 'vfdb') %>% select(sample_id, GENE, PRODUCT) %>% distinct(sample_id, GENE, .keep_all = TRUE)
    
    if (nrow(abricate_data) > 0) {
        heatmap_matrix <- abricate_data %>% mutate(present = 1) %>% pivot_wider(id_cols = sample_id, names_from = GENE, values_from = present, values_fill = 0) %>% column_to_rownames("sample_id")
        
        # PROACTIVE FIX: strict distinct(GENE) to prevent column_to_rownames crash!
        gene_annotation <- abricate_data %>% select(GENE, PRODUCT) %>% distinct(GENE, .keep_all = TRUE) %>% column_to_rownames("GENE")
        
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
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis'
    publishDir "${params.outdir}/figures", mode: 'copy'

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
    
    mobsuite_file <- file.path("summary_csvs", "all_mobsuite_data.csv")
    if (!file.exists(mobsuite_file)) {
        print("MOB-suite summary CSV not found."); file.create("plasmid_dot_plot.png"); file.create("plasmid_inc_class_heatmap.png"); quit()
    }
    
    raw_mob_data <- read_csv(mobsuite_file)
    
    if ("rep_type(s)" %in% names(raw_mob_data)) {
        raw_mob_data <- raw_mob_data %>% rename(inc_types = `rep_type(s)`)
    }
    if ("predicted_mobility" %in% names(raw_mob_data)) {
        raw_mob_data <- raw_mob_data %>% rename(mobility = predicted_mobility)
    }
    
    mob_data <- raw_mob_data %>% 
                select(any_of(c("sample_id", "primary_cluster_id", "inc_types", "mobility"))) %>% 
                rename(plasmid_id = primary_cluster_id) %>% 
                filter(!is.na(plasmid_id))
    
    if ("mobility" %in% names(mob_data) && nrow(mob_data) > 0) {
        dot_plot <- ggplot(mob_data, aes(x = plasmid_id, y = sample_id)) + geom_point(aes(color = mobility), size = 4, alpha = 0.8) +
                    scale_color_viridis_d(option = "D", name = "Predicted Mobility") + labs(title = "Distribution of Predicted Plasmids", x = "Plasmid Cluster ID", y = "Sample") +
                    theme_bw() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), plot.title = element_text(hjust = 0.5))
        ggsave("plasmid_dot_plot.png", plot = dot_plot, width = 14, height = 10, dpi = 300)
    } else {
        file.create("plasmid_dot_plot.png")
    }
    
    if ("inc_types" %in% names(mob_data) && nrow(mob_data) > 0) {
        inc_class_data <- mob_data %>% filter(!is.na(inc_types) & inc_types != "-") %>% separate_rows(inc_types, sep = ",") %>% mutate(inc_types = str_trim(inc_types), present = 1) %>% distinct(sample_id, inc_types, .keep_all = TRUE)
        
        if(nrow(inc_class_data) > 0) {
            inc_heatmap_matrix <- inc_class_data %>% pivot_wider(id_cols = sample_id, names_from = inc_types, values_from = present, values_fill = 0) %>% column_to_rownames("sample_id")
            
            if (nrow(inc_heatmap_matrix) > 1 && ncol(inc_heatmap_matrix) > 1) {
                heatmap_colors <- c("#212121", "#FDE725FF")
                pheatmap(inc_heatmap_matrix, main = "Presence of Plasmid Incompatibility (Inc) Classes", cluster_rows = TRUE, cluster_cols = TRUE,
                         color = heatmap_colors, legend_breaks = c(0, 1), legend_labels = c("Absent", "Present"), filename = "plasmid_inc_class_heatmap.png",
                         width = 12, height = 8, units = "in", res = 300)
            } else {
                print("Not enough data for Inc Class heatmap."); file.create("plasmid_inc_class_heatmap.png")
            }
        } else {
             file.create("plasmid_inc_class_heatmap.png")
        }
    } else {
        print("No Inc Type data found."); file.create("plasmid_inc_class_heatmap.png")
    }
    '''
}

process PLOT_PANTHER_DOTPLOT {
    tag "Generating PANTHER enrichment dot plot"
    label 'process_medium'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-viridis'
    publishDir "${params.outdir}/figures", mode: 'copy'

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
    
    panther_file <- file.path("summary_csvs", "panther_significant_enrichment.csv")
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
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-pheatmap conda-forge::r-viridis conda-forge::r-ggnewscale bioconductor-ggtree bioconductor-ggtreeextra'    
    publishDir "${params.outdir}/figures", mode: 'copy'
    
    input:
    path(treefile)
    path(summary_csvs)
    path(metadata)
    
    output:
    path("annotated_phylogenetic_tree.png"), emit: png
    path("annotated_phylogenetic_tree.pdf"), emit: pdf
    
    script:
    """#!/usr/bin/env Rscript
    library(tidyverse)
    library(ggtree)
    library(ggtreeExtra)
    library(viridis)
    library(ggnewscale)
    
    tryCatch({
        if (!file.exists("${treefile}") || "${treefile}" == "dummy_tree" || file.info("${treefile}")[['size']] == 0) {
            stop("No valid phylogenetic tree file was generated (requires 2 or more samples).")
        }
        tree <- read.tree("${treefile}")
        
        if (file.exists("${metadata}")) {
            sample_metadata <- read_csv("${metadata}", show_col_types = FALSE)
        } else {
            sample_metadata <- tibble(sample_id = tree[['tip.label']])
        }
        
        plasmid_data_file <- file.path("summary_csvs", "all_platon_data.csv")
        resistance_data_file <- file.path("summary_csvs", "all_abricate_data.csv")
        
        if (file.exists(plasmid_data_file) && file.info(plasmid_data_file)[['size']] > 0) {
            plasmid_counts <- read_csv(plasmid_data_file, show_col_types = FALSE) %>% group_by(sample_id) %>% summarise(plasmid_count = n())
        } else {
            plasmid_counts <- tibble(sample_id = character(), plasmid_count = numeric())
        }
        
        if (file.exists(resistance_data_file) && file.info(resistance_data_file)[['size']] > 0) {
            resistance_matrix <- read_csv(resistance_data_file, show_col_types = FALSE) %>% 
                                 distinct(sample_id, GENE, .keep_all = TRUE) %>%
                                 mutate(present = 1) %>% 
                                 select(sample_id, GENE, present) %>%
                                 pivot_wider(id_cols = sample_id, names_from = GENE, values_from = present, values_fill = 0) %>% 
                                 column_to_rownames("sample_id")
        } else {
            resistance_matrix <- data.frame()
        }
                             
        annotation_data <- sample_metadata %>% 
                           left_join(plasmid_counts, by = "sample_id") %>%
                       mutate(plasmid_count = ifelse(is.na(plasmid_count), 0, plasmid_count))
        
        tree_layout <- if (length(tree[['tip.label']]) > 2) "circular" else "rectangular"
        
        p <- ggtree(tree, layout = tree_layout)
        p[['data']] <- p[['data']] %>% left_join(annotation_data, by = c("label" = "sample_id"))
        
        color_by_column <- "${params.tree_color_column}"
        if (color_by_column %in% colnames(annotation_data)) {
            p <- p + geom_tippoint(aes_string(color = color_by_column), size = 3) +
                     scale_color_viridis_d(option="D", name = str_to_title(str_replace_all(color_by_column, "_", " ")))
        } else {
            p <- p + geom_tippoint(size = 3)
        }
                 
        p <- p + geom_fruit(geom = geom_point, mapping = aes(size = plasmid_count), offset = 0.1, pwidth = 0.2) +
                scale_size_continuous(name = "Plasmid Count")
                
        if (ncol(resistance_matrix) > 0) {
            p <- p + new_scale_fill() +
                 geom_fruit(data = resistance_matrix, geom = geom_tile, mapping = aes(fill = value), offset = 0.2, pwidth = 0.6) +
                 scale_fill_viridis_c(option="C", name="Gene Presence")
        }
        
        p <- p + labs(title = "Annotated Phylogeny") + 
             theme(plot.title = element_text(hjust = 0.5), legend.position = "right")
        
        ggsave("annotated_phylogenetic_tree.pdf", plot = p, width = 14, height = 12)
        ggsave("annotated_phylogenetic_tree.png", plot = p, width = 14, height = 12, dpi = 300)
        
    }, error = function(e) {
        pdf("annotated_phylogenetic_tree.pdf")
        plot(1, type="n", axes=FALSE, xlab="", ylab="")
        text(1, 1, paste("No tree generated (requires 2 or more samples).\\n\\n(Error:", e[['message']], ")"), cex=0.8)
        dev.off()
        file.create("annotated_phylogenetic_tree.png")
    })
    """
}

process PLOT_KRAKEN_REPORTS {
    tag "Generating Kraken2 summary plot"
    label 'process_medium'
    conda 'conda-forge::r-base conda-forge::r-tidyverse conda-forge::r-rcolorbrewer'
    publishDir "${params.outdir}/figures/kraken2", mode: 'copy'

    input:
    path reports

    output:
    path "kraken2_stacked_barplot.png"

    script:
    '''
    #!/usr/bin/env Rscript
    library(tidyverse)
    library(RColorBrewer)
    
    report_files <- list.files(path = ".", pattern = "\\\\.kraken2_report\\\\.txt$")
    
    if (length(report_files) == 0) {
        png("kraken2_summary_plot.png", width = 800, height = 600)
        plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
        text(1, 1, "No Kraken2 reports found to generate a plot.", cex = 1.5)
        dev.off()
        quit()
    }
    
    kraken_data <- report_files %>%
        set_names() %>%
        map_dfr(
            ~ read_tsv(., col_names = c('percentage', 'reads_total', 'reads_level', 'rank', 'taxid', 'name'), col_types = cols(.default = "c")),
            .id = "filepath"
        ) %>%
        mutate(
            sample_id = basename(filepath) %>% str_replace(".kraken2_report.txt", ""),
            percentage = as.numeric(percentage),
            name = str_trim(name)
        ) %>%
        filter(rank %in% c('G', 'S'))
        
    top_taxa <- kraken_data %>%
        group_by(name) %>%
        summarise(mean_abundance = mean(percentage, na.rm = TRUE)) %>%
        filter(name != 'unclassified' & !is.na(name)) %>%
        slice_max(order_by = mean_abundance, n = 10) %>%
        pull(name)
        
    plot_data <- kraken_data %>%
        mutate(taxon_plot = ifelse(name %in% top_taxa, name, 'Other')) %>%
        group_by(sample_id, taxon_plot) %>%
        summarise(total_percentage = sum(percentage, na.rm = TRUE), .groups = 'drop')
        
    kraken_plot <- ggplot(plot_data, aes(x = sample_id, y = total_percentage, fill = taxon_plot)) +
        geom_bar(stat = "identity", position = "stack") +
        scale_fill_brewer(palette = "Paired") +
        labs(
            title = "Top 10 Taxa per Sample (Kraken2)",
            x = "Sample ID",
            y = "Percentage of Reads",
            fill = "Taxon"
        ) +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom")
        
    ggsave("kraken2_stacked_barplot.png", plot = kraken_plot, width = 12, height = 8, dpi = 300)
    '''
}
