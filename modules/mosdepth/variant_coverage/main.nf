    process MOSDEPTH_VARIANT_COVERAGE {

    label 'mosdepth_variant_coverage'

    input:
        tuple val(meta), path(bam), path(index)
        path bin_file


    output:
        tuple val(meta), path("${meta.id}.regions.bed.gz"), emit: coverage
        path "versions.yml",                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """    
    # need to use the isotype ref strain here, not the isotype strain!
    mosdepth -b ${bin_file} ${meta.id} ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mosdepth: \$( mosdepth --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_Mask_DF.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mosdepth: \$( mosdepth --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}