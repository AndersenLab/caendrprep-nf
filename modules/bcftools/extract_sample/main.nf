process BCFTOOLS_EXTRACT_SAMPLE {

    tag "${strain}"
    label 'bcftools_extract_sample'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        val strain

    output:
        tuple val(strain), path("${strain}.vcf.gz"), path("${strain}.vcf.gz.tbi"), emit: vcf
        path "versions.yml",                                                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools view -s ${strain} -O v -U ${vcf} | \\
      vcffixup - | \\
      bcftools view --threads ${task.cpus} -O z > ${strain}.vcf.gz
    bcftools index --tbi ${strain}.vcf.gz
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch ${strain}.vcf.gz
    touch ${strain}.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}
