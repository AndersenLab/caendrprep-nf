    process BEDTOOLS_VARIANT_COVERAGE {

    label 'bedtools_variant_coverage'

    input:
        tuple val(meta), path("mosdepth.regions.bed.gz"), path(vcf), path(index)
        path bin_file

    output:
        tuple val(meta), path("${meta.id}_Mask_DF.tsv"), emit: mask
        path "versions.yml",                             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """    
    zcat ${vcf} | grep -v "#" | awk '{if (\$10 ~ /1\\/1/) print \$0}' | \\
    bedtools coverage -a ${bin_file} -b stdin -counts > ${meta.id}_variant_counts.txt

    gunzip mosdepth.regions.bed.gz

    echo -e 'CHROM\tSTART_BIN\tEND_BIN\tVAR_COUNT\tCOVERAGE' > ${meta.id}_Mask_DF.tsv

    paste ${meta.id}_variant_counts.txt mosdepth.regions.bed | cut -f 1-4,8 >> ${meta.id}_Mask_DF.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$( bedtools --version |& sed '1!d; s/^.*bedtools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_variant_counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$( bedtools --version |& sed '1!d; s/^.*bedtools //' )
    END_VERSIONS
    """
}