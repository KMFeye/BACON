#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// === IMPORT ALL NECESSARY PROCESSES ===

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
    QUAST_REPORT
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
include {
    ALIGN_TO_REFERENCE;
    CALL_VARIANTS_BCFTOOLS;
    FILTER_VARIANTS_BCFTOOLS
} from './modules/snp_analysis.nf'
include { SUMMARIZE_RESULTS } from './modules/summarize.nf'


// === THE MAIN WORKFLOW ===

workflow {

    // --- 1. PREPARATION ---
    human_genome_fasta_ch = DOWNLOAD_HUMAN_GENOME()
    bacterial_ref_fasta_ch = DOWNLOAD_BACTERIAL_REFERENCE()
    bacterial_ref_fasta_val = bacterial_ref_fasta_ch.collect()
    bacterial_ref_index_ch = INDEX_BACTERIAL_GENOME(bacterial_ref_fasta_ch)
    bacterial_ref_val = bacterial_ref_index_ch.collect()

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
    QUAST_REPORT(FLYE_ASSEMBLY.out.assembly_fasta)
    
    bakta_in_ch = FLYE_ASSEMBLY.out.assembly_fasta
    BAKTA_ANNOTATION(bakta_in_ch)
    AMRFINDER_ANALYSIS(bakta_in_ch)
    PLASMIDFINDER_ANALYSIS(bakta_in_ch)
    MOB_SUITE_ANALYSIS(bakta_in_ch)
    RUN_ABRICATE(bakta_in_ch)
    CRISPR_TYPING(bakta_in_ch)

    ALIGN_TO_REFERENCE(cleaned_reads_ch, bacterial_ref_fasta_ch)
    CALL_VARIANTS_BCFTOOLS(ALIGN_TO_REFERENCE.out.aligned_bam, bacterial_ref_fasta_val)
    FILTER_VARIANTS_BCFTOOLS(CALL_VARIANTS_BCFTOOLS.out.raw_vcf)

    // --- 4. FINAL AGGREGATION & SUMMARY (NEW SECTION) ---

    vcf_ch = FILTER_VARIANTS_BCFTOOLS.out.filtered_vcf
    gff_ch = BAKTA_ANNOTATION.out.bakta_report.map { sample_id, path -> [ sample_id, file("${path}/*.gff3") ] }
    fasta_ch = FLYE_ASSEMBLY.out.assembly_fasta
    gfa_ch = FLYE_ASSEMBLY.out.assembly_gfa
    mob_ch = MOB_SUITE_ANALYSIS.out.mobsuite_report

    vcf_ch.join(gff_ch)
          .join(fasta_ch)
          .join(gfa_ch)
          .join(mob_ch)
          .set { summary_input_ch }

    SUMMARIZE_RESULTS(summary_input_ch)

    bacterial_ref_fasta_ch
        .collectFile(name: 'reference.fasta', storeDir: "${params.outdir}/summary")

    // --- 5. MULTIQC AGGREGATION ---
    multiqc_ch = Channel.empty()
        .mix(CLEAN_QAQC.out.zip)
        .mix(QUAST_REPORT.out.quast_report)
        .mix(RUN_ABRICATE.out.report)
        .collect()

    MULTIQC(multiqc_ch)
}
