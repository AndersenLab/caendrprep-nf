process LOCAL_GET_CONTIG_INFO {

    tag "${meta.id}"
    label "local_get_contig_info"

    input:
        tuple val(meta), path(vcf), path(vcf_index)
        val binsize

    output:
        path "contigs.txt",          emit: contigs
        path "contig_lengths.tsv",   emit: lengths
        path "genome_partition.bed", emit: partition

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    zcat ${vcf} | head -n 200 | grep "##contig" | \\
        awk '{split(\$1,A,"="); split(A[3],B,","); CHROM=B[1]; split(A[4],C,">"); SIZE=C[1]; printf "%s\\t%i\\n", CHROM, SIZE;}' > contig_lengths.tsv
    cut -f 1 contig_lengths.tsv > contigs.txt
    awk -v BINSIZE="${binsize}" '{if (NF > 1){ N=int(\$2/BINSIZE); for (I=0;I<=N;I++){ START=I*BINSIZE; STOP=START+BINSIZE; if (STOP > \$2) STOP=\$2; printf "%s\\t%i\\t%i\\n", \$1, START, STOP;}}}' contig_lengths.tsv > genome_partition.bed
    """

    stub:
    """
    touch contigs.txt
    touch contig_lengths.tsv
    touch genome_partition.txt
    """
}
