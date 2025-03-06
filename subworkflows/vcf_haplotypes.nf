//
// Find haplotypes from vcf file
//

include { LOCAL_GET_CONTIG_INFO       } from "../modules/local/get_contig_info/main"
include { JAVA_HAPLOTYPE_SWEEP_IBD    } from "../modules/java/haplotype_sweep_idb/main"
include { R_PLOT_HAPLOTYPE            } from "../modules/r/plot_haplotype/main"
include { BCFTOOLS_VARIANT_COVERAGE   } from "../modules/bcftools/variant_coverage/main"
include { R_DIVERGENT_REGIONS         } from "../modules/r/divergent_regions/main"

workflow VCF_HAPLOTYPES {
    take:
    ch_vcf             // channel: [ val(meta), path(vcf), path(vcf_index) ]
    ch_isotype_strains // channel: val(strain1), val(strain2), ...
    bam_folder         // val bam_folder
    binsize            // val binsize

    main:
    ch_versions = Channel.empty()

    // Get contigs from vcf
    LOCAL_GET_CONTIG_INFO( ch_vcf,
                           binsize )
    ch_contig = LOCAL_GET_CONTIG_INFO.out.contigs.splitCsv()

    // Find haplotype sweeps
    JAVA_HAPLOTYPE_SWEEP_IBD( ch_vcf,
                              Channel.fromPath("${workflow.projectDir}/bin/ibdseq.r1206.jar"),
                              ch_contig )
    ch_versions = ch_versions.mix(JAVA_HAPLOTYPE_SWEEP_IBD.out.versions)
    ch_sweep_contigs = JAVA_HAPLOTYPE_SWEEP_IBD.out.sweep.collect()

    // Plot haplotype sweep
    R_PLOT_HAPLOTYPE( ch_sweep_contigs,
                      Channel.fromPath("${workflow.projectDir}/bin/process_ibd_nf_final.R") )
    ch_versions = ch_versions.mix(R_PLOT_HAPLOTYPE.out.versions)

    // Count variant coverage
    ch_isotype_bams = ch_isotype_strains.map{ strain -> [[id: strain], path("${bam_folder}/${strain}.bam"), path("${bam_folder}/${strain}.bam.bai")]] }
    BCFTOOLS_VARIANT_COVERAGE( ch_isotype_bams,
                               ch_vcf,
                               LOCAL_GET_CONTIG_INFO.out.partition )
    ch_versions = ch_versions.mix(BCFTOOLS_VARIANT_COVERAGE.out.versions)
    ch_mask_df = BCFTOOLS_VARIANT_COVERAGE.out.mask.collect()

    // Define divergent regions
    R_DIVERGENT_REGIONS( ch_mask_df,
                         Channel.fromPath("${workflow.projectDir}/bin/reoptimzied_divergent_region_characterization.Rmd") )
                         LOCAL_GET_CONTIG_INFO.out.lengths )
    ch_versions = ch_versions.mix(R_DIVERGENT_REGIONS.out.versions)

    emit:
    haplotype_sweeps  = ch_sweep_contigs                   // channel: path(contig1.ibd), path(contig2.ibd), ...
    haplotype_data    = R_PLOT_HAPLOTYPES.out.haplotype    // channel: [path(*.Rda), path(*.png), path(*.pdf), path(summary.tsv)]
    nemascan_data     = R_PLOT_HAPLOTYPES.out.nemascan     // channel: path(haplotype_df_isotype.bed)
    variant_coverage  = ch_mask_df                         // channel: path(mask1.tsv), path(mask2.tsv), ...
    divergent_regions = R_DIVERGENT_REGIONS.out.divergent  // channel: [path(strain.bed), path(all.bed), path(plot.png)]
    nemascan_regions  = R_DIVERGENT_REGIONS.out.nemascan   // channel: [path(divergent_bins.bed), path(df_isotype.bed)]
    region_plot       = R_DIVERGENT_REGIONS.out.plot       // channel: path(plot.png)
    versions          = ch_versions                        // channel: val(version1), val(version2)...
}