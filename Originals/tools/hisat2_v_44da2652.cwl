cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "HISAT2 Alignment" 
doc: "A CWL Command Line Tool for HISAT2."

inputs:
    inputR1:
        type: File
        doc: "The first-/single-end FastQ file."
    inputR2:
        type: File?
        doc: "The second-end FastQ file."
    indexFiles:
        type: Directory
        loadListing: shallow_listing
        doc: "The hisat2 index files."
    outputBam:
        type: string
        default: "hisat2.bam"
        doc: "The location the output BAM file should be written to."
    sample:
        type: string
        doc: "The sample id."
    library:
        type: string
        doc: "The library id."
    readgroup:
        type: string
        doc: "The readgroup id."
    platform:
        type: string
        default: "illumina"
        doc: "The platform used for sequencing."
    downstreamTranscriptomeAssembly:
        type: boolean
        default: true
        doc: "Equivalent to hisat2's `--dta` flag."
    summaryFilePath:
        type: string?
        doc: "Where the summary file should be written."
    sortMemoryPerThreadGb:
        type: int
        default: 2
        doc: "The amount of memory for each sorting thread in gigabytes."
    compressionLevel:
        type: int
        default: 1
        doc: "The compression level of the output BAM."
    sortThreads:
        type: int?
        doc: "The number of threads to use for sorting."
    threads:
        type: int?
        default: 1
        doc: "The number of threads to use."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."

outputs:
    bamFile:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.outputBam)"
        doc: "Output BAM file."
    summaryFile:
        type: File
        outputBinding:
            glob: "$(inputs.summaryFilePath ? inputs.outputDir + '/' + inputs.summaryFilePath : inputs.outputDir + '/' + inputs.outputBam.split('.')[0] + '.summary.txt')"
        doc: "Alignment summary file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1_2880dd9d8ad0a7b221d4eacda9a818e92983128d-0.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: '$(inputs.threads)'
        ramMin: '$(Math.ceil(((inputs.sortThreads !== undefined ? inputs.sortThreads : (inputs.threads == 1 ? 1 : 1 + Math.ceil(inputs.threads / 4))) * inputs.sortMemoryPerThreadGb + 1 + Math.ceil(inputs.indexFiles.listing.reduce((a, f) => a + (f.size || 0), 0) / (1024 ** 3) * 1.2)) * 1024))'

arguments:
      - |
        mkdir -p $(inputs.outputDir)
        hisat2 \
        $(inputs.threads ? "-p " + inputs.threads : "") \
        -x $(inputs.indexFiles.listing[0].path.split('.')[0]) \
        $(inputs.inputR2 ? "-1 " + inputs.inputR1.path + " -2 " + inputs.inputR2.path : "-U " + inputs.inputR1.path) \
        --rg-id $(inputs.readgroup) \
        --rg SM:$(inputs.sample) \
        --rg LB:$(inputs.library) \
        --rg PL:$(inputs.platform) \
        $(inputs.downstreamTranscriptomeAssembly ? "--dta" : "") \
        --new-summary \
        --summary-file $(inputs.summaryFilePath ? inputs.outputDir + '/' + inputs.summaryFilePath : inputs.outputDir + '/' + inputs.outputBam.split('.')[0] + '.summary.txt') \
        | \
        samtools sort \
        $(inputs.sortThreads ? "-@ " + inputs.sortThreads : "") \
        $(inputs.sortMemoryPerThreadGb ? "-m " + inputs.sortMemoryPerThreadGb + "G" : "") \
        $(inputs.compressionLevel ? "-l " + inputs.compressionLevel : "") \
        - \
        -o $(inputs.outputDir + '/' + inputs.outputBam)