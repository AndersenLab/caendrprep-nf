process QUICKTREE_MAKE_TREE {

    tag "${meta.id}"
    label 'quicktree_make_tree'

    input:
        path stockholm

    output:
        path "*.tree",         emit: tree
        path "versions.yml",   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    output_tree=`echo ${stockholm} | sed 's/.stockholm/.tree/'`

    quicktree -in a -out t ${stockholm} > \${output_tree}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quicktree: \$( quicktree -v |& cut -f 2 )
    END_VERSIONS
    """

    stub:
    """
    output_tree=`echo ${stockholm} | sed 's/.stockholm/.tree/'`
    touch \${output_tree}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quicktree: \$( quicktree -v |& cut -f 2 )
    END_VERSIONS
    """
}
