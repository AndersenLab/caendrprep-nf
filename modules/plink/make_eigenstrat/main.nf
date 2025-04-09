process PLINK_MAKE_EIGENSTRAT {

    label 'plink_make_eigenstrat'

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        path singleton_ids
        val ld

    output:
        tuple val(ld), path("eigenstrat_input.ped"), path("eigenstrat_input.bim"), path("plink.prune.in"), path("eigenstrat_markers.txt"),  emit: plink
        path "versions.yml",                                                                                                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    plink --vcf ${vcf} --snps-only --biallelic-only --set-missing-var-ids @:# --indep-pairwise 50 10 ${ld} --allow-extra-chr 
    plink --vcf ${vcf} --biallelic-only --set-missing-var-ids @:# --extract plink.prune.in --exclude ${singleton_ids} --geno 0 --recode 12 --out eigenstrat_input --allow-extra-chr --make-bed   
   
    awk '{print \$2}' OFS="\t" eigenstrat_input.bim | awk -F":" '\$1=\$1' OFS="\t"| sort -k1,1d -k2,2n > eigenstrat_markers.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$( plink --version |& head -n 1 | cut -f 2' )
    END_VERSIONS
    """

    stub:
    """
    touch eigenstrat_input.ped
    touch eigenstrat_input.bim
    touch plink.prune.in
    touch eigenstrat_markers.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$( plink --version |& head -n 1 | cut -f 2' )
    END_VERSIONS
    """
}