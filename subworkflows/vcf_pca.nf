//
// Run PCA analysis
//

include { LOCAL_GET_CONTIG_INFO                } from "../modules/local/get_contig_info/main"
include { BCFTOOLS_FILTER_MISSING_GENOTYPES    } from '../modules/bcftools/filter_missing_genotypes/main'
include { VCFTOOLS_GET_SINGLETONS              } from '../modules/vcftools/get_singletons/main'
include { PLINK_MAKE_EIGENSTRAT                } from '../modules/plink/make_eigenstrat/main'
include { SMARTPCA_EIGENSTRAT_WITH_OUTLIERS    } from '../modules/smartpca/eigenstrat_with_outliers/main'
include { SMARTPCA_EIGENSTRAT_WITHOUT_OUTLIERS } from '../modules/smartpca/eigenstrat_without_outliers/main'

workflow VCF_PCA { 
    take:
    ch_snv_vcf         // channel: [ val(meta), path(snv_vcf), path(snv_vcf_index) ]
    ch_isotype_strains // channel: val(strain1), val(strain2), ...
    ld_range           // val: ld_range_csv_list
    outlier_its        // val: outlier_iteration_csv_list
    singletons         // bool

    main:
    ch_versions = Channel.empty()

    LOCAL_GET_CONTIG_INFO( ch_snv_vcf )

    // Filter SNVs with missing genotypes
    BCFTOOLS_FILTER_MISSING_GENOTYPES( ch_snv_vcf )
    ch_versions = ch_versions.mix(BCFTOOLS_FILTER_MISSING_GENOTYPES.out.versions)

    if (singletons) {
      // Get VCF singletons
      VCFTOOLS_GET_SINGLETONS( BCFTOOLS_FILTER_MISSING_GENOTYPES.out.vcf )
      ch_versions = ch_versions.mix(VCFTOOLS_GET_SINGLETONS.out.versions)

      ch_singletons = VCFTOOLS_GET_SINGLETONS.out.singletons
    } else {
      ch_singletons = Channel.empty().collectFile(name: "blank_snps.txt")
    }
     
    // Filter out MtDNA and normalize vcf
    BCFTOOLS_CE_NORM( BCFTOOLS_FILTER_MISSING_GENOTYPES.out.vcf,
                      LOCAL_GET_CONTIG_INFO.out.contigs )
    ch_versions = ch_versions.mix(BCFTOOLS_CE_NORM.out.versions)

    // Create plink eigenstrat file
    ch_ld_range = Channel.of(ld_range).splitCsv().collate(1)
    PLINK_MAKE_EIGENSTRAT( BCFTOOLS_CE_NORM.out.vcf,
                           ch_ld_range,
                           ch_contig_file,
                           ch_singletons )
    ch_versions = ch_versions.mix(PLINK_MAKE_EIGENSTRAT.out.versions)

    // Reformat plink files
    BCFTOOLS_PREP_EIGENSTRAT( BCFTOOLS_CE_NORM.out.vcf,
                              PLINK_MAKE_EIGENSTRAT.out.plink,
                              LOCAL_GET_CONTIG_INFO.out.contigs )
    ch_versions = ch_versions.mix(BCFTOOLS_PREP_EIGENSTRAT.out.versions)
    ch_eigenstrat = PLINK_MAKE_EIGENSTRAT.out.plink
      .join(BCFTOOLS_PREP_EIGENSTRAT.out.ped)
      .map{ row -> [[ld: row[1]], row[2], row[3], row[4], row[5], row[6], row[7], row[8]] }

    // Run eigenstrat without outlier removal
    SMARTPCA_EIGENSTRAT_WITH_OUTLIERS( ch_eigenstrat,
                                       Channel.fromPath("${workflow.projectDir}/data/eigpar_no_removal") )
    ch_versions = ch_versions.mix(SMARTPCA_EIGENSTRAT_WITH_OUTLIERS.out.versions)

    // Run eigenstrat with outlier removal
    ch_outlier_its = Channel.fromPath(outlier_its).splitCsv().collate(1)
    ch_eigenstrat_its = ch_eigenstrat.combine(ch_outlier_its)
    SMARTPCA_EIGENSTRAT_WITHOUT_OUTLIERS( ch_eigenstrat_its,
                                          Channel.fromPath("${workflow.projectDir}/data/eigpar"),
                                          Channel.fromPath("${workflow.projectDir}/bin/edit_outlier_param.sh"),
                                          num_outliers )
    ch_versions = ch_versions.mix(SMARTPCA_EIGENSTRAT_WITHOUT_OUTLIERS.out.versions)
    ch_eigenstrat_wo_outliers = SMARTPCA_EIGENSTRAT_WITHOUT_OUTLIERS.out.pca.map{ row -> [[ld: row[1].id, outlier: row[2]], row[3], row[4], row[5], row[6], row[7], row[8]] }

    emit:
    eigenstrat         = ch_eigenstrat               // channel: [ val(meta1), path(ped1), ... ], [ val(meta2), path(ped2), ... ], ...
    pca_w_outliers     = ch_eigenstrat_w_outliers    // channel: [ val(meta1), path(evac1), ... ], [ val(meta2), path(evac2), ... ], ...
    pca_wo_outliers    = ch_eigenstrat_wo_outliers   // channel: [ val(meta1), path(evac1), ... ], [ val(meta2), path(evac2), ... ], ...
    versions           = ch_versions                 // channel: val(version1), val(version2)...
}