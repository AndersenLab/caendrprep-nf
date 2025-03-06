process VCFTOOLS_GET_SINGLETONS {

    label 'vcftools_get_singletons'

    input:
        tuple val(meta), path(vcf), path(vcf_index)

    output:
        path "singleton_ids.txt", emit: singletons
        path "versions.yml",      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    vcftools --gzvcf ${vcf} --singletons
    cat out.singletons | awk 'BEGIN{OFS=":"} {if (NR!=1) print \$1,\$2}' > singleton_ids.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch singleton_ids.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}