process DOWNLOAD_HUMAN_GENOME {
    label 'process_low'
    conda 'conda-forge::wget=1.21.4'

    output:
    path("human_genome.fasta"), emit: fasta

    script:
    """
    wget --no-check-certificate -O human_genome.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.29_GRCh38.p14/GCA_000001405.29_GRCh38.p14_genomic.fna.gz"
    
    gunzip human_genome.fasta.gz
    """
}


process DOWNLOAD_BACTERIAL_REFERENCE {
    label 'process_low'
    // **FIXED**: Pointing to the correct conda-forge channel for wget
    conda 'conda-forge::wget=1.21.4'

    output:
    path("bacterial_ref.fasta"), emit: fasta

    script:
    """
    wget -O bacterial_ref.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/904/859/905/GCF_904859905.1_MSB1_1H/GCF_904859905.1_MSB1_1H_genomic.fna.gz"
    gunzip bacterial_ref.fasta.gz
    """
}

process INDEX_GENOME {
    label 'process_medium'
    conda 'bioconda::bwa=0.7.17'

    input:
    path(fasta_in)

    output:
    path("${fasta_in.baseName}.*"), emit: index

    script:
    """
    bwa index ${fasta_in}
    """
}
