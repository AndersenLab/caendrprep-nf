process DELLY_CALL_INDELS {

    tag "${meta.id}"
    label "delly_call_indels"

    input:
        tuple val(meta),  path(bam),     path(bam_index)
        tuple val(meta1), path(ref_bam), path(ref_bam_index)
        tuple val(meta2), path(genome),  path(genome_index)

    output:
        tuple val("indel"), path("${meta.id}_indels_unfiltered.bcf"), path("${meta.id}_indels_unfiltered.bcf.csi"), emit: indels
        path "versions.yml",                                                                                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    delly call -q 20 -g ${genome} -o ${meta.id}_indels_unfiltered.bcf ${bam} ${ref_bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(echo \$(delly --version 2>&1 | head -n 1) | sed 's/^Delly version: //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_indels.unfiltered.bcf
    touch ${meta.id}_indels.unfiltered.bcf.csi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(echo \$(delly --version 2>&1 | head -n 1) | sed 's/^Delly version: //')
    END_VERSIONS
    """
}
