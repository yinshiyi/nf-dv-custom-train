#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.N_SHARDS = 10           // number of shards
params.DOCKER_IMAGE = 'google/deepvariant:1.5.0'

process MAKE_EXAMPLES {

    tag "${mode}_task_${task_id}"

    input:
    val task_id
    val mode          // "training" or "validation"
    val chr
    path bam

    output:
    file "output/${mode}_set.with_label.tfrecord-${task_id}.gz"

    container docker_image

    script:
    """
    make_examples \
      --mode "training" \
      --ref ${ref} \
      --reads ${bam} \
      --examples output/${mode}_set.with_label.tfrecord-${task_id}.gz \
      --truth_variants ${truth_vcf} \
      --confident_regions ${truth_bed} \
      --task ${task_id} \
      --regions '${chr}' \
      --channels insert_size
    """
}


// Training
workflow {

    bam_chr1 = Channel.fromPath(params.BAM_CHR1)
    bam_chr21 = Channel.fromPath(params.BAM_CHR21)
    ref = Channel.fromPath(params.REF)
    truth_vcf = Channel.fromPath(params.TRUTH_VCF)
    truth_bed = Channel.fromPath(params.TRUTH_BED)

    task_ch = Channel.from(0..(params.N_SHARDS-1))

    train_tasks_ch = task_ch.map { task_id ->
        tuple(task_id, 'training', 'chr1', bam_chr1)
    }
    MAKE_EXAMPLES(train_tasks_ch)
    val_tasks_ch = task_ch.map { task_id ->
        tuple(task_id, 'validation', 'chr21', bam_chr21)
    }
    MAKE_EXAMPLES(val_tasks_ch)

}