//
// Call indels from bam files with Delly
//

include { DELLY_CALL_INDELS   } from "./modules/delly/call_indels/main"
include { DELLY_FILTER_INDELS } from "./modules/delly/filter_indels/main"
include { BCFTOOLS_BCF_TO_VCF } from "./modules/bcftools/bcf_to_vcf/main"

workflow CALL_DELLY_INDELS{
    take:    
    ch_genome       // channel: [ val(meta), path(fasta), path(fasta_index) ]
    ch_all_strains  // channel: strain1, strain2, ...
    bam_dir         // path: /path/to/bams
    ref_strain      // val: name_of_reference_strain
    minsize         // val: minimum_indel_size
    maxsize         // val: maximum_indel_size

    main:
    ch_versions = Channel.empty()

    // Pull isotypes from sample sheet, removing reference strain from isotype reference strain list
    ch_nonref_strains = ch_all_strains
        .filter{ row -> row != ref_strain}

    // Create bam channel with paths and indices
    ch_bams = ch_nonref_strains
        .map( strain -> [[id: strain], "${bam_dir}/${strain}.bam", "${bam_dir}/${strain}.bam.bai"])

    ch_ref_bam = Channel.of([[id: ref_strain], "${bam_dir}/${ref_strain}.bam", "${bam_dir}/${ref_strain}.bam.bai"])

    // Call indels
    DELLY_CALL_INDELS( ch_bams,
                       ch_ref_bam,
                       ch_genome )
    ch_versions = ch_versions.mix(DELLY_CALL_INDELS.out.versions)
    ch_raw_indel_vcf = DELLY_FILTER_INDELS.out.filtered.map{ row -> [[id: row[0]], row[1], row[2]]}

    // Filter indels
    DELLY_FILTER_INDELS( ch_raw_indel_vcf,
                         ref_strain,
                         minsize,
                         maxsize )
    ch_versions = ch_versions.mix(DELLY_FILTER_INDELS.out.versions)

    // Convert from bcf to vcf
    BCFTOOLS_BCF_TO_VCF( DELLY_FILTER_INDELS.out.filtered )
    ch_versions = ch_versions.mix(BCFTOOLS_BCF_TO_VCF.out.versions)
    ch_indel_vcf = BCFTOOLS_BCF_TO_VCF.out.vcf.collect()

    emit:
    indels   = ch_indel_vcf  // channel: [ val(meta1), path(vcf1), path(vcf1_index) ], [ val(meta2), path(vcf2), path(vcf2_index) ], ...
    versions = ch_versions   // channel: val(version1), val(version2)...
}