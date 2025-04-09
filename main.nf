#!/usr/bin/env nextflow 
/*
    Authors:
    - Dan Lu <dan.lu@northwestern.edu>
    - Katie Evans <katiesevans9@gmail.com>
    - Mike Sauria <mike.sauria@gmail.com>
*/

nextflow.enable.dsl=2

// Needed to publish results
nextflow.preview.output = true

date = new Date().format( 'yyyyMMdd' )

def getGenomeAttribute(attribute, subworkflows, required=true) {
    if (params.genomes && params.species && params.genomes.containsKey(params.species)) {
        if (params.genomes[ params.species ].containsKey(attribute)) {
            return params.genomes[ params.species ][ attribute ]
        } else if (required) {
            println "${attribute} is missing from genome map, needed for running ${subworkflows}"
            exit 1
        }
    } else if (required == true) {
        println "Must have --species defined and present in --genomes map"
        exit 1
    }
    return null
}

if (params.debug == false) {
    if (params.skip_delly == false || params.skip_haplotypes == false){
        if (params.bam_dir != null) {
            bam_dir = params.bam_dir
        } else {
            bam_dir = getGenomeAttribute("bam_dir", "delly")
        }
    } else {
        bam_dir = null
    }

    if (params.skip_delly == false || params.skip_pca == false || params.skip_postprocessing == false || params.skip_haplotypes == false){
        if (params.isotype_groups != null) {
            isogroups = params.isotype_groups
        } else {
            concordance_dir = getGenomeAttribute("concordance_dir", "postprocessing, delly, haplotypes, and pca")
            if (params.release != null) {
                isogroups = "${concordance_dir}/${params.release}/isotype_groups.tsv"
            } else {
                println "A valid release date must be specified with --release"
                exit 1
            }
        }
    } else {
        isogroups = null
    }

    if ((params.skip_haplotypes == false || params.skip_tree == false) && params.skip_postprocessing == true){
        if (params.isotype_vcf != null) {
            isotype_vcf = params.isotype_vcf
        } else if (params.skip_haplotypes == false) {
            variation_dir = getGenomeAttribute("variation_dir", "haplotypes")
            if (params.release != null) {
                isotype_vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.hard-filter.isotype.vcf.gz"
            } else {
                println "A valid release date must be specified with --release"
                exit 1
            }
        } else {
            variation_dir = getGenomeAttribute("variation_dir", "haplotypes", false)
            if (params.release != null) {
                isotype_vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.hard-filter.isotype.vcf.gz"
            } else {
                isotype_vcf = null
            }
        }
    } else {
        isotype_vcf = null
    }

    if (params.skip_tree == false || params.skip_postprocessing == false) {
        if (params.hard_vcf != null) {
            hard_vcf = params.hard_vcf
        } else {
            if ((params.skip_tree == false && isotype_vcf == null) || params.skip_postprocessing == false) {
                variation_dir = getGenomeAttribute("variation_dir", "haplotypes")
            } else {
                variation_dir = getGenomeAttribute("variation_dir", "haplotypes", false)
            }
            if (params.release != null && variation_dir != null) {
                hard_vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.hard-filter.vcf.gz"
            } else {
                hard_vcf = null
            }
            if (params.skip_postprocessing == false && hard_vcf == null) {
                println "For running the postprocessing analysis, specify a full hard-filtered vcf"
            }
            if (params.skip_tree == false && isotype_vcf == null && hard_vcf == null) {
                println "For running the tree analysis, specify a full hard-filtered vcf, isotype reference only hard-filtered vcf, or both"
            }
        }
    } else {
        hard_vcf = null
    }

    if (params.skip_postprocessing == true && (params.skip_pca == false || params.skip_imputation == false)) {
        if (params.snv_vcf != null) {
            snv_vcf = params.snv_vcf
        } else {
            variation_dir = getGenomeAttribute("variation_dir", "haplotypes")
            if (params.release != null) {
                snv_vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.hard-filter.isotype.SNV.vcf.gz"
            } else {
                println "A valid release date must be specified with --release"
                exit 1
            }
        }
    } else {
        snv_vcf = null
    }

    if (params.skip_postprocessing == false) {
        if (params.soft_vcf != null) {
            soft_vcf = params.soft_vcf
        } else {
            variation_dir = getGenomeAttribute("variation_dir", "haplotypes")
            if (params.release != null) {
                soft_vcf = "${variation_dir}/${params.release}/vcf/WI.${params.release}.soft-filter.vcf.gz"
            } else {
                println "A valid release date must be specified with --release"
                exit 1
            }
        }
    } else {
        soft_vcf = null
    }

    if (params.skip_imputation == false) {
        if (params.map_dir != null) {
            map_dir = params.map_dir
        } else if (params.species == 'c_elegans') {
            map_dir = "${workflow.projectDir}/data/c_elegans"
        } else if (params.species == 'c_briggsae') {
            map_dir = "${workflow.projectDir}/data/c_briggsae"
        } else if (params.species == 'c_tropicalis') {
            map_dir = "${workflow.projectDir}/data/c_tropicalis"
        } else {
            println "The directory for the imputation map directory must be specified with --map_dir for non-CaeNDR species"
            exit 1
        }
    } else {
        map_dir = null
    }

    if (params.skip_delly == false) {
        if (params.ref_strain != null) {
            ref_strain = params.ref_strain
        } else {
            ref_strain = getGenomeAttribute("ref_strain", "delly")
        }
        if (params.reference != null) {
            reference = params.reference
        } else {
            reference = getGenomeAttribute("fasta", "delly")
        }
    } else {
        ref_strain = null
        reference = null
    }

    if (params.skip_haplotypes == false && params.skip_postprocessing == true){
        if (params.strain_vcf_dir != null) {
            strain_vcf_dir = params.strain_vcf_dir
        } else {
            variant_dir = getGenomeAttribute("variation_dir", "haplotypes")
            if (params.release != null) {
                strain_vcf_dir = "${variant_dir}/${params.release}/vcf/strain_vcf"
            } else {
                println "A valid release date must be specified with --release"
                exit 1
            }
        }
    } else {
        strain_vcf_dir = null
    }

}

def log_summary() {
/*
    Generates a log
*/

out = """

Build trees, define haplotypes and divergent regions.

   ______           _   ______  ____                                    ____
  / ____/___ ____  / | / / __ \\/ __ \\____  ________  ____        ____  / __/
 / /   / __ `/ _ \\/  |/ / / / / /_/ / __ \\/ ___/ _ \\/ __ \\______/ __ \\/ /_  
/ /___/ /_/ /  __/ /|  / /_/ / _, _/ /_/ / /  /  __/ /_/ /_____/ / / / __/  
\\____/\\__,_/\\___/_/ |_/_____/_/ |_/ .___/_/   \\___/ .___/     /_/ /_/_/   
                                 /_/             /_/

nextflow main.nf --species=c_elegans --release=20250331 --ref_strain=N2

nextflow main.nf --isotype_groups=/path/to/groups --hard_isotype_vcf=/path/to/hard_isotype_vcf --full_vcf=/path/to/full_vcf --reference=/path/to/fasta --bam_dir=/path/to/bams --ref_strain=refstrain

    parameters           description                                              Set/Default
    ==========           ===========                                              ========================
    --debug               Set to 'true' to test                                   ${params.debug}
    --species             Species: 'c_elegans', 'c_tropicalis' or 'c_briggsae'    ${params.species}
    --release             CaeNDR release for genome lookup values                 ${params.release}
    --hard_vcf            Path to hard-filtered full VCF file                     ${hard_vcf}
    --isotype_vcf         Path to hard-filtered isotype VCF file                  ${isotype_vcf}
    --snv_vcf             Path to hard-filtered SNV-only VCF file                 ${snv_vcf}
    --isotype_groups      Path to isotype_groups file                             ${isogroups}
    --bam_dir             Path to folder containing bam files                     ${bam_dir}
    -output-dir           Output destination directory                            ${workflow.outputDir}

    Postprocessing parameters
    =========================
    --soft_vcf            Path to soft-filtered full VCF file                     ${soft_vcf}

    Haplotype parameters
    ====================
    --strain_vcf_dir      Path to folder containing strain vcf files              ${strain_vcf_dir}
    --binsize             Size to partition genome into for finding coverage      ${params.binsize}

    Imputation parameters
    ====================
    --map_dir             Directory containing contig LD maps                     ${map_dir}
    --window              Window size for Beagle imputation                       ${params.window}
    --overlap             Overlap size for Beagle imputation                      ${params.overlap}

    PCA parameters
    ==============
    --ld_range            Comma-separated list of LD cutoffs                      ${params.ld_range}
    --outlier_iterations  Comma-separated list of outlier iterations              ${params.outlier_iterations}
    --singletons          Boolean specifying whether to find singletons           ${params.singletons}

    Delly parameters
    ================
    --reference           Path to genome fasta file                               ${reference}
    --ref_strain          Reference strain name                                   ${ref_strain}
    --minsize             Minimum indel size                                      ${params.minsize}
    --maxsize             Maximum indel size                                      ${params.maxsize}

    Workflow parameters
    ===================
    --skip_postprocessing Skip running VCF postprocessing analysis                ${params.skip_postprocessing}
    --skip_haplotypes     Skip running VCF haplotye analysis                      ${params.skip_haplotypes}
    --skip_tree           Skip running VCF phylogenetic tree analysis             ${params.skip_tree}
    --skip_imputation     Skip running VCF imputation analysis                    ${params.skip_imputation}
    --skip_pca            Skip running VCF pca analysis                           ${params.skip_pca}
    --skip_delly          Skip running VCF delly analysis                         ${params.skip_delly}

    username                                                                      ${"whoami".execute().in.text}

    HELP: http://andersenlab.org/dry-guide/pipeline-CaeNDRprep   
    ----------------------------------------------------------------------------------------------
    Git info: $workflow.repository - $workflow.revision [$workflow.commitId] 
"""
out
}

log.info(log_summary())

if (params.help) {
    exit 1
}

// import the subworkflows
include { VCF_POSTPROCESSING } from './subworkflows/vcf_postprocessing'
include { VCF_HAPLOTYPES     } from './subworkflows/vcf_haplotypes'
// include { VCF_MAKE_TREE      } from './subworkflows/vcf_make_tree'
include { VCF_IMPUTATION     } from './subworkflows/vcf_imputation'
// include { VCF_PCA            } from './subworkflows/vcf_pca'
// include { CALL_DELLY_INDELS  } from './subworkflows/call_delly_indels'

workflow { 
    main:
    ch_versions = Channel.empty()

    // Created needed channels
    if (hard_vcf != null) {
        ch_hard_vcf = Channel.of([id: "hard"]).combine(Channel.fromPath(hard_vcf, checkIfExists: true)).combine(Channel.fromPath("${hard_vcf}.tbi", checkIfExists: true))
    } else {
        ch_hard_vcf = Channel.empty()
    }

    if (soft_vcf != null) {
        ch_soft_vcf = Channel.of([id: "soft"]).combine(Channel.fromPath(soft_vcf, checkIfExists: true)).combine(Channel.fromPath("${soft_vcf}.tbi", checkIfExists: true))
    }

    if (isotype_vcf != null) {
        ch_isotype_vcf = Channel.of([id: "hard_isotype"]).combine(Channel.fromPath(isotype_vcf, checkIfExists: true)).combine(Channel.fromPath("${isotype_vcf}.tbi", checkIfExists: true))
    } else if (params.skip_postprocessing == true) {
        ch_isotype_vcf = Channel.empty()
    }

    if (snv_vcf != null) {
        ch_snv_vcf = Channel.of([id: "snv"]).combine(Channel.fromPath(snv_vcf, checkIfExists: true)).combine(Channel.fromPath("${snv_vcf}.tbi", checkIfExists: true))
    }

    if (reference != null) {
        ch_genome_ch = Channel.of([id: params.species]).combine(Channel.fromPath(reference, checkIfExists: true)).combine(Channel.fromPath("${reference}.fai", checkIfExists))
    }

    if (isogroups != null) {
        ch_isogroups = Channel.fromPath(isogroups, checkIfExists: true).splitCsv(header: true, sep: "\t")
        ch_all_strains = ch_isogroups.map{ row -> row.strain }.unique()
        ch_isotype_strains = ch_isogroups.map{ row -> row.isotype_ref_strain }.unique()
    }

    if (strain_vcf_dir != null) {
        ch_strain_vcfs = ch_isotype_strains.map{ it -> [[id: it], "${strain_vcf_dir}/${it}.vcf.gz", "${strain_vcf_dir}/${it}.vcf.gz.tbi"] }
    }

    // Run postprocessing analysis
    if (params.skip_postprocessing == false) {
        VCF_POSTPROCESSING(
            ch_hard_vcf,
            ch_soft_vcf,
            ch_all_strains,
            ch_isotype_strains
        )
        ch_versions = ch_versions.mix(VCF_POSTPROCESSING.out.versions)
        ch_isotype_vcf = VCF_POSTPROCESSING.out.isotype_vcf
        ch_pub_isotype_vcf = VCF_POSTPROCESSING.out.isotype_vcf
        ch_snv_vcf = VCF_POSTPROCESSING.out.snv_isotype_vcf
        ch_pub_snv_vcf = VCF_POSTPROCESSING.out.snv_isotype_vcf
        ch_pub_soft_isotype_vcf = VCF_POSTPROCESSING.out.soft_isotype_vcf
        ch_pub_small_isotype_vcf = VCF_POSTPROCESSING.out.small_isotype_vcf
        ch_strain_vcfs = VCF_POSTPROCESSING.out.strain_vcfs
        ch_pub_strain_vcfs = ch_strain_vcfs
    } else {
        ch_pub_isotype_vcf = Channel.empty()
        ch_pub_snv_vcf = Channel.empty()
        ch_pub_soft_isotype_vcf = Channel.empty()
        ch_pub_small_isotype_vcf = Channel.empty()
        ch_pub_strain_vcfs = Channel.empty()
    }

    // Run haplotype analysis
    if (params.skip_haplotypes == false) {
        VCF_HAPLOTYPES(
            ch_isotype_vcf,
            ch_isotype_strains,
            ch_strain_vcfs,
            bam_dir,
            params.binsize
        )
        ch_versions = ch_versions.mix(VCF_HAPLOTYPES.out.versions)
        ch_pub_haplotype = VCF_HAPLOTYPES.out.haplotype_data
            .mix(VCF_HAPLOTYPES.out.haplotype_sweeps)
        ch_pub_nemascan = VCF_HAPLOTYPES.out.nemascan_data
            .mix(VCF_HAPLOTYPES.out.nemascan_regions)
        ch_pub_divergent = VCF_HAPLOTYPES.out.divergent_regions
        ch_pub_divergent_masks = VCF_HAPLOTYPES.out.variant_coverage
    } else {
        ch_pub_haplotype = Channel.empty()
        ch_pub_nemascan = Channel.empty()
        ch_pub_divergent = Channel.empty()
        ch_pub_divergent_masks = Channel.empty()
    }

    // // Run phylogenetic tree analysis
    // if (params.skip_tree == false) {
    //     VCF_MAKE_TREE(
    //         ch_hard_vcf.concat(ch_isotype_vcf)
    //     )
    //     ch_versions = ch_versions.mix(VCF_MAKE_TREE.out.versions)
    //     ch_pub_tree = VCF_MAKE_TREE.out.tree
    //         .mix(VCF_MAKE_TREE.out.tree_plot)
    // } else {
    //     ch_pub_tree = Channel.empty()
    // }

    // Run genotype imputation analysis
    if (params.skip_imputation == false) {
        VCF_IMPUTATION(
            ch_snv_vcf,
            params.window,
            params.overlap,
            map_dir
        )
        ch_versions = ch_versions.mix(VCF_IMPUTATION.out.versions)
        ch_pub_imputed = VCF_IMPUTATION.out.imputed_vcf
            .mix(VCF_IMPUTATION.out.imputed_stats)
    } else {
        ch_pub_imputed = Channel.empty()
    }

    // // Run VCF PCA analysis
    // if (params.skip_pca == false) {
    //     VCF_PCA(
    //         ch_snv_vcf,
    //         ch_isotype_strains,
    //         params.ld_range,
    //         params.outlier_iterations,
    //         params.singletons
    //     )
    //     ch_versions = ch_versions.mix(VCF_PCA.out.versions)
    //     ch_pub_eigenstrat = VCF_PCA.out.eigenstrat
    //     ch_pub_pca_w_outliers = VCF_PCA.out.pca_w_outliers
    //     ch_pub_pca_wo_outliers = VCF_PCA.out.pca_wo_outliers
    // } else {
    //     ch_pub_eigenstrat = Channel.empty()
    //     ch_pub_pca_w_outliers = Channel.empty()
    //     ch_pub_pca_wo_outliers = Channel.empty()
    // }

    // // Run delly indel analysis
    // if (params.skip_delly == false) {
    //     CALL_DELLY_INDELS(
    //         ch_genome,
    //         ch_all_strains,
    //         bam_dir,
    //         ref_strain,
    //         params.minsize,
    //         params.maxsize
    //     )
    //     ch_versions = ch_versions.mix(CALL_DELLY_INDELS.out.versions)
    //     ch_pub_indels = CALL_DELLY_INDELS.out.indels
    // } else {
    //     ch_pub_indels = Channel.empty()
    // }

    // Collate and save software versions
    ch_versions
        .collectFile(name: 'workflow_software_versions.txt', sort: true, newLine: true)
        .set { ch_collated_versions }

    publish:
    // Postprocessing outputs
    // ch_pub_isotype_vcf       >> "variation"
    // ch_pub_soft_isotype_vcf  >> "variation"
    ch_pub_small_isotype_vcf >> "variation"
    ch_pub_snv_vcf           >> "variation"
    // ch_pub_strain_vcfs       >> "variation/strain_vcf"
    
    // Haplotype outputs
    ch_pub_haplotype         >> "haplotype"
    ch_pub_nemascan          >> "nemascan"
    ch_pub_divergent         >> "divergent_regions"
    ch_pub_divergent_masks   >> "divergent_regions/Mask_DF"

    // // Phylogenetic tree outputs
    // ch_pub_tree              >> "tree"

    // Imputation outputs
    ch_pub_imputed           >> "variation"

    // // PCA outputs
    // ch_pub_eigenstrat        >> "eigenstrat/inputfiles"
    // ch_pub_pca_w_outliers    >> "eigenstrat/no_removal"
    // ch_pub_pca_wo_outliers   >> "eigenstrat/outlier_removal"

    // // Indel outputs
    // ch_pub_indels            >> "variation/indels"

    ch_collated_versions     >> "."
}

// Current bug that publish doesn't work without an output closure
output {
    "variation" {
        mode "copy"
        enabled (params.skip_postprocessing == false || params.skip_imputation == false)
    }
    "variation/strain_vcf" {
        mode "copy"
        enabled (params.skip_postprocessing == false)
    }
    "variation/indels" {
        mode "copy"
        enabled (params.skip_delly == false)
    }
    "haplotype" {
        mode "copy"
        enabled (params.skip_haplotypes == false)
    }
    "NemaScan" {
        mode "copy"
        enabled (params.skip_haplotypes == false)
    }
    "divergent_regions" {
        mode "copy"
        enabled (params.skip_haplotypes == false)
    }
    "divergent_regions/Mask_DF" {
        mode "copy"
        enabled (params.skip_haplotypes == false)
    }
    "tree" {
        mode "copy"
        enabled (params.skip_tree == false)
    }
    "eigenstrat/inputfiles" {
        mode "copy"
        enabled (params.skip_pca == false)
        path { meta, ped, bim, prune, markers, pedsnp, pedind, samples -> eigenstrat/inputfiles/LD_${meta.ld} }
    }
    "eigenstrat/no_removal" {
        mode "copy"
        enabled (params.skip_pca == false)
        path { meta, evac, eval, logfile, relatedness, relatedness_id, tracywidom -> eigenstrat/no_removal/LD_${meta.ld} }
    }
    "eigenstrat/outlier_removal" {
        mode "copy"
        enabled (params.skip_pca == false)
        path { meta, evac, eval, logfile, relatedness, relatedness_id, tracywidom -> eigenstrat/outlier_removal/LD_${meta.ld}/${meta.outlier} }
    }
    "." {
        mode "copy"
    }
}


workflow.onComplete {

    summary = """
    Pipeline execution summary
    ---------------------------
    Completed at: ${workflow.complete}
    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    exit status : ${workflow.exitStatus}
    Error report: ${workflow.errorReport ?: '-'}
    Git info: $workflow.repository - $workflow.revision [$workflow.commitId]
    { Parameters }
    ---------------------------
    Species: ${params.species}
    Release: ${params.release}
    Hard_VCF: ${hard_vcf}
    Soft_VCF: ${soft_vcf}
    Isotype_VCF: ${isotype_vcf}
    SNV_VCF: ${snv_vcf}
    Isotype_groups: ${isogroups}
    Bam_dir: ${bam_dir}
    Reference: ${reference}
    Output: ${workflow.outputDir}
    Binsize: ${params.binsize}
    LD_range: ${params.ld_range}
    Map_dir: ${map_dir}
    Window: ${params.window}
    Overlap: ${params.overlap}
    Outlier_iterations: ${params.outlier_iterations}
    Singletons: ${params.singletons}
    Ref_strain: ${ref_strain}
    Minsize: ${params.minsize}
    Maxsize: ${params.maxsize}
    Skip_postprocessing: ${params.skip_postprocessing}
    Skip_haplotypes: ${params.skip_haplotypes}
    Skip_tree: ${params.skip_tree}
    Skip_imputation: ${params.skip_imputation}
    Skip_pca: ${params.skip_pca}
    Skip_delly: ${params.skip_delly}
    """

    println summary

}