//
// Post-process VCF files, filtering and splitting into various smaller versions
//

include { BCFTOOLS_EXTRACT_ISOTYPES      } from '../modules/bcftools/extract_isotypes/main'
include { BCFTOOLS_EXTRACT_ISOTYPES as BCFTOOLS_EXTRACT_ISOTYPES_SOFT } from '../modules/bcftools/extract_isotypes/main'
include { BCFTOOLS_STRIP_NONGENOTYPES    } from '../modules/bcftools/strip_nongenotypes/main'
include { BCFTOOLS_SNV_ONLY              } from '../modules/bcftools/snv_only/main'
include { BCFTOOLS_EXTRACT_SAMPLE        } from '../modules/bcftools/extract_sample/main'


workflow VCF_POSTPROCESSING { 
    take:
    ch_hard_vcf         // channel: [ val(meta), path(vcf), path(vcf_index) ]
    ch_soft_vcf         // channel: [ val(meta), path(vcf), path(vcf_index) ]
    ch_all_strains      // channel: val(strain1), val(strain2), ...
    ch_isotype_strains  // channel: val(strain1), val(strain2), ...

    main:
    ch_versions = Channel.empty()

    // Make hard-filtered isotype reference-only VCF
    ch_isotype_strain_file = ch_isotype_strains.collectFile(name: "isotypes.txt", newLine: true, sort: true)
    BCFTOOLS_EXTRACT_ISOTYPES( ch_hard_vcf,
                               ch_isotype_strain_file )
    ch_versions = ch_versions.mix(BCFTOOLS_EXTRACT_ISOTYPES.out.versions)
    ch_isotype_vcf = BCFTOOLS_EXTRACT_ISOTYPES.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    // Make soft-filtered isotype reference-only VCF
    BCFTOOLS_EXTRACT_ISOTYPES_SOFT( ch_soft_vcf,
                                    ch_isotype_strain_file )
    ch_versions = ch_versions.mix(BCFTOOLS_EXTRACT_ISOTYPES_SOFT.out.versions)
    ch_soft_isotype_vcf = BCFTOOLS_EXTRACT_ISOTYPES_SOFT.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    // Make small version of hard-filtered isotype reference VCF
    BCFTOOLS_STRIP_NONGENOTYPES( ch_isotype_vcf )
    ch_versions = ch_versions.mix(BCFTOOLS_STRIP_NONGENOTYPES.out.versions)
    ch_geno_isotype_vcf = BCFTOOLS_STRIP_NONGENOTYPES.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    // Make SNV-only hard-filtered isotype reference VCF
    BCFTOOLS_SNV_ONLY( ch_isotype_vcf )
    ch_versions = ch_versions.mix(BCFTOOLS_SNV_ONLY.out.versions)
    ch_snv_isotype_vcf = BCFTOOLS_SNV_ONLY.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    // Split hard-filtered VCF into individual strain VCFs
    BCFTOOLS_EXTRACT_SAMPLE( ch_hard_vcf.first(),
                             ch_all_strains )
    ch_versions = ch_versions.mix(BCFTOOLS_EXTRACT_SAMPLE.out.versions)
    ch_strain_vcf = BCFTOOLS_EXTRACT_SAMPLE.out.vcf.map{ row -> [[id: row[0]], row[1], row[2]]}

    emit:
    isotype_vcf       = ch_isotype_vcf       // channel: [ val(meta), path(vcf), path(vcf_index) ]
    soft_isotype_vcf  = ch_soft_isotype_vcf  // channel: [ val(meta), path(vcf), path(vcf_index) ]
    small_isotype_vcf = ch_geno_isotype_vcf  // channel: [ val(meta), path(vcf), path(vcf_index) ]
    snv_isotype_vcf   = ch_snv_isotype_vcf   // channel: [ val(meta), path(vcf), path(vcf_index) ]
    strain_vcfs       = ch_strain_vcf        // channel: [ val(meta1), path(vcf1), path(vcf1_index) ], ...
    versions          = ch_versions          // channel: val(version1), val(version2)...
}
