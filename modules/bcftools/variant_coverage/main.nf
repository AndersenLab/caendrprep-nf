    process BCFTOOLS_VARIANT_COVERAGE {

    label 'bcftools_variant_coverage'

    input:
        tuple val(meta), path(bam), path(bam_index)
        tuple val(meta1), path(vcf), path(index)
        path bin_file

    output:
        tuple val(meta), path("${meta.id}_Mask_DF.tsv"), emit: mask
        path "versions.yml",                             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """    
    bcftools view -s ${meta.id} ${vcf} | bcftools filter -i 'GT="alt"' -Ov | \\
    bedtools coverage -a ${bin_file} -b stdin -counts > ${meta.id}_variant_counts.txt

    # need to use the isotype ref strain here, not the isotype strain!
    mosdepth -b ${bin_file} ${meta.id} ${bam}

    gunzip ${meta.id}.regions.bed.gz

    echo -e 'CHROM\tSTART_BIN\tEND_BIN\tVAR_COUNT\tCOVERAGE' > ${meta.id}_Mask_DF.tsv

    paste ${meta.id}_variant_counts.txt ${meta.id}.regions.bed | cut -f 1-4,8 >> ${meta.id}_Mask_DF.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_Mask_DF.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}