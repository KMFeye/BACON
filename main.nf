#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// =================================================================
// === IMPORT ALL NECESSARY PROCESSES ===
// =================================================================

// General purpose modules
include { SUBSAMPLE_RASUSA } from './modules/subsample.nf'
include { CLEAN_QAQC } from './modules/QAQCClean.nf'
include { MULTIQC } from './modules/multiqc.nf'

// Reference genome preparation
include {
    DOWNLOAD_HUMAN_GENOME;
    DOWNLOAD_BACTERIAL_REFERENCE;
    INDEX_GENOME as INDEX_BACTERIAL_GENOME
} from './modules/IndexClean.nf'

// Decontamination modules
include {
    BAM_TO_FASTQ;
    MINIMAP2_DECONTAMINATE
} from './modules/bamtocleanfastq.nf'

// Assembly and QC modules
include {
    FLYE_ASSEMBLY;
    QUAST_REPORT;
    BOSCO
} from './modules/circularizeassemblecheck.nf'

// Annotation modules
include { BAKTA_ANNOTATION } from './modules/annotation.nf'

include {
    AMRFINDER_ANALYSIS;
    PLASMIDFINDER_ANALYSIS;
    MOB_SUITE_ANALYSIS;
    RUN_ABRICATE
} from './modules/resistance.nf'

include { CRISPR_TYPING } from './modules/other_analysis.nf'

// SNP Analysis modules
include {
    ALIGN_TO_REFERENCE;
    CALL_VARIANTS_BCFTOOLS;
    FILTER_VARIANTS_BCFTOOLS
} from './modules/snp_analysis.nf'

// Final Summarization module
include { SUMMARIZE_RESULTS } from './modules/summarize.nf';

// =================================================================
// === THE MAIN WORKFLOW ===
// =================================================================

workflow {

    // --- 1. PREPARATION ---
    human_genome_fasta_ch = DOWNLOAD_HUMAN_GENOME()
    bacterial_ref_fasta_ch = DOWNLOAD_BACTERIAL_REFERENCE()
    bacterial_ref_index_ch = INDEX_BACTERIAL_GENOME(bacterial_ref_fasta_ch)

    // --- CORRECTED: Removed unnecessary .collect() calls.
    // The original value channels are used directly by downstream processes,
    // which is more efficient and correct.
    // bacterial_ref_fasta_val = bacterial_ref_fasta_ch.collect() <-- REMOVED
    // bacterial_ref_val = bacterial_ref_index_ch.collect() <-- REMOVED

    // --- 2. INITIAL PER-SAMPLE PROCESSING ---
    Channel
        .fromPath(params.input_bam)
        .map { file ->
            def sample_id = file.baseName.replaceAll('.bam$', '')
            return [ sample_id, file ]
        }
        .set { bam_files_ch }

    BAM_TO_FASTQ(bam_files_ch)
    MINIMAP2_DECONTAMINATE(BAM_TO_FASTQ.out.raw_fastq, human_genome_fasta_ch)
    SUBSAMPLE_RASUSA(MINIMAP2_DECONTAMINATE.out.cleaned_fastq)
    
    cleaned_reads_ch = SUBSAMPLE_RASUSA.out.rasusa_fastq
    
    // --- 3. PARALLEL ANALYSIS BRANCHES ---
    CLEAN_QAQC(cleaned_reads_ch)
    FLYE_ASSEMBLY(cleaned_reads_ch)
    
    assembly_ch = FLYE_ASSEMBLY.out.assembly_fasta

    QUAST_REPORT(assembly_ch)
    BAKTA_ANNOTATION(assembly_ch)
    AMRFINDER_ANALYSIS(assembly_ch)
    PLASMIDFINDER_ANALYSIS(assembly_ch)
    MOB_SUITE_ANALYSIS(assembly_ch)
    RUN_ABRICATE(assembly_ch)
    CRISPR_TYPING(assembly_ch)
    BOSCO(assembly_ch) // <-- BOSCO is now called here

    // --- SNP Analysis Branch (runs in parallel) ---
    ALIGN_TO_REFERENCE(cleaned_reads_ch, bacterial_ref_fasta_ch)

    // --- CORRECTED: The process now receives the value channel 'bacterial_ref_fasta_ch'
    // directly, instead of the incorrect collected list.
    CALL_VARIANTS_BCFTOOLS(ALIGN_TO_REFERENCE.out.aligned_bam, bacterial_ref_fasta_ch)
    
    FILTER_VARIANTS_BCFTOOLS(CALL_VARIANTS_BCFTOOLS.out.raw_vcf)

    // --- 4. FINAL AGGREGATION & SUMMARY ---
    // This structure is correct for joining many results channels by sample ID.
    // It has been updated to include the new BOSCO report.
    SUMMARIZE_RESULTS (
        FILTER_VARIANTS_BCFTOOLS.out.filtered_vcf
            .join(BAKTA_ANNOTATION.out.gff_file)
            .join(FLYE_ASSEMBLY.out.assembly_dir)
            .join(MOB_SUITE_ANALYSIS.out.mobsuite_report)
            .join(AMRFINDER_ANALYSIS.out.amrfinder_report)
            .join(RUN_ABRICATE.out.report)
            .join(CRISPR_TYPING.out.crispr_dir)
            .join(PLASMIDFINDER_ANALYSIS.out.plasmidfinder_report)
            .join(SUBSAMPLE_RASUSA.out.rasusa_stats)
            .join(BOSCO.out.busco_report) // <-- BUSCO output is now joined
    )

    bacterial_ref_fasta_ch
        .collectFile(name: 'reference.fasta', storeDir: "${params.outdir}/summary")

    // --- 5. MULTIQC AGGREGATION ---
    multiqc_ch = Channel.empty()
        .mix(CLEAN_QAQC.out.zip)
        .mix(QUAST_REPORT.out.quast_report)
        .mix(RUN_ABRICATE.out.report.map { it[1] }) 
        .collect()

    MULTIQC(multiqc_ch)
}
