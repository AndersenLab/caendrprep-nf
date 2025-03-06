//
// Generate phylogenetic tree from vcf
//

include { BIOCONVERT_VCF_TO_STOCKHOLM } from "../modules/bioconvert/vcf_to_stockholm/main"
include { QUICKTREE_MAKE_TREE         } from "../modules/quicktree/make_tree/main"
include { R_PLOT_TREE                 } from "../modules/r/plot_tree/main"

workflow VCF_MAKE_TREE {
    take:
    ch_vcf  // channel: [ val(meta), path(vcf), path(vcf_index) ]

    main:
    ch_versions = Channel.empty()

    // Convert vcf file to stockholm format for building tree
    BIOCONVERT_VCF_TO_STOCKHOLM( ch_vcf,
                                 Channel.fromPath("${workflow.projectDir}/bin/vcf2phylip.py") )
    ch_versions = ch_versions.mix(BIOCONVERT_VCF_TO_STOCKHOLM.out.versions)

    // Generate phylogenetic tree
    QUICKTREE_MAKE_TREE( BIOCONVERT_VCF_TO_STOCKHOLM.out.stockholm )
    ch_versions = ch_versions.mix(QUICKTREE_MAKE_TREE.out.versions)

    // Plot phylogenetic tree
    R_PLOT_TREE( QUICKTREE_MAKE_TREE.out.tree,
                 Channel.fromPath("${workflow.projectDir}/bin/plot_tree.R") )
    ch_versions = ch_versions.mix(R_PLOT_TREE.out.versions)

    emit:
    tree      = QUICKTREE_MAKE_TREE.out.tree  // channel: [ val(meta1), path(tree1) ], [ val(meta2), path(tree2) ]
    tree_plot = R_PLOT_TREE.out.plot          // channel: [ val(meta1), path(plot1) ], [ val(meta2), path(plot2) ]
    versions  = ch_versions                   // channel: val(version1), val(version2)...
}