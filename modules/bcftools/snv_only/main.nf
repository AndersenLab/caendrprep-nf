process BCFTOOLS_SNV_ONLY {

    tag "${meta.id}"
    label 'bcftools_snv_only'

    input:
        tuple val(meta), path(vcf), path(vcf_index)

    output:
        tuple val("snv"), path("*.SNV.vcf.gz"), path("*.SNV.vcf.gz.tbi"), emit: vcf
        path "versions.yml",                                              emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    output=`echo ${vcf} | sed 's/.vcf.gz/.SNV.vcf.gz/'`
    bcftools view -O u ${vcf} | \
    bcftools view -O v --types snps --min-af 0.000001 --max-af 0.999999 | \
    vcffixup - | \
    bcftools view --threads=${task.cpus} -O z > \${output}
    
    bcftools index --tbi \${output}

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
