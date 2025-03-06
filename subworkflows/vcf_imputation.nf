//
// Impute missing genotypes in VCF
//

include { LOCAL_GET_CONTIG_INFO       } from "../modules/local/get_contig_info/main"
include { BEAGLE_IMPUTATION           } from "../modules/beagle/imputation/main"
include { BCFTOOLS_CONCAT_IMPUTED     } from "../modules/bcftools/concat_imputed/main"

workflow VCF_IMPUTATION {
    take:
    ch_snv_vcf  // channel: [ val(meta), path(snv_vcf), path(snv_vcf_index) ]
    window      // val: window
    overlap     // val: overlap
    map_dir     // path: /path/to/LD_contig_maps

    main:
    ch_versions = Channel.empty()

    LOCAL_GET_CONTIG_INFO( ch_snv_vcf )
    ch_contig_map = LOCAL_GET_CONTIG_INFO.out.contigs
        .map{ contig -> [contig, path("${map_dir}/chr${contig}.map")]}

    // Impute genotypes
    BEAGLE_IMPUTATION( ch_snv_vcf.first(),
                       ch_contig_map,
                       window,
                       overlap )
    ch_versions = ch_versions.mix(BEAGLE_IMPUTATION.out.versions)

    // Concatenate imputed genotypes
    ch_imputed = BEAGLE_IMPUTATION.out.imputed
        .flatten()
        .toSortedList()
    BCFTOOLS_CONCAT_IMPUTED( ch_imputed )
    ch_versions = ch_versions.mix(BCFTOOLS_CONCAT_IMPUTED.out.versions)
    ch_imputed_vcf = BCFTOOLS_CONCAT_IMPUTED.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    emit:
    imputed_vcf   = ch_imputed_vcf                    // channel: [ val(meta1), path(vcf), path(vcf_index) ]
    imputed_stats = BCFTOOLS_CONCAT_IMPUTED.out.stats // val: stats
    versions      = ch_versions                       // channel: val(version1), val(version2)...
}