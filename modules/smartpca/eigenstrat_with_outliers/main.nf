process SMARTPCA_EIGENSTRAT_WITH_OUTLIERS {

    label 'smartpca_eigenstrat_with_outliers'

    input:
    tuple val(meta), path("eigenstrat_input.ped"), path("eigenstrat_input.bim"), path("plink.prune.in"), path("eigenstrat_markers.txt"), \
          path("eigenstrat_input.pedsnp"), path("eigenstrat_input.pedind"), path("sorted_samples.txt")
    path eigenparameters

    output:
    tuple val(meta), path("eigenstrat_no_removal.evac"), path("eigenstrat_no_removal.eval"), path("logfile_no_removal.txt"), \
          path("eigenstrat_no_removal_relatedness"), path("eigenstrat_no_removal_relatedness.id"), path("TracyWidom_statistics_no_removal.tsv"), emit: pca
    path "versions.yml",                                                                                                                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    smartpca -p ${eigenparameters} > logfile_no_removal.txt

    sed -n -e '/Tracy/,\$p' logfile_no_removal.txt |\
    sed -e '/kurt/,\$d' |\
    awk '\$0 !~ "##" && \$0 !~ "#" {print}' |\
    sed -e "s/[[:space:]]\\+/ /g" |\
    sed 's/^ //g' |\
    awk 'BEGIN{print "N", "eigenvalue", "difference", "twstat", "p-value", "effect.n"}; {print}' OFS="\\t" |\
    awk -F" " '\$1=\$1' OFS="\\t" > TracyWidom_statistics_no_removal.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        smartpca: \$( smartpca |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """

    stub:
    """
    touch "eigenstrat_no_removal.evac
    touch "eigenstrat_no_removal.eval
    touch logfile_no_removal.txt
    touch eigenstrat_no_removal_relatedness
    touch eigenstrat_no_removal_relatedness.id
    touch TracyWidom_statistics_no_removal.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        smartpca: \$( smartpca |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """
}