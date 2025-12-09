cwlVersion: v1.2
class: Workflow
label: "Alignment Workflow"
doc: "A CWL workflow that performs alignment on reads using either STAR or HISAT2."

inputs:
    read1:
        type: File
        doc: "The first-/single-end FastQ file."
    read2:
        type: File?
        doc: "The second-end FastQ file."
    starIndex:
        type: Directory?
        doc: "The STAR index files."
    hisat2Index:
        type: Directory?
        doc: "The hisat2 index files."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    outFileNamePrefix:
        type: string
        default: "star_align_"
        doc: "The prefix for the STAR output files."
    sampleJson:
        type: File
        loadContents: true
        doc: "The samplesheet, including sample ids, library ids, readgroup ids and fastq file locations."
    
outputs:
    bamFile:
        type: File
        pickValue: first_non_null
        outputSource:
            - starAlign/bamFile
            - hisat2Align/bamFile
        doc: "Bam Alignment File."
    logFile:
        type: File[]
        outputSource: 
            - starAlign/logFinalOut
            - hisat2Align/summaryFile
        doc: "Alignment logs (STAR Log.final.out or HISAT2 summary file)."
    outputDir:
        type: Directory[]?
        outputSource:
            - starAlign/outputDir
            - hisat2Align/outputDir
        doc: "The output directory."

requirements:
    InlineJavascriptRequirement: {}
    StepInputExpressionRequirement: {}
    MultipleInputFeatureRequirement: {}

steps:
    starAlign:
        in:
            inputR1: read1
            inputR2: read2
            indexFiles: starIndex
            outFileNamePrefix: outFileNamePrefix
            outputDir: outputDir
        out:
            [bamFile, logFinalOut ,outputDir]
        run: ../../tools/star_v2_7_3a.cwl
        when: $(inputs.indexFiles !== null && inputs.indexFiles.class === "Directory")
    hisat2Align:
        in:
            inputR1: read1
            inputR2: read2
            indexFiles: hisat2Index
            sampleJson: sampleJson
            starIndex: starIndex
            sample:
                valueFrom: ${ return JSON.parse(inputs.sampleJson.contents).samples[0].id}
            library:
                valueFrom: ${ return JSON.parse(inputs.sampleJson.contents).samples[0].readgroups[0].lib_id}
            readgroup:
                valueFrom: ${ return JSON.parse(inputs.sampleJson.contents).samples[0].readgroups[0].id}
            outputDir: outputDir
        out:
            [bamFile, summaryFile ,outputDir]
        run: ../../tools/hisat2_v2_1_0.cwl
        when: $(inputs.indexFiles !== null && inputs.indexFiles.class === "Directory" && (inputs.starIndex === null || inputs.starIndex.class !== "Directory"))
