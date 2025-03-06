process SMARTPCA_EIGENSTRAT_WITHOUT_OUTLIERS {

    label 'smartpca_eigenstrat_without_outliers'

    input:
    tuple val(meta), path("eigenstrat_input.ped"), path("eigenstrat_input.bim"), path("plink.prune.in"), path("eigenstrat_markers.txt"), \
          path("eigenstrat_input.pedsnp"), path("eigenstrat_input.pedind"), path("sorted_samples.txt"), val(num_outliers)
    path eigenparameters
    path "edit_outlier_params.sh"

    output:
    tuple val(meta), val(num_outliers), path("eigenstrat_outliers_removed.evac"), path("eigenstrat_outliers_removed.eval"), \
          path("logfile_outlier.txt"), path("eigenstrat_outliers_removed_relatedness"), \
          path("eigenstrat_outliers_removed_relatedness.id"), path("TracyWidom_statistics_outliers_removed.tsv"), emit: pca
    path "versions.yml",                                                                                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bash edit_outlier_params.sh -f ${eigenparameters} -n ${num_outliers}

    smartpca -p outlier_eigpar > logfile_outlier.txt

    sed -n -e '/Tracy/,\$p' logfile_outlier.txt |\
    sed -e '/kurt/,\$d' |\
    awk '\$0 !~ "##" && \$0 !~ "#" {print}' |\
    sed -e "s/[[:space:]]\\+/ /g" |\
    sed 's/^ //g' |\
    awk 'BEGIN{print "N", "eigenvalue", "difference", "twstat", "p-value", "effect.n"}; {print}' OFS="\\t" |\
    awk -F" " '\$1=\$1' OFS="\\t" > TracyWidom_statistics_outlier_removal.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        smartpca: \$( smartpca |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """

    stub:
    """
    touch "eigenstrat_outliers_removed.evac
    touch "eigenstrat_outliers_removed.eval
    touch logfile_outlier.txt
    touch eigenstrat_outliers_removed_relatedness
    touch eigenstrat_outliers_removed_relatedness.id
    touch TracyWidom_statistics_outliers_removed.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        smartpca: \$( smartpca |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """
}