process R_PLOT_HAPLOTYPE {

    label 'r_plot_haplotype'

    input:
        path ibd_files
        path plot_script

    output:
        path "haplotype_df_isotype.bed",                                              emit: nemascan
        tuple path("*.Rda"), path("*.png"), path("*.pdf"), path("sweep_summary.tsv"), emit: haplotype
        path "versions.yml",                                                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cat *.ibd > haplotype.tsv

    Rscript --vanilla ${plot_script} haplotype.tsv
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """

    stub:
    """
    touch complete_hap_counts.Rda
    touch complete_chromosome_haps.Rda
    touch complete_metled_haps.Rda
    touch complete_sorted_strains.Rda
    touch colorscheme.Rda
    touch processed_haps.Rda
    touch haplotype_df_isotype.bed
    touch haplotype_plot_df.Rda
    touch haplotype.pdf
    touch haplotype.png
    touch sweep.pdf
    touch sweep.png
    touch sweep_summary.tsv
    touch haplotype_length.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """
}
