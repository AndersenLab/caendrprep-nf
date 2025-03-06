process R_PLOT_TREE {

    label 'r_plot_tree'

    input:
        path tree,
        path plot_tree

    output:
        path "*.pdf",          emit: plot
        path "versions.yml",   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    Rscript --vanilla ${plot_tree} ${tree}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """

    stub:
    """
    touch ${tree}.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """
}
