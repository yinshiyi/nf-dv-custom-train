nextflow.enable.dsl=2

process MAKE_EXAMPLES {
    tag "${mode}"

    input:
    tuple val(mode),
        val(chr),
        val(n_shards),
        path(bam),
        path(bai),
        path(ref),
        path(ref_index),
        path(truth_vcf),
        path(truth_vcf_index),
        path(truth_bed)

    output:
    file "output/${mode}_set.with_label.tfrecord*.gz"

    container "${params.DOCKER_IMAGE}"

    script:
    """
    touch ${bai}
    mkdir -p output/logs
    seq 0 \$(($n_shards-1)) | parallel --halt 2 --line-buffer \
    make_examples \
      --mode "training" \
      --ref ${ref} \
      --reads ${bam} \
      --examples "output/${mode}_set.with_label.tfrecord@${n_shards}.gz" \
      --truth_variants ${truth_vcf} \
      --confident_regions ${truth_bed} \
      --task {} \
      --regions "${chr}" \
      --channels insert_size \
    2>&1 | tee output/logs/make_examples.log
    """
}
