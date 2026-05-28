process DOWNLOAD_BACTERIAL_REFERENCE {
    tag "Downloading Bacterial Reference"
    label 'process_low'
    conda 'conda-forge::wget=1.21.4'

    output: path("bacterial_ref.fasta"), emit: fasta
    script:
    """
    wget --no-check-certificate -O bacterial_ref.fasta.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/045/GCF_000009045.1_ASM904v1/GCF_000009045.1_ASM904v1_genomic.fna.gz"
    gunzip bacterial_ref.fasta.gz
    """
}

process INDEX_GENOME {
    tag "Indexing ${fasta_in.baseName}"
    label 'process_medium'
    conda 'bioconda::bwa=0.7.17'

    input: path(fasta_in)
    output: path("${fasta_in.baseName}.*"), emit: index

    script: 
    """
    bwa index ${fasta_in}
    """
}

process PREPARE_PLASMIDFINDER_DB {
    tag "Preparing PlasmidFinder database"
    label 'process_low'
    conda 'conda-forge::git conda-forge::python=3.9 bioconda::kma'

    output: path "plasmidfinder_db"

    script:
    """
    git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git
    cd plasmidfinder_db
    python3 INSTALL.py kma_index
    """
}

process INITIALIZE_AMRFINDER_DB {
    tag "Initializing AMRFinderPlus database"
    label 'process_low'
    conda 'bioconda::ncbi-amrfinderplus'

    output:
    path "amrfinder.ready"

    script:
    """
    amrfinder --update
    touch amrfinder.ready
    """
}
