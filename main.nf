#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.TRAIN_SHARDS = 40
params.VAL_SHARDS   = 5
params.DOCKER_IMAGE = 'google/deepvariant:1.5.0'

include { MAKE_EXAMPLES; MAKE_EXAMPLES as MAKE_EXAMPLES_VAL } from './modules/make_example.nf'

workflow {

    val_ch = Channel.of(
        tuple(
            'validation',
            'chr21',
            params.VAL_SHARDS,
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

    train_ch = Channel.of(
        tuple(
            'training',
            'chr1',
            params.TRAIN_SHARDS,
            file(params.BAM_CHR1),
            file(params.BAI_CHR1)
        )
    )
    train_tasks_ch = train_ch
        .combine(constants_ch)
        .map { it.flatten() }
    MAKE_EXAMPLES(train_tasks_ch)


    val_tasks_ch = val_ch
        .combine(constants_ch)
        .map { it.flatten() }
    MAKE_EXAMPLES_VAL(val_tasks_ch)
}
