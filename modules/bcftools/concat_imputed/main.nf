process BCFTOOLS_CONCAT_IMPUTED {

    label 'bcftools_concat_imputed'

    input:
        path("*")

    output:
        tuple val("impute"), path("impute.isotype.vcf.gz"), file("impute.isotype.vcf.gz.tbi"), emit: imputed
        path "impute.isotype.stats.txt",                                                       emit: stats
        path "versions.yml",                                                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools concat *.b5.vcf.gz > impute.isotype.vcf
    bcftools view -O z -o impute.isotype.vcf.gz impute.isotype.vcf
    bcftools index -t impute.isotype.vcf.gz
    bcftools stats --verbose impute.isotype.vcf.gz > impute.isotype.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch impute.isotype.vcf.gz
    touch impute.isotype.vcf.gz.tbi
    touch impute.isotype.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}