process BCFTOOLS_EXTRACT_ISOTYPES {

    tag "${meta.id}"
    label 'bcftools_extract_isotypes'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        path strains

    output:
        tuple val("${meta.id}_isotype"), path("*isotype.vcf.gz"), path("*isotype.vcf.gz.tbi"), emit: vcf
        path "versions.yml",                                                                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    output=`echo $vcf | sed 's/.vcf.gz/.isotype.vcf.gz/'`

    bcftools view --threads ${task.cpus} -S ${strains} -O u ${vcf} | \\
      bcftools view -O v --threads ${task.cpus} --min-af 0.000001 --max-af 0.999999 | \\
      vcffixup - | \\
      bcftools view --threads ${task.cpus} -O z > \${output}

    bcftools index --tbi \${output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    output=`echo $vcf | sed 's/.vcf.gz/.isotype.vcf.gz/'`
    touch \${output}
    touch \${output}.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}
