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
    zcat ${vcf} | head -n 200 | grep "##contig" | \
        awk -v '{split(\$1,A,"="); split(A[3],B,","); CHROM=B[1]; split(A[4],C,">"); SIZE=C[1]; printf "%s\t%i\n", CHROM, SIZE;}' > contig_lengths.tsv
    cut -f 1 contig_lengths.tsv > contigs.txt
    awk -v BINSIZE="${binsize} '{for (I=0;I<\$2;I+=BINSIZE){ END=I+BINSIZE; if (END > \$2) END=SIZE; printf "%s\t%i\t%i\n", \$1, I, END;} contig_lengths.tsv > genome_partition.bed
    """

    stub:
    """
    touch contigs.txt
    touch contig_lengths.tsv
    touch genome_partition.txt
    """
}
