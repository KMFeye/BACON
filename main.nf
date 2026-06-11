#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// =================================================================
// === IMPORTS ===
// =================================================================
include { DOWNLOAD_BACTERIAL_REFERENCE; INDEX_GENOME as INDEX_BACTERIAL_GENOME; PREPARE_PLASMIDFINDER_DB; INITIALIZE_AMRFINDER_DB } from './modules/IndexDB.nf'
include { BAM_TO_FASTQ } from './modules/bamtofastq.nf'
include { EXTRACT_TARGET_READS; GENERATE_CONTAMINATION_REPORT } from './modules/decontamination.nf'
include { SUBSAMPLE_RASUSA } from './modules/subsample.nf'
include { CLEAN_QAQC as INITIAL_READ_QC; CLEAN_QAQC as POSTFILTER_READ_QC } from './modules/fastqc.nf'
include { MULTIQC as MULTIQC_GENERAL; MULTIQC as MULTIQC_ASSEMBLY } from './modules/multiqc.nf'
include { FLYE_ASSEMBLY; QUAST_REPORT; BUSCO } from './modules/assemblecheck.nf'
include { BAKTA_ANNOTATION } from './modules/annotation.nf'
include { CREATE_SAMPLESHEET } from './modules/create_samplesheet.nf'
include { AMRFINDER_ANALYSIS; PLASMIDFINDER_ANALYSIS; MOB_SUITE_ANALYSIS; RUN_ABRICATE } from './modules/resistance.nf'
include { RUN_PLATON } from './modules/platonmodule.nf'
include { CRISPR_TYPING; VISUALIZE_CRISPR_RESULTS } from './modules/crispr.nf'
include { ALIGN_TO_REFERENCE; CALL_VARIANTS_BCFTOOLS; FILTER_VARIANTS_BCFTOOLS; FIX_VCF_HEADER } from './modules/snpanalysis.nf'
include { SNPEFF_ANNOTATE } from './modules/snpeff.nf'
include { CREATE_SNP_ALIGNMENT; BUILD_PHYLO_TREE } from './modules/phylogenetics.nf'
include { CREATE_SNPEFF_DB; FIND_FRAMESHIFTS; EXTRACT_IMPACTFUL_GENES; RUN_PANTHER_API_DIRECT } from './modules/functionalanalysis.nf'
include { RUN_PROGRESSIVE_MAUVE } from './modules/wholegenomealignment.nf'
include { RUN_PANAROO; RUN_PYSEER; PLOT_PYSEER_MANHATTAN } from './modules/pangenomeanalysis.nf'
include { GENERATE_FINAL_REPORT; SUMMARIZE_AND_ORGANIZE } from './modules/finalreport.nf'
include { PLOT_GENOME_SYNTENY; PLOT_PLASMID_MAPS; PLOT_RESISTANCE_HEATMAP; PLOT_VIRULENCE_HEATMAP; PLOT_PLASMID_SUMMARY; PLOT_PANTHER_DOTPLOT; PLOT_ANNOTATED_TREE; PLOT_KRAKEN_REPORTS } from './modules/visualization.nf'

// =================================================================
// === WORKFLOW ===
// =================================================================
workflow {

// --- 1. Preprocess ---
    bacterial_ref_fasta_ch = DOWNLOAD_BACTERIAL_REFERENCE()
    INDEX_BACTERIAL_GENOME(bacterial_ref_fasta_ch)
    amrfinder_db_ch = INITIALIZE_AMRFINDER_DB()
    plasmidfinder_db_ch = PREPARE_PLASMIDFINDER_DB()

    ch_input_bams = channel.fromPath(params.input_bam).map { file -> [ file.baseName.replaceAll('\\.bam$', ''), file ] }
    BAM_TO_FASTQ(ch_input_bams)
    raw_reads_ch = BAM_TO_FASTQ.out.raw_fastq
    INITIAL_READ_QC(raw_reads_ch.combine(channel.value('initial_raw_qc')))

    ch_kraken_db = channel.fromPath(params.kraken2_db_path)
    kraken_input_ch = raw_reads_ch.combine(ch_kraken_db)
    
    GENERATE_CONTAMINATION_REPORT(kraken_input_ch)
    EXTRACT_TARGET_READS(kraken_input_ch)

    reads_for_subsampling = EXTRACT_TARGET_READS.out.target_reads
        .combine(channel.value(params.genome_size))
        .combine(channel.value(params.coverage))
        
    SUBSAMPLE_RASUSA(reads_for_subsampling)
    rasusa_fastq_ch = SUBSAMPLE_RASUSA.out.fastq
    POSTFILTER_READ_QC(rasusa_fastq_ch.combine(channel.value('postfilter_subsampled_qc')))

// --- 2. Assembly and QAQC ---
    FLYE_ASSEMBLY(rasusa_fastq_ch)
    successful_assemblies_fasta = FLYE_ASSEMBLY.out.assembly_fasta

    QUAST_REPORT(successful_assemblies_fasta)
    BUSCO(successful_assemblies_fasta)
    MULTIQC_ASSEMBLY(QUAST_REPORT.out.quast_report.map{ it[1] })

// --- 3. Annotation and Characterization ---
    BAKTA_ANNOTATION(successful_assemblies_fasta)
    bakta_gff_ch = BAKTA_ANNOTATION.out.gff

    if (params.samplesheet && file(params.samplesheet).exists()) {
        ch_samplesheet_for_snpeff = channel.fromPath(params.samplesheet)
    } else {
        CREATE_SAMPLESHEET(BAKTA_ANNOTATION.out.gff.collect(), file("${params.outdir}/rawresults/bakta/"))
        ch_samplesheet_for_snpeff = CREATE_SAMPLESHEET.out.samplesheet
    }

    AMRFINDER_ANALYSIS(successful_assemblies_fasta, amrfinder_db_ch)
    PLASMIDFINDER_ANALYSIS(successful_assemblies_fasta.combine(plasmidfinder_db_ch))
    MOB_SUITE_ANALYSIS(successful_assemblies_fasta)
    RUN_ABRICATE(successful_assemblies_fasta)
    CRISPR_TYPING(successful_assemblies_fasta)
    RUN_PLATON(successful_assemblies_fasta)
    ch_platon_plasmids = RUN_PLATON.out.plasmid_fasta.map { id, fasta -> fasta }
    ch_mobsuite_plasmids = MOB_SUITE_ANALYSIS.out.mobsuite_report.map { id, dir -> file("${dir}/plasmid_*.fasta") }.flatten()
    ch_all_plasmids_to_plot = ch_platon_plasmids.mix(ch_mobsuite_plasmids)
    PLOT_PLASMID_MAPS(ch_all_plasmids_to_plot)

// --- 4. SNP and Functional Analysis ---
    ALIGN_TO_REFERENCE(rasusa_fastq_ch, bacterial_ref_fasta_ch)
    CALL_VARIANTS_BCFTOOLS(ALIGN_TO_REFERENCE.out.aligned_bam, bacterial_ref_fasta_ch)
    FILTER_VARIANTS_BCFTOOLS(CALL_VARIANTS_BCFTOOLS.out.raw_vcf)
    FIX_VCF_HEADER(FILTER_VARIANTS_BCFTOOLS.out.filtered_vcf)
    vcfs_after_fix = FIX_VCF_HEADER.out.vcf

    gff_for_build_ch = bakta_gff_ch.first()
    CREATE_SNPEFF_DB(gff_for_build_ch.map{ it[1] }, bacterial_ref_fasta_ch)
    
    def ref_genome_name_ch = bacterial_ref_fasta_ch.map { it.baseName }
    SNPEFF_ANNOTATE(
        vcfs_after_fix,
        CREATE_SNPEFF_DB.out.snpeff_config,
        CREATE_SNPEFF_DB.out.snpeff_db_dir,
        ref_genome_name_ch
    )
    annotated_vcfs = SNPEFF_ANNOTATE.out.annotated_vcf
    
    EXTRACT_IMPACTFUL_GENES(annotated_vcfs.join(bakta_gff_ch))
    ch_gene_lists = EXTRACT_IMPACTFUL_GENES.out.gene_lists
    RUN_PANTHER_API_DIRECT(
        ch_gene_lists,
        channel.value(params.panther_organism),
        channel.value(params.panther_annot_dataset)
    )

// --- 5. Pangenome and GWAS Analysis ---
    RUN_PANAROO(bakta_gff_ch.map { _id, gff -> gff }.collect())
    RUN_PYSEER(RUN_PANAROO.out.panaroo_dir, channel.fromPath(params.traits_file))

    ch_vcfs_for_phylo = vcfs_after_fix
        .map { sample_id, vcf, tbi -> [vcf, tbi] }
        .collect()
        .filter { list -> list.size() > 1 }
        
    CREATE_SNP_ALIGNMENT(ch_vcfs_for_phylo, bacterial_ref_fasta_ch)
    BUILD_PHYLO_TREE(CREATE_SNP_ALIGNMENT.out.alignment)

    ch_assemblies_for_mauve = successful_assemblies_fasta.map { _id, fasta -> fasta }.collect().filter { list -> list.size() > 1 }
    RUN_PROGRESSIVE_MAUVE(ch_assemblies_for_mauve)

// --- 6. Visualizations & Aggregation ---
    ch_done_signal = RUN_PLATON.out.plasmid_fasta.collect()

    SUMMARIZE_AND_ORGANIZE(
        ch_done_signal,
        successful_assemblies_fasta.map { id, fasta -> fasta }.collect(),
        file("${params.outdir}/rawresults"),
        file("${params.outdir}/tables")
    )
    
    ch_summary_csvs = SUMMARIZE_AND_ORGANIZE.out.map { final_files -> file("${final_files}/summary_csvs") }

    PLOT_RESISTANCE_HEATMAP(ch_summary_csvs)
    PLOT_VIRULENCE_HEATMAP(ch_summary_csvs)
    PLOT_PLASMID_SUMMARY(ch_summary_csvs)
    PLOT_PANTHER_DOTPLOT(ch_summary_csvs)

    ch_names_for_plot = successful_assemblies_fasta.map { id, fasta -> id }.collect()
    ch_fastas_for_plot = successful_assemblies_fasta.map { id, fasta -> fasta }.collect()

    PLOT_GENOME_SYNTENY(
        RUN_PROGRESSIVE_MAUVE.out.backbone, // Note: Make sure progressiveMauve emits this in its module
        ch_fastas_for_plot,
        ch_names_for_plot
    )
    
    PLOT_KRAKEN_REPORTS(GENERATE_CONTAMINATION_REPORT.out.report.map { _id, report -> report }.collect())
    VISUALIZE_CRISPR_RESULTS(CRISPR_TYPING.out.crispr_gff.collect().ifEmpty([]))

// --- 7. Concatenate Reports ---
    GENERATE_FINAL_REPORT(
        ch_summary_csvs,
        RUN_PANAROO.out.panaroo_dir.ifEmpty(file("dummy_panaroo")),
        BUILD_PHYLO_TREE.out.treefile.ifEmpty(file("dummy_tree")),
        CREATE_SNP_ALIGNMENT.out.merged_vcf.ifEmpty(file("dummy_vcf"))
    )

    PLOT_ANNOTATED_TREE(
        BUILD_PHYLO_TREE.out.treefile.ifEmpty(file("dummy_tree")),
        ch_summary_csvs,
        channel.fromPath(params.traits_file)
    )
}
