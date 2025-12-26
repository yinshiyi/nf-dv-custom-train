#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.N_SHARDS = 10           // number of shards
params.DOCKER_IMAGE = 'google/deepvariant:1.5.0'

process MAKE_EXAMPLES {
    tag "${mode}"

    input:
    tuple val(mode),
        val(chr),
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
    make_examples \
      --mode "training" \
      --ref ${ref} \
      --reads ${bam} \
      --examples "output/${mode}_set.with_label.tfrecord@${params.N_SHARDS}.gz" \
      --truth_variants ${truth_vcf} \
      --confident_regions ${truth_bed} \
      --regions "${chr}" \
      --channels insert_size \
    2>&1 | tee output/logs/make_examples.log
    """
}


// Training
workflow {

    val_ch = Channel.of(
        tuple(
            'validation',
            'chr21',
            file(params.BAM_CHR21),
            file(params.BAI_CHR21)
        )
    )
    constants_ch = Channel.of(
        tuple(
            file(params.REF),
            file(params.REF_INDEX),
            file(params.TRUTH_VCF),
            file(params.TRUTH_VCF_INDEX),
            file(params.TRUTH_BED)
        )
    )
    // task_ch = Channel.from(0..(params.N_SHARDS-1))

    // train_tasks_ch = task_ch.map { task_id ->
    //     tuple(task_id, 'training', 'chr1', bam_chr1)
    // }
    // MAKE_EXAMPLES(train_tasks_ch)


    val_tasks_ch = val_ch
        .combine(constants_ch)
        .map { it.flatten() }

    MAKE_EXAMPLES(val_tasks_ch)
}
