process CRISPR_TYPING {
    tag "Finding CRISPR arrays for ${sample_id}"
    label 'process_medium'
    conda 'bioconda::minced'

    // The robust publishDir syntax
    publishDir "${params.outdir}/rawresults/crispr", mode: 'copy', saveAs: { filename -> "${sample_id}/${filename}" }

    input:
    tuple val(sample_id), path(assembly)

    output:
    // Specifically capture the expected output files, and make them optional
    tuple val(sample_id), path("${sample_id}.minced.gff"), emit: crispr_gff, optional: true
    tuple val(sample_id), path("${sample_id}.minced.fna"), emit: crispr_fna, optional: true
    tuple val(sample_id), path("${sample_id}.minced.log"), emit: crispr_log, optional: true

    script:
    """
    minced -minNR 3 -minRL 18 -maxRL 50 \
        "${assembly}" \
        "${sample_id}.minced"
    """
}

process VISUALIZE_CRISPR_RESULTS {
    tag "Visualizing CRISPR results for all samples"
    label 'process_low'
    conda 'conda-forge::matplotlib-base'

    publishDir "${params.outdir}/figures", mode: 'copy'

    input:
    path(gff_files)

    output:
    path("crispr_summary_plot.png"), emit: plot

    script:
    """
    #!/usr/bin/env python
    import os, sys, matplotlib.pyplot as plt

    all_gffs = [f for f in os.listdir('.') if f.endswith('.gff')]
    data_points = []
    for gff_file in all_gffs:
        sample_id = gff_file.replace('.minced.gff', '')
        with open(gff_file, 'r') as f:
            num_crisprs = sum(1 for line in f if not line.startswith('#'))
        data_points.append((sample_id, num_crisprs))

    if not data_points:
        plt.figure(figsize=(8, 6))
        plt.text(0.5, 0.5, 'No CRISPR arrays found in any sample', ha='center', va='center', fontsize=12)
        plt.savefig('crispr_summary_plot.png')
        sys.exit(0)

    data_points.sort(key=lambda x: x[0])
    samples = [x[0] for x in data_points]
    counts = [x[1] for x in data_points]
    
    fig, ax = plt.subplots(figsize=(max(8, len(samples) * 0.5), 6))
    ax.bar(samples, counts)
    ax.set_ylabel('Number of CRISPR Arrays Found')
    ax.set_title('CRISPR Array Summary')
    ax.tick_params(axis='x', rotation=90)
    plt.tight_layout()
    plt.savefig('crispr_summary_plot.png')
    """
}
