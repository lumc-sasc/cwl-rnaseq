cwlVersion: v1.2
class: CommandLineTool
baseCommand: [bash, -c]
label: "Deduplicate BAM with umi_tools"
doc: "Deduplicates a BAM file using umi_tools and indexes the output."

inputs:
    inputBam:
        type: File
        secondaryFiles:
            - pattern: ^.bai
              required: true
        doc: "The input BAM file."
    outputBam:
        type: string
        doc: "The name of the output BAM file."
    tmpDir:
        type: string
        default: "./umiToolsDedupTmpDir"
        doc: "Temporary directory."
    paired:
        type: boolean?
        default: true
        doc: "Whether or not the data is paired."
    umiSeparator:
        type: string?
        doc: "Separator used for UMIs in the read names."
    statsPrefix:
        type: string?
        doc: "The prefix for the stats files."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    memory:
        type: string?
        default: "25G"
        doc: "The amount of memory required for the task."

outputs:
    deduppedBam:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.outputBam)
        doc: "Deduplicated BAM file."
    deduppedBamIndex:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.outputBam.replace(/\.bam$/, ".bai"))
        doc: "Index of the deduplicated BAM file."
    editDistance:
        type: File?
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.statsPrefix + '_edit_distance.tsv')
        doc: "Report of the (binned) average edit distance between the UMIs at each position."
    umiStats:
        type: File?
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.statsPrefix + '_per_umi.tsv')
        doc: "UMI-level summary statistics."
    positionStats:
        type: File?
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.statsPrefix + '_per_umi_per_position.tsv')
        doc: "The counts for unique combinations of UMI and position."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/mulled-v2-509311a44630c01d9cb7d2ac5727725f51ea43af_3067b520386698317fd507c413baf7f901666fd4-0.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        ramMin: $(parseInt(inputs.memory.replace(/G$/, "")) * 1024)
        ramMax: $(parseInt(inputs.memory.replace(/G$/, "")) * 1024 + 1024)
        coresMin: 1
        coresMax: 1

arguments:
     -  |
        mkdir -p $(inputs.outputDir) $(inputs.tmpDir)
        umi_tools dedup \
        --stdin=$(inputs.inputBam.path) \
        --stdout=$(inputs.outputBam) \
        $(inputs.statsPrefix ? "--output-stats " + inputs.statsPrefix : "") \
        $(inputs.umiSeparator ? "--umi-separator=" + inputs.umiSeparator : "") \
        $(inputs.paired ? "--paired" : "") \
        --temp-dir=$(inputs.tmpDir)
        samtools index $(inputs.outputBam) $(inputs.outputBam.replace(/\.bam$/, ".bai"))
        mv $(inputs.outputBam) $(inputs.outputDir + '/' + inputs.outputBam)
        mv $(inputs.outputBam.replace(/\.bam$/, ".bai")) $(inputs.outputDir + '/' + inputs.outputBam.replace(/\.bam$/, ".bai"))
        $(inputs.statsPrefix ? "mv " + inputs.statsPrefix + "_edit_distance.tsv " + inputs.outputDir + "/" + inputs.statsPrefix + "_edit_distance.tsv" : "")
        $(inputs.statsPrefix ? "mv " + inputs.statsPrefix + "_per_umi.tsv " + inputs.outputDir + "/" + inputs.statsPrefix + "_per_umi.tsv" : "")
        $(inputs.statsPrefix ? "mv " + inputs.statsPrefix + "_per_umi_per_position.tsv " + inputs.outputDir + "/" + inputs.statsPrefix + "_per_umi_per_position.tsv" : "")
