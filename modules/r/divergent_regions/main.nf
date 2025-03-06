    process R_DIVERGENT_REGIONS {

    label 'r_divergent_regions'

    input:
        tuple val(metas), path(mask_dfs)
        path reoptimized_divergent_region_script
        path contig_lengths
        path contig_bins

        tuple val(meta), path(bam), path(bam_index)
        tuple val(meta1), path(vcf), path(index)
        path bin_file

    output:
        tuple path("divergent_regions_strain.bed"), path("divergent_regions_all.bed"), path("divergent_regions.png"), emit: divergent
        tuple path("divergent_bins.bed"), path("divergent_df_isotype.bed"),                                           emit: nemascan
        path "versions.yml",                                                                                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    # files for NemaScan
    cp ${contig_lengths} ./df_chr_lengths.tsv
    cp ${contig_bins} ./divergent_bins.bed

    Rscript -e "rmarkdown::render('${reoptimized_divergent_region_script}')"

    # gzip divergent files
    cp All_divergent_regions.tsv divergent_regions_all.bed
    cp divergent_regions_strain.bed ./divergent_df_isotype.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """

    stub:
    """
    touch divergent_output_all_strains_all_bins.tsv
    touch df_divergent_final.tsv
    touch DataS3_divergent_regions_isotypes.csv
    touch divergent_regions_strain.bed
    touch divergent_classification.RData
    touch Common_divergent_regions.tsv
    touch Intermediate_divergent_regions.tsv
    touch Rare_divergent_regions.tsv
    touch All_divergent_regions.tsv
    touch divergent_regions_all.bed
    touch Common_divergent_regions_clustered.tsv
    touch Intermediate_divergent_regions_clustered.tsv
    touch Rare_divergent_regions_clustered.tsv
    touch All_divergent_regions_clustered.tsv
    touch divergent_regions.png
    touch divergent_regions_all.bed
    touch divergent_df_isotype.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$( Rscript --version |& cut -f 4' )
    END_VERSIONS
    """
}