#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.N_SHARDS = 10           // number of shards
params.REF      = '/path/to/ref.fasta'
params.BAM      = '/path/to/chr1.bam'
params.TRUTH_VCF = '/path/to/truth.vcf'
params.TRUTH_BED = '/path/to/truth.bed'
params.OUTPUT_DIR = '/path/to/output'
params.DOCKER_IMAGE = 'google/deepvariant:1.5.0'

process MAKE_EXAMPLES {

    tag "task_${task_id}"

    input:
    val task_id from task_ch

    output:
    file "${params.OUTPUT_DIR}/training_set.with_label.tfrecord-${task_id}.gz"

    container params.DOCKER_IMAGE

    script:
    """
    make_examples \
      --mode training \
      --ref "${params.REF}" \
      --reads "${params.BAM}" \
      --examples "${params.OUTPUT_DIR}/training_set.with_label.tfrecord-${task_id}.gz" \
      --truth_variants "${params.TRUTH_VCF}" \
      --confident_regions "${params.TRUTH_BED}" \
      --task ${task_id} \
      --regions 'chr1' \
      --channels insert_size
    """
}

// Channel of tasks (0 .. N_SHARDS-1)
task_ch = Channel.from(0..(params.N_SHARDS-1))
