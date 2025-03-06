process DELLY_FILTER_INDELS {

    tag "${meta.id}"
    label "delly_filter_indels"

    input:
        tuple val(meta), path(indels), path(indels_index)
        val reference
        val minsize
        val maxsize
        
    output:
        tuple val(meta), path("${meta.id}.isotype.bcf"), path("${meta.id}.isotype.bcf.csi"), emit: filtered
        path "versions.yml",                                                                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo -e "${reference}\tcontrol\n${meta.id}\ttumor" > samples.tsv
    delly filter -f somatic -o ${meta.id}.isotype.bcf -a 0.75 -p -m ${minsize} -n ${maxsize} -s samples.tsv ${indels_bcf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(echo \$(delly --version 2>&1 | head -n 1) | sed 's/^Delly version: //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_indels_filtered.bcf
    touch ${meta.id}_indels_filtered.bcf.csi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(echo \$(delly --version 2>&1 | head -n 1) | sed 's/^Delly version: //')
    END_VERSIONS
    """
}
