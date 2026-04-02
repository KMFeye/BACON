process CREATE_SNPEFF_DB {
    tag "Create SnpEff database from ${sample_id}"
    label 'process_low'
    publishDir "${params.outdir}/rawresults/snpEff_db", mode: 'copy'
    conda 'bioconda::snpeff=5.1d'

    input:
    tuple val(sample_id), path(gff), path(reference_fasta)

    output:
    path "snpEff.config", emit: snpeff_config
    path "data", emit: snpeff_db_dir

    script:
    """
    mkdir -p data/${sample_id}
    
    cp ${reference_fasta} data/${sample_id}/sequences.fa
    cp ${gff} data/${sample_id}/genes.gff

    echo "data.dir = ./data" > snpEff.config
    echo "${sample_id}.genome : ${sample_id}" >> snpEff.config

    snpEff build -gff3 -v \\
        -c snpEff.config \\
        -noCheckProtein \\
        -noCheckCds \\
        ${sample_id}
    """
}


process FIND_FRAMESHIFTS {
    tag "Find frameshift variants in ${sample_id}"
    publishDir "${params.outdir}/rawresults/functional_analysis", mode: 'copy'
    conda 'bioconda::bcftools'

    input:
    tuple val(sample_id), path(vcf)

    output:
    tuple val(sample_id), path("${sample_id}_frameshift_report.txt")

    script:
    """
    bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\t%INFO/ANN\\n' ${vcf} \\
        | grep 'frameshift_variant' > "${sample_id}_frameshift_report.txt" || true
    """
}

process EXTRACT_IMPACTFUL_GENES {
    tag "Extract impactful genes for ${sample_id}"
    publishDir "${params.outdir}/rawresults/functional_analysis/${sample_id}", mode: 'copy'
    conda 'bioconda::bcftools'

    input:
    tuple val(sample_id), path(vcf), path(gff)

    output:
    tuple val(sample_id), path("impactful_genes.txt"), path("background_genes.txt"), emit: gene_lists

    script:
    '''
    #!/bin/bash
    bcftools query -f '[%INFO/ANN]\\n' ${vcf} | \\
        awk -F '|' '/HIGH|MODERATE/ {print $4}' | \\
        sort -u \\
        > impactful_genes.txt
        
    grep -o 'gene_id=[^;]*' ${gff} | \\
        sed 's/gene_id=//' | \\
        sort -u \\
        > background_genes.txt
    '''
}



process RUN_PANTHER_API_DIRECT {
    tag "Querying PANTHER API for ${sample_id}"
    label 'process_low'
    conda 'conda-forge::curl conda-forge::jq'

    publishDir "${params.outdir}/tables",
        mode: 'copy',
        pattern: "*.panther_results.tsv"

    publishDir "${params.outdir}/rawdata/panther/${sample_id}",
        mode: 'copy',
        pattern: "*"

    input:
    tuple val(sample_id), path(target_list), path(background_list), val(organism_id), val(annot_dataset)

    output:
    path("${sample_id}.panther_results.tsv"), emit: results

    script:
    """
    TARGET_GENES=\$(cat "${target_list}" | tr '\\n' ',' | sed 's/,\$//')
    BACKGROUND_GENES=\$(cat "${background_list}" | tr '\\n' ',' | sed 's/,\$//')
    curl -s \\
        -X POST \\
        -H "Content-Type: application/x-www-form-urlencoded" \\
        --data "geneInputList=\${TARGET_GENES}" \\
        --data "organism=${organism_id}" \\
        --data "annotDataSet=${annot_dataset}" \\
        --data "enrichmentTestType=FISHER" \\
        --data "correction=FDR" \\
        --data "refInputList=\${BACKGROUND_GENES}" \\
        --data "refOrganism=${organism_id}" \\
        "http://pantherdb.org/services/rest/enrichment/overrepresentation" > panther_response.json

    if [ -s "panther_response.json" ] && [ "\$(jq '.results | has("result")' panther_response.json)" == "true" ]; then
        # Create header
        echo -e "id\\tnumber_in_list\\texpected\\tnumber_in_reference\\tplus_minus\\tfdr\\tlabel" > "${sample_id}.panther_results.tsv"
        # Parse JSON and append to file
        jq -r '.results.result[] | [.term.id, .number_in_list, .expected, .number_in_reference, .plus_minus, .fdr, .term.label] | @tsv' panther_response.json >> "${sample_id}.panther_results.tsv"
    else
        # If no results, create an empty file with just a header
        echo -e "id\\tnumber_in_list\\texpected\\tnumber_in_reference\\tplus_minus\\tfdr\\tlabel" > "${sample_id}.panther_results.tsv"
    fi
    """
}
