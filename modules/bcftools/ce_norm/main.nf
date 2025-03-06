process BCFTOOLS_CE_NORM {

    label 'bcftools_ce_norm'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        path contigs

    output:
        tuple val(meta), path("ce_norm.vcf.gz"), path("ce_norm.vcf.gz.tbi"),  emit: vcf
        path "versions.yml",                                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    CONTIGS=""
    for I in \$(grep -v "Mt" ${contigs}); do
        if [[ \${CONTIGS} == "" ]]; then
            CONTIGS=\${I}
        else
            CONTIGS="\${CONTIGS},\${I}"
        fi
    done

    bcftools view --regions \${CONTIGS} ${vcf} | \\
    bcftools norm -m + -Oz -o ce_norm.vcf.gz
    bcftools index -t ce_norm.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ce_norm.vcf.gz
    touch ce_norm.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}