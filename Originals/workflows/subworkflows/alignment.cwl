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
    sample:
        type:
            type: record
            name: sample_record
            fields:
                - name: id
                  type: string
                - name: readgroups
                  type:
                      type: array
                      items:
                          type: record
                          name: readgroup_record
                          fields:
                              - name: id
                                type: string
                              - name: R1
                                type: File
                              - name: R1_md5
                                type: string?
                              - name: R2
                                type: File?
                              - name: R2_md5
                                type: string?
                              - name: lib_id
                                type: string
        doc: "Sample definitions with loose sample id and nested readgroups."
    
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
            outFileNamePrefix: 
                source: sample
                valueFrom: $(self.id + "-" + self.readgroups[0].lib_id + "-" + self.readgroups[0].id + ".star.")
            outputDir: outputDir
        out:
            [bamFile, logFinalOut ,outputDir]
        run: ../../tools/star_v2_7_5a.cwl
        when: $(inputs.indexFiles !== null && inputs.indexFiles.class === "Directory")
    hisat2Align:
        in:
            inputR1: read1
            inputR2: read2
            indexFiles: hisat2Index
            starIndex: starIndex
            sample:
                valueFrom: inputs.sample.id
            library:
                valueFrom: inputs.sample.readgroups[0].lib_id
            readgroup:
                valueFrom: inputs.sample.readgroups[0].id
            outputDir: outputDir
        out:
            [bamFile, summaryFile ,outputDir]
        run: ../../tools/hisat2_v_44da2652.cwl
        when: $(inputs.indexFiles !== null && inputs.indexFiles.class === "Directory" && (inputs.starIndex === null || inputs.starIndex.class !== "Directory"))
