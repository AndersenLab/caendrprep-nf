process BCFTOOLS_PREP_EIGENSTRAT {

    label 'bcftools_prep_eigenstrat'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        tuple val(ld), path(ped), path(bim), path(prune), path(markers)
        path contigs

    output:
        tuple val(ld), path("eigenstrat_input.pedsnp"), path("eigenstrat_input.pedind"), path("sorted_samples.txt"), emit: ped
        path "versions.yml",                                                                                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bcftools view -T ${markers} -Oz -o eiganstrat_input.vcf.gz ${vcf}

    bcftools query -l ${vcf} | sort > sorted_samples.txt

    cp ${bim} eigenstrat_input.pedsnp
    CONTIGS=(\$(grep -v Mt ${contigs}))
    for I in \$(seq 0 1 \$(expr \${#CONTIGS[*]} - 1));
        cat eigenstrat_input.pedsnp | sed 's/^\${CONTIGS[\${I}]}/\${I}/g' > tmp
        mv tmp eigenstrat_input.pedsnp
    done
    cut -f-6 eigenstrat_input.pedsnp > tmp
    mv tmp eigenstrat_input.pedsnp

    cut -f-6 -d' ' eigenstrat_input.ped | awk '{print 1, \$2, \$3, \$3, \$5, 1}'  > eigenstrat_input.pedind

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """

    stub:
    """
    touch eigenstrat_input.pedsnp
    touch eigenstrat_input.pedind
    touch sorted_samples.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version |& sed '1!d; s/^.*bcftools //' )
    END_VERSIONS
    """
}