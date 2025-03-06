process BCFTOOLS_STRIP_NONGENOTYPES {

    tag "${meta.id}"
    label 'bcftools_strip_nongenotypes'

    input:
        tuple val(meta), path(vcf), path(vcf_index)

    output:
        tuple val("geno_only"), path("*.small.hard-filter*.vcf.gz"), path("*.small.hard-filter*.vcf.gz.tbi"), emit: vcf
        path "versions.yml",                                                                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    output=`echo ${vcf} | sed 's/.hard-filter/.small.hard-filter/'`

    bcftools annotate -x INFO,^FORMAT/GT -O z ${vcf} > \${output}
    bcftools index -t \${output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    output=`echo ${vcf} | sed 's/.hard-filter/.small.hard-filter/'`
    touch \${output}
    touch \${output}.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}
