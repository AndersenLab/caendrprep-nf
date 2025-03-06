![Build Docker (env/beagle.Dockerfile)](https://github.com/AndersenLab/caendrprep-nf/workflows/Build%20Docker%20(env/beagle.Dockerfile)/badge.svg)

# caendrprep-nf

This pipeline performs a variety of post-variant calling analyses and processing in prep for CaeNDR release as well as in-lab use. These include restricting VCF files to isotype references, creating a SNV-only VCF file, population genetics analyses (such as identifying shared haplotypes and divergent regions) at the isotype level, creating phylogenetic trees, PCA analysis, and INDEL calling.

# Pipeline overview

```

   ______           _   ______  ____                                    ____
  / ____/___ ____  / | / / __ \/ __ \____  ________  ____        ____  / __/
 / /   / __ `/ _ \/  |/ / / / / /_/ / __ \/ ___/ _ \/ __ \______/ __ \/ /_  
/ /___/ /_/ /  __/ /|  / /_/ / _, _/ /_/ / /  /  __/ /_/ /_____/ / / / __/  
\____/\__,_/\___/_/ |_/_____/_/ |_/ .___/_/   \___/ .___/     /_/ /_/_/   
                                 /_/             /_/

nextflow andersenlab/caendrprep.nf --species=c_elegans --release=20250331

nextflow andersenlab/caendrprep.nf --isotype_groups=/path/to/groups --hard_isotype_vcf=/path/to/hard_isotype_vcf --full_vcf=/path/to/full_vcf --reference=/path/to/fasta --bam_dir=/path/to/bams --ref_strain=refstrain

    parameters           description                                              Set/Default
    ==========           ===========                                              ========================
    --debug               Set to 'true' to test                                   (optional)
    --species             Species: 'c_elegans', 'c_tropicalis' or 'c_briggsae'    (optional if needed files manually specified)
    --release             CaeNDR release for genome lookup values                 (optional if needed files manually specified)
    --hard_vcf            Path to hard-filtered full VCF file                     (optional if species and release are specified)
    --isotype_vcf         Path to hard-filtered isotype VCF file                  (optional if species and release are specified)
    --snv_vcf             Path to hard-filtered SNV-only VCF file                 (optional if species and release are specified)
    --isogroups           Path to isotype_groups file                             (optional if species and release are specified)
    --bam_dir             Path to folder containing bam files                     (optional if species and release are specified)
    -output-dir           Output destination directory                            CaeNDRprep_{date}

    Postprocessing parameters
    =========================
    --soft_vcf            Path to soft-filtered full VCF file                     (optional if species and release are specified)

    Haplotype parameters
    ====================
    --binsize             Size to partition genome into for finding coverage      1000

    Imputation parameters
    ====================
    --map_dir             Directory containing contig LD maps                     ./data/{species}
    --window              Window size for Beagle imputation                       5
    --overlap             Overlap size for Beagle imputation                      2

    PCA parameters
    ==============
    --ld_range            Comma-separated list of LD cutoffs                      0.8
    --outlier_iterations  Comma-separated list of outlier iterations              5
    --singletons          Boolean specifying whether to find singletons           false

    Delly parameters
    ================
    --reference           Path to genome fasta file                               (optional if species and release are specified)
    --ref_strain          Reference strain name                                   (optional if species and release are specified)
    --minsize             Minimum indel size                                      50
    --maxsize             Maximum indel size                                      1000

    Workflow parameters
    ===================
    --skip_postprocessing Skip running VCF postprocessing analysis                false
    --skip_haplotypes     Skip running VCF haplotye analysis                      false
    --skip_tree           Skip running VCF phylogenetic tree analysis             false
    --skip_imputation     Skip running VCF imputation analysis                    false
    --skip_pca            Skip running VCF pca analysis                           false
    --skip_delly          Skip running VCF delly analysis                         false

```


## Software Requirements

* The latest update requires Nextflow version 24.10.0+. On Rockfish, you can access this version by loading the `nf24_env` conda environment prior to running the pipeline command:

```
ml anaconda
conda activate /data/eande106/software/conda_envs/nf24_env
```

# Usage

*Note: if you are having issues running Nextflow or need reminders, check out the [Nextflow](http://andersenlab.org/dry-guide/latest/rockfish/rf-nextflow/) page.*

## Testing on Rockfish

*This command uses a test dataset*

```
nextflow run -latest andersenlab/caendrprep-nf --debug
```

>[!Note]
> This is not currently implemented

## Running on Rockfish

You should run this in a screen or tmux session.

```
nextflow andersenlab/caendrprep.nf --species=c_elegans --release=20250331
```

# General Parameters

##  --species (optional if needed files manually specified)

If not all required files are manually specified, the species and release date can be used to look up existing files for c_elegans, c_briggsae, or c_tropicalis

## --release (optional if needed files manually specified)

If not all required files are manually specified, the species and release date can be used to look up existing files for c_elegans, c_briggsae, or c_tropicalis

## --hard_vcf (optional if species and release are specified, used in postprocessing and tree analyses)

Path to hard-filtered VCF file.

## --isotype_vcf (optional if species and release are specified or postprocessing is run, used in haplotype and tree analyses)

Path to hard-filtered VCF file restricted to just isotype reference strains

## --snv_vcf (optional if species and release are specified or postprocessing is run, used in imputation and pca analysese)

Path to hard-filtered VCF file restricted to SNVs in isotype reference strains

## --isogroups (optional if species and release are specified, used in postprocessing, haplotype, and pca analyses)

Path to isotype groups file containing strains, isotype assignments, and isotype reference strains

## --bam_dir (optional if species and release are specified, used in haplotye and delly analyses)

Path to folder containing bam files

## -output-dir (default: CaeNDRprep_{date})

Output destination directory                            

# Postprocessing Parameters

## --soft_vcf (optional if species and release are specified)

Path to soft-filtered VCF file

# Haplotype Parameters

## --binsize (default: 1000)

Size to partition genome into for finding coverage

# Imputation Parameters

## --map_dir (default: ./data/{species})

Directory containing contig LD maps                

## --window (default: 5)

Window size for Beagle imputation

## --overlap (default: 2)

Overlap size for Beagle imputation

# PCA Parameters

## --ld_range (default: 0.8)

Comma-separated list of LD cutoffs to use

## --outlier_iterations (default: 5)

Comma-separated list of outlier iterations to use

## --singletons (default: false)

Boolean specifying whether to find singletons

# Delly Parameters

## --reference (optional if species and release are specified)

Path to reference genome fasta file

## --ref_strain (optional if species and release are specified)

Reference strain name

## --minsize (default: 50)

Minimum indel size to keep

## --maxsize (default: 1000)

Maximum indel size to keep

# Workflow Parameters

--skip_postprocessing (default: false)

Skip running VCF postprocessing analysis

## --skip_haplotypes (default: false)

Skip running VCF haplotye analysis

## --skip_tree (default: false)

Skip running VCF phylogenetic tree analysis

## --skip_imputation (default: false)

Skip running VCF imputation analysis

## --skip_pca (default: false)

Skip running VCF pca analysis

## --skip_delly (default: false)

Skip running VCF delly analysis

# Output

```
├── variation
|   ├── WI.{date}.small.hard-filter.isotype.vcf.gz
|   ├── WI.{date}.small.hard-filter.isotype.vcf.gz.tbi
|   ├── WI.{date}.hard-filter.isotype.SNV.vcf.gz
|   ├── WI.{date}.hard-filter.isotype.SNV.vcf.gz.tbi
|   ├── WI.{date}.soft-filter.isotype.vcf.gz
|   ├── WI.{date}.soft-filter.isotype.vcf.gz.tbi
|   ├── WI.{date}.hard-filter.isotype.vcf.gz
|   ├── WI.{date}.hard-filter.isotype.vcf.gz.tbi
|   ├── impute.isotype.vcf.gz
|   ├── impute.isotype.vcf.gz.tbi
|   ├── strain_vcf
│   |   ├── strain1.vcf.gz
│   |   ├── strain1.vcf.tbi
│   |   ├── strain2.vcf.gz
│   |   ├── strain2.vcf.tbi
|   |   └── *
|   |
|   └── indels
|       ├── indel.isotype.vcf.gz
|       └── indel.isotype.vcf.gz.tbi
|
├── haplotype
│   ├── haplotype_length.pdf
│   ├── sweep_summary.tsv
│   ├── haplotype.pdf
│   ├── haplotype.tsv
│   ├── [chr].ibd
│   └── haplotype_plot_df.Rda
|
├── NemaScan
│   ├── strain_isotype_lookup.tsv
│   ├── div_isotype_list.txt
│   ├── haplotype_df_isotype.bed
│   ├── divergent_bins.bed
│   └── divergent_df_isotype.bed
|
├── divergent_regions
|   ├── divergent_regions_strain.bed
│   └── Mask_DF
│       └── [strain]_Mask_DF.tsv
|
├── tree
│   ├── WI.{date}.hard-filter.isotype.min4.tree
│   ├── WI.{date}.hard-filter.isotype.min4.tree.pdf
│   ├── WI.{date}.hard-filter.min4.tree
│   └── WI.{date}.hard-filter.min4.tree.pdf
|
└── eigenstrat
    ├── input_files
    |   └── LD_{eigen_ld}
    │       ├── eigenstrat_input.ped
    │       ├── eigenstrat_input.bim
    │       ├── plink.prune.in
    │       ├── eigenstrat_markers.txt
    │       ├── eigenstrat_input.pedsnp
    │       ├── eigenstrat_input.pedind
    │       └── sorted_samples.txt
    |
    ├── outlier_removal
    |       └── LD_{eigen_ld}
    |           └── {outlier_iteration}
    │               ├── eigenstrat_outliers_removed_relatedness
    │               ├── eigenstrat_outliers_removed_relatedness.id
    │               ├── eigenstrat_outliers_removed.evac
    │               ├── eigenstrat_outliers_removed.eval
    │               ├── logfile_outlier.txt
    │               └── TracyWidom_statistics_outlier_removal.tsv
    └── no_removal
            └── LD_{eigen_ld}
                └── same as outlier_removal


```

# Relevant docker images
* `andersenlab-hetpolarization-1.10` ([link](https://hub.docker.com/r/andersenlab/hetpolarization:1.10)): Docker image is created within the pipeline [wi-gatk](https://github.com/AndersenLab/wi-gatk) using GitHub actions. Whenever a change is made to `env/hetpolarization.Dockerfile` or `.github/workflows/build_docker.yml` GitHub actions will create a new docker image and push if successful
* `eclipse-temurin:23.0.2_7-jre-alpine-3.21` ([link](https://hub.docker.com/r/eclipse-temurin:23.0.2_7-jre-alpine-3.21)): Docker image maintained by Eclipse Temurin for OpenJDK
* `andersenlab-r_packages-v0.7` ([link](https://hub.docker.com/r/andersenlab/r_packages:v0.7)): Docker image is created manually, code can be found in the [dockerfile](https://github.com/AndersenLab/dockerfile/tree/master/r_packages) repo.
* `bioconvert-bioconvert-0.6.1` ([link](https://hub.docker.com/r/bioconvert/bioconvert:0.6.1)): Docker image maintained by bioconvert for bioconvert
* `andersenlab-tree-2022030116023027c1b8` ([link](https://hub.docker.com/r/andersenlab/tree:2022030116023027c1b8)): Docker image is created within this pipeline using GitHub actions. Whenever a change is made to `env/tree.Dockerfile` or `.github/workflows/build_tree_docker.yml` GitHub actions will create a new docker image and push if successful
* `andersenlab-beagle-20250305` ([link](https://hub.docker.com/r/andersenlab/beagle:20250305)): Docker image is created within this pipeline using GitHub actions. Whenever a change is made to `env/beagle.Dockerfile` or `.github/workflows/build_beagle_docker.yml` GitHub actions will create a new docker image and push if successful
* `quay.io-biocontainers-bcftools-1.16--hfe4b78e_1` ([link](https://quay.io/biocontainers/bcftools:1.16--hfe4b78e_1)): Docker image maintained by biocontainers for bcftools
* `biocontainers-vcftools-v0.1.16-1-deb_cv1` ([link](https://hub.docker.com/r/biocontainers/vcftools:v0.1.16-1-deb_cv1)): Docker image maintained by biocontainers for vcftools
* `biocontainers-plink-v1.07dfsg-2-deb_cv1` ([link](https://hub.docker.com/r/biocontainers/plink:v1.07dfsg-2-deb_cv1)): Docker image maintained by biocontainers for plink
* `quay.io-biocontainers-eigensoft-8.0.0--h75d7a4a_6` ([link](https://quay.io/biocontainers/eigensoft:8.0.0--h75d7a4a_6)): Docker image maintained by biocontainers for eigensoft
* `dellytools-delly-v1.2.6` ([link](https://hub.docker.com/r/dellytools/delly:v1.2.6)): Docker image maintained by dellytools for delly

Make sure that you have followed the [Nextflow configuration](https://andersenlab.org/dry-guide/latest/rockfish/rf-nextflow/) described in the dry-guide prior to running the workflow.
