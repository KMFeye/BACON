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
include { FLYE_ASSEMBLY; QUAST_REPORT; BOSCO } from './modules/assemblecheck.nf'
include { BAKTA_ANNOTATION } from './modules/annotation.nf'
include { CREATE_SAMPLESHEET } from './modules/create_samplesheet.nf'
include { AMRFINDER_ANALYSIS; PLASMIDFINDER_ANALYSIS; MOB_SUITE_ANALYSIS; RUN_ABRICATE } from './modules/resistance.nf'
include { RUN_PLATON } from './modules/platon_module.nf'
include { CRISPR_TYPING; VISUALIZE_CRISPR_RESULTS } from './modules/crispr.nf'
include { ALIGN_TO_REFERENCE; CALL_VARIANTS_BCFTOOLS; FILTER_VARIANTS_BCFTOOLS; FIX_VCF_HEADER } from './modules/snpanalysis.nf'
include { SNPEFF_ANNOTATE } from './modules/snpeff.nf'
include { CREATE_SNP_ALIGNMENT; BUILD_PHYLO_TREE } from './modules/SNPphylogenetics.nf'
include { CREATE_SNPEFF_DB; FIND_FRAMESHIFTS; EXTRACT_IMPACTFUL_GENES; RUN_PANTHER_API_DIRECT } from './modules/functionalanalysis.nf'
include { RUN_PROGRESSIVE_MAUVE; PLOT_GENOME_SYNTENY } from './modules/wholegenomealignment.nf'
include { RUN_PANAROO; RUN_PYSEER; PLOT_PYSEER_MANHATTAN } from './modules/pangenomeanalysis.nf'
include { GENERATE_FINAL_REPORT; SUMMARIZE_AND_ORGANIZE } from './modules/finalreport.nf' 
include { PLOT_PLASMID_MAPS; PLOT_RESISTANCE_HEATMAP; PLOT_VIRULENCE_HEATMAP; PLOT_PLASMID_SUMMARY; PLOT_PANTHER_DOTPLOT; PLOT_ANNOTATED_TREE; PLOT_KRAKEN_REPORTS  } from './modules/visualization.nf'


// =================================================================
// === WORKFLOW ===
// =================================================================

workflow {

// --- 1. Preprocess ---
    bacterial_ref_fasta_ch = DOWNLOAD_BACTERIAL_REFERENCE()
    INDEX_BACTERIAL_GENOME(bacterial_ref_fasta_ch)

    amrfinder_db_ch = INITIALIZE_AMRFINDER_DB()
    plasmidfinder_db_ch = PREPARE_PLASMIDFINDER_DB()

    ch_input_bams = channel.fromPath(params.input_bam).map { file -> [ file.baseName.replaceAll('.bam$', ''), file ] }
    BAM_TO_FASTQ(ch_input_bams)
    raw_reads_ch = BAM_TO_FASTQ.out.raw_fastq

    INITIAL_READ_QC(raw_reads_ch.combine(channel.value('initial_raw_qc')))

    ch_kraken_db = channel.fromPath(params.kraken2_db_path)
    GENERATE_CONTAMINATION_REPORT(raw_reads_ch.combine(ch_kraken_db))
    EXTRACT_TARGET_READS(raw_reads_ch.combine(ch_kraken_db))

    ch_genome_size = channel.value(params.genome_size)
    ch_coverage = channel.value(params.coverage)
    reads_for_subsampling = EXTRACT_TARGET_READS.out.target_reads
    	.combine(ch_genome_size)
    	.combine(ch_coverage)
    SUBSAMPLE_RASUSA(reads_for_subsampling)
    rasusa_fastq_ch = SUBSAMPLE_RASUSA.out.fastq
    
    POSTFILTER_READ_QC(rasusa_fastq_ch.combine(channel.value('postfilter_subsampled_qc')))

// --- 2. Assembly via Flye and QAQC Assembly---
    FLYE_ASSEMBLY(rasusa_fastq_ch)
    successful_assemblies_fasta = FLYE_ASSEMBLY.out.assembly_dir.flatMap { id, dir ->
        def assembly_file = dir.resolve('assembly.fasta')
        assembly_file.exists() ? [ [ id, assembly_file ] ] : []
    }

    QUAST_REPORT(successful_assemblies_fasta)
    MULTIQC_ASSEMBLY(QUAST_REPORT.out.quast_report.collect().ifEmpty([]))

// --- 3. Annotation and Characterization ---
    BAKTA_ANNOTATION(successful_assemblies_fasta)
    bakta_gff_ch = BAKTA_ANNOTATION.out.gff
    bakta_fasta_ch = BAKTA_ANNOTATION.out.fasta

    AMRFINDER_ANALYSIS(successful_assemblies_fasta, amrfinder_db_ch)
    PLASMIDFINDER_ANALYSIS(successful_assemblies_fasta.combine(plasmidfinder_db_ch))
    MOB_SUITE_ANALYSIS(successful_assemblies_fasta)
    RUN_ABRICATE(successful_assemblies_fasta)
    BOSCO(successful_assemblies_fasta)
    CRISPR_TYPING(successful_assemblies_fasta)
    RUN_PLATON(successful_assemblies_fasta)
    PLOT_PLASMID_MAPS(RUN_PLATON.out.plasmid_fasta.map { id, fasta -> fasta })

// --- 4. SNP AND FUNCTIONAL ANALYSIS OF SNP IMPACTS ON BACTERIA ---
    ch_samplesheet_for_snpeff
    if (params.samplesheet && file(params.samplesheet).exists()) {
        println "[Workflow] Using provided samplesheet: ${params.samplesheet}"
        ch_samplesheet_for_snpeff = channel.fromPath(params.samplesheet)
    } else {
        println "[Workflow] No valid samplesheet provided. Generating one from BAKTA results."
        CREATE_SAMPLESHEET(
            BAKTA_ANNOTATION.out.gff.collect(), // A signal that all GFFs are ready
            file("${params.outdir}/rawresults/bakta/") // The path to the published results
        )
        ch_samplesheet_for_snpeff = CREATE_SAMPLESHEET.out.samplesheet
    }

    ALIGN_TO_REFERENCE(rasusa_fastq_ch, bacterial_ref_fasta_ch)
    CALL_VARIANTS_BCFTOOLS(ALIGN_TO_REFERENCE.out.aligned_bam, bacterial_ref_fasta_ch)
    FILTER_VARIANTS_BCFTOOLS(CALL_VARIANTS_BCFTOOLS.out.raw_vcf)
    FIX_VCF_HEADER(FILTER_VARIANTS_BCFTOOLS.out.filtered_vcf)
    vcfs_after_fix = FIX_VCF_HEADER.out.vcf

    db_build_input = bakta_gff_ch.join(successful_assemblies_fasta).first()
    CREATE_SNPEFF_DB(ch_samplesheet_for_snpeff)
    SNPEFF_ANNOTATE(vcfs_after_fix.combine(CREATE_SNPEFF_DB.out.snpeff_config).combine(CREATE_SNPEFF_DB.out.snpeff_db_dir))
    annotated_vcfs = SNPEFF_ANNOTATE.out.annotated_vcf

    EXTRACT_IMPACTFUL_GENES(annotated_vcfs.join(bakta_gff_ch))
    ch_gene_lists = EXTRACT_IMPACTFUL_GENES.out.gene_lists

    RUN_PANTHER_API_DIRECT(
    ch_gene_lists.combine(channel.value(params.rbioapi_organism_id))
                 .combine(channel.value(params.rbioapi_annot_dataset))
          )

// --- 5. PANGENOME and GWAS Analysis ---
    RUN_PANAROO(bakta_gff_ch.map { id, gff -> gff }.collect())
    RUN_PYSEER(RUN_PANAROO.out.panaroo_dir, channel.fromPath(params.traits_file))
    ch_vcfs_for_phylo = vcfs_after_fix.map { id, vcf -> vcf }.collect().filter { list -> list.size() > 1 }
    CREATE_SNP_ALIGNMENT(ch_vcfs_for_phylo, bacterial_ref_fasta_ch)
    BUILD_PHYLO_TREE(CREATE_SNP_ALIGNMENT.out.alignment)
    ch_assemblies_for_mauve = successful_assemblies_fasta.map { id, fasta -> fasta }.collect().filter { list -> list.size() > 1 }
    RUN_PROGRESSIVE_MAUVE(ch_assemblies_for_mauve)
   
// --- 6. Visualizations ---
    PLOT_GENOME_SYNTENY(RUN_PROGRESSIVE_MAUVE.out.xmfa)
    PLOT_KRAKEN_REPORTS(GENERATE_CONTAMINATION_REPORT.out.report.map { id, report -> report }.collect())
    VISUALIZE_CRISPR_RESULTS(CRISPR_TYPING.out.crispr_gff.collect().ifEmpty([]))

// --- 7. Concatenate Reports ---
    GENERATE_FINAL_REPORT(
        channel.empty(), // Placeholder
        RUN_PANAROO.out.panaroo_dir.ifEmpty(null),
        BUILD_PHYLO_TREE.out.treefile.ifEmpty(null),
        CREATE_SNP_ALIGNMENT.out.merged_vcf.ifEmpty(null)
    )

    PLOT_ANNOTATED_TREE(
        BUILD_PHYLO_TREE.out.treefile.ifEmpty(null),
        channel.fromPath(params.traits_file),
        channel.empty() 
    )
}
