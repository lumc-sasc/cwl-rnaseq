cwlVersion: v1.2
class: Workflow
label: "BAM8 to Count Tables Workflow"
doc: "A CWL Workflow to turn BAM-files into count tables for ct_compare and tests.py to use"

inputs:
    WDLaBam:
        type: File[]
        doc: "Aligned BAM files from WDL pipeline."
    WDLmdBam:
        type: File[]
        doc: "Markduplicated BAM files from WDL pipeline."
    WDLudmdBam:
        type: File[]
        doc: "UMI deduplicated Markduplicated BAM files from WDL pipeline."
    CWLaBam:
        type: File[]
        doc: "Aligned BAM files from CWL pipeline."
    CWLmdBam:
        type: File[]
        doc: "Markduplicated BAM files from CWL pipeline."
    CWLudmdBam:
        type: File[]
        doc: "UMI deduplicated Markduplicated BAM files from CWL pipeline."
    referenceGtf:
        type: File
        doc: "A GTF/GFF file containing the features of interest."
    strandedness:
        type: string
        doc: "The strandedness of the RNA sequencing library preparation. One of 'None' (unstranded), 'FR' (forward-reverse: first read equal transcript) or 'RF' (reverse-forward: second read equals transcript)."
    outputDir:
        type: string
        default: "tmp"
        doc: "The output directory."

outputs:
    outputDirs:
        type: Directory[]
        outputSource: 
            - WDLaHTSeqCount/outputDir
            - WDLmdHTSeqCount/outputDir
            - WDLudmdHTSeqCount/outputDir
            - CWLaHTSeqCount/outputDir
            - CWLmdHTSeqCount/outputDir
            - CWLudmdHTSeqCount/outputDir
        linkMerge: merge_flattened

requirements:
    InlineJavascriptRequirement: {}
    ScatterFeatureRequirement: {}
    StepInputExpressionRequirement: {}
    MultipleInputFeatureRequirement: {}

steps:
    WDLaHTSeqCount:
        in:
            inputBams:
                source: WDLaBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/starAlign/WDL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
    CWLaHTSeqCount:
        in:
            inputBams:
                source: CWLaBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/starAlign/CWL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
    WDLmdHTSeqCount:
        in:
            inputBams:
                source: WDLmdBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/markdup/WDL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
    CWLmdHTSeqCount:
        in:
            inputBams:
                source: CWLmdBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/markdup/CWL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
    WDLudmdHTSeqCount:
        in:
            inputBams:
                source: WDLudmdBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/umimarkdup/WDL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
    CWLudmdHTSeqCount:
        in:
            inputBams:
                source: CWLudmdBam
                valueFrom: $([self])
            gtfFile: referenceGtf
            stranded: 
                source: strandedness
                valueFrom: "$(self === 'FR' ? 'yes' : self === 'RF' ? 'reverse' : 'no')"
            outputTable: 
                valueFrom: $(inputs.inputBams.basename.split(".")[0] + '.count_table.tsv')
            outputDir: 
                source: outputDir
                valueFrom: $(self + '/umimarkdup/CWL')
        out: [counts, outputDir]
        run: ../../cwl-rnaseq/copies/tools/htseq-count_v0_12_4.cwl
        scatter: inputBams
