cwlVersion: v1.2
class: Workflow
label: "Metrics Workflow"
doc: "A CWL metrics workflow."

inputs:
    inputBams:
        type: File[]
        doc: "The BAM files."
    sampleName:
        type: string
        default: "metrics-run-placeholder"
        doc: "The sample name, used to form the output names."
    umiDeduplication: 
        type: boolean
        default: false
        doc: "Whether or not UMI based deduplication should be performed."
    outputDir:
        type: string
        default: "."
        doc: "The directory to which the outputs will be written."

outputs:
    outputBam:
        type: File[]
        pickValue: all_non_null
        outputSource:
            - markDuplicates1/outputBam
            - markDuplicates2/outputBam
    outputBamIndex:
        type: File[]
        pickValue: all_non_null
        outputSource:
            - markDuplicates1/outputBamIndex
            - markDuplicates2/outputBamIndex
    metrics:
        type: File[]
        pickValue: all_non_null
        outputSource:
            - markDuplicates1/metricsFile
            - markDuplicates2/metricsFile
    outputDir:
        type: Directory[]?
        pickValue: all_non_null
        outputSource:
            - markDuplicates1/outputDir
            - markDuplicates2/outputDir
    finalBam:
        type: File
        pickValue: first_non_null
        outputSource:
            - markDuplicates2/outputBam
            - markDuplicates1/outputBam
    finalBamIndex:
        type: File
        pickValue: first_non_null
        outputSource:
            - markDuplicates2/outputBamIndex
            - markDuplicates1/outputBamIndex

requirements:
    InlineJavascriptRequirement: {}

steps:
    markDuplicates1:
        in: 
            inputBams: inputBams
            outputBam:
                source: sampleName
                valueFrom: $(self + '.markdup.bam')
            metrics:
                source: sampleName
                valueFrom: $(self + '.markdup.metrics')
            outputDir: outputDir
        out: [outputBam, outputBamIndex, metricsFile, outputDir]
        run: ../../tools/picard-markduplicates_v2_26_10.cwl
    umi_tools_dedup:
        in:
            umiDeduplication: umiDeduplication
            inputBam: markDuplicates1/outputBam
            statsPrefix: sampleName
            outputBam:
                source: sampleName
                valueFrom: $(self + '.dedup.bam')
            outputDir: outputDir
        out: [deduppedBam, outputDir]
        run: ../../tools/umi_tools-dedup_v1_1_1.cwl
        when: $(inputs.umiDeduplication === true)
    markDuplicates2:
        in:
            umiDeduplication: umiDeduplication
            inputBams: 
                source: umi_tools_dedup/deduppedBam
                valueFrom: $([self])
            outputBam: 
                source: sampleName
                valueFrom: $(self + '.dedup.markdup.bam')
            metrics: 
                source: sampleName
                valueFrom: $(self + '.dedup.markdup.metrics')
            outputDir: outputDir
        out: [outputBam, outputBamIndex, metricsFile, outputDir]
        run: ../../tools/picard-markduplicates_v2_26_10.cwl
        when: $(inputs.umiDeduplication === true)
