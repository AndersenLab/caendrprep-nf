process BEAGLE_IMPUTATION {

    tag "${meta.id}_${contig}"
    label 'beagle_imputation'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        tuple val(contig), path(contig_map)
        val window
        val overlap

    output:
        tuple path("${contig}.b5.vcf.gz"), path("${contig}.b5.vcf.gz.csi"), emit: imputed
        path "versions.yml",                                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    beagle chrom=${contig} window=${window} overlap=${overlap} impute=true ne=100000 nthreads=${task.cpus} imp-segment=0.5 imp-step=0.01 \
        cluster=0.0005 gt=${vcf} map=${contig_map} out=${contig}.b5

    bcftools index ${contig}.b5.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        beagle: \$( beagle |& head -n 1 |&  cut -f 3 |& sed 's/)//' )
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch "${contig}.b5.vcf.gz"
    touch "${contig}.b5.vcf.gz.csi"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        beagle: \$( beagle |& head -n 1 |&  cut -f 3 |& sed 's/)//' )
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}
