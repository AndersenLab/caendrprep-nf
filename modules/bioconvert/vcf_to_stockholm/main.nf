process BIOCONVERT_VCF_TO_STOCKHOLM {

    tag "${meta.id}"
    label 'bioconvert_vcf_to_stockholm'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        path vcf2phylip

    output:
        path "*.stockholm",    emit: stockholm
        path "versions.yml",   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    output_phylip=`echo ${vcf} | sed 's/.vcf.gz/.min4.phy/'`
    output_stockholm=`echo \${output_phylip} | sed 's/.phy/.stockholm/'`

    python ${vcf2phylip} -i ${vcf}
    bioconvert phylip2stockholm \${output_phylip} \${output_stockholm}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconvert: \$( bioconvert --version )
    END_VERSIONS
    """

    stub:
    """
    output_phylip=`echo ${vcf} | sed 's/.vcf.gz/.min4.phy/'`
    output_stockholm=`echo \${output_phylip} | sed 's/.phy/.stockholm/'`
    touch \${stockholm}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioconvert: \$( bioconvert --version )
    END_VERSIONS
    """
}
