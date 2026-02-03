#!/usr/bin/env nextflow
// This is the main file for your nextflow.  Do not touch this UNLESS your path for your db has changed ##
nextflow.enable.dsl = 2

// =================================================================
// echo "Let's go"
// =================================================================

// General purpose modules (no changes)
include { SUBSAMPLE_RASUSA } from './modules/subsample.nf'
include { CLEAN_QAQC } from './modules/QAQCClean.nf'
include { MULTIQC } from './modules/multiqc.nf'

// Reference genome preparation 
include {
    DOWNLOAD_HUMAN_GENOME;
    DOWNLOAD_BACTERIAL_REFERENCE;
    INDEX_GENOME as INDEX_BACTERIAL_GENOME
} from './modules/IndexClean.nf'

// Decontamination modules (no changes)
include {
    BAM_TO_FASTQ;
    MINIMAP2_DECONTAMINATE
} from './modules/bamtocleanfastq.nf'

// Assembly and QC modules (no changes)
include {
    FLYE_ASSEMBLY;
    QUAST_REPORT
} from './modules/circularizeassemblecheck.nf'

// --- KEY CHANGE: Refactored Annotation and Analysis includes ---
// We now include processes from their new, functionally-grouped module files.

// 1. Bakta from the new, dedicated annotation.nf
include { BAKTA_ANNOTATION } from './modules/annotation.nf'

// 2. AMR/Virulence/Plasmid tools from the new resistance.nf
include {
    AMRFINDER_ANALYSIS;
    PLASMIDFINDER_ANALYSIS;
    MOB_SUITE_ANALYSIS; // <-- MOB_SUITE is now correctly included again
    RUN_ABRICATE
} from './modules/resistance.nf'

// 3. Other typing tools from their own module file
include { CRISPR_TYPING } from './modules/other_analysis.nf'

// SNP Analysis modules (no changes)
include {
    ALIGN_TO_REFERENCE;
    CALL_VARIANTS_BCFTOOLS;
    FILTER_VARIANTS_BCFTOOLS
} from './modules/snp_analysis.nf';

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
    
    // --- KEY CHANGE: Restored the call to MOB_SUITE_ANALYSIS ---
    MOB_SUITE_ANALYSIS(bakta_in_ch)
    
    RUN_ABRICATE(bakta_in_ch)
    CRISPR_TYPING(bakta_in_ch)

    ALIGN_TO_REFERENCE(cleaned_reads_ch, bacterial_ref_fasta_ch)
    CALL_VARIANTS_BCFTOOLS(ALIGN_TO_REFERENCE.out.aligned_bam, bacterial_ref_fasta_val)
    FILTER_VARIANTS_BCFTOOLS(CALL_VARIANTS_BCFTOOLS.out.raw_vcf)

    // --- 4. FINAL AGGREGATION STEP ---
    multiqc_ch = Channel.empty()
        .mix(CLEAN_QAQC.out.zip)
        .mix(QUAST_REPORT.out.quast_report)
        .mix(RUN_ABRICATE.out.report)
        .collect()

    MULTIQC(multiqc_ch)
}
