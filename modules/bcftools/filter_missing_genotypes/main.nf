process BCFTOOLS_FILTER_MISSING_GENOTYPES {

    label 'bcftools_filter_missing_genotypes'

    input:
        tuple val(meta), path(vcf), path(vcf_index)

    output:
        tuple val(meta), path("filtered.vcf.gz"), path("filtered.vcf.gz.tbi"), emit: vcf
        path "versions.yml",                                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools filter -i N_MISSING=0 -O z -o filtered.vcf.gz ${vcf}
    bcftools index -t filtered.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch filtered.vcf.gz
    touch filtered.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}