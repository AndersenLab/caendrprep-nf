process JAVA_HAPLOTYPE_SWEEP_IBD {

    tag "${meta.id} ${contig}"
    label 'java_haplotype_sweep_ibd'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        path ibdseq
        val contig

    output:
        path "${contig}.ibd", emit: vcf
        path "versions.yml",  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def avail_mem = (task.memory.giga).intValue() - 1
    """
    java -Xmx${avail_mem} -jar ${ibdseq} gt=${vcf} minalleles=4 r2max=0.3 ibdlod=3 r2window=1500 nthreads=${task.cpus} chrom=${contig} out=${contig}
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        java: \$( java --version |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """

    stub:
    """
    touch ${contig}.ibd

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        java: \$( java --version |& head -n 1 |& cut -f 2' )
    END_VERSIONS
    """
}
