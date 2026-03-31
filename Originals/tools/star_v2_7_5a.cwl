cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "STAR alignment"
doc: "A CWL Command Line Tool for STAR."

inputs:
    inputR1:
        type: File 
        doc: "The first-/single-end FastQ files."
    inputR2:
        type: File?
        doc: "The second-end FastQ files (in the same order as the first-end files)."
    indexFiles:
        type: Directory
        loadListing: deep_listing
        doc: "The STAR index files."
    outFileNamePrefix:
        type: string
        doc: "The prefix for the output files. May include directories."
    outSAMtype:
        type: string
        default: "BAM SortedByCoordinate"
        doc: "The type of alignment file to be produced. Currently only `BAM SortedByCoordinate` is supported."
    readFilesCommand:
        type: string
        default: "zcat"
        doc: "Equivalent to STAR's `--readFilesCommand` option."
    outBAMcompression:
        type: int
        default: 1
        doc: "The compression level of the output BAM."
    outFilterScoreMin:
        type: int?
        doc: "Equivalent to STAR's `--outFilterScoreMin` option."
    outFilterScoreMinOverLread:
        type: float?
        doc: "Equivalent to STAR's `--outFilterScoreMinOverLread` option."
    outFilterMatchNmin:
        type: int?
        doc: "Equivalent to STAR's `--outFilterMatchNmin` option."
    outFilterMatchNminOverLread:
        type: float?
        doc: "Equivalent to STAR's `--outFilterMatchNminOverLread` option."
    outStd:
        type: string?
        doc: "Equivalent to STAR's `--outStd` option."
    twopassMode:
        type: string?
        default: "Basic"
        doc: "Equivalent to STAR's `--twopassMode` option."
    outSAMattrRGline:
        type: string[]?
        doc: "The readgroup lines for the FastQ pairs given (in the same order as the FastQ files)."
    outSAMunmapped:
        type: string?
        default: "Within KeepPairs"
        doc: "Equivalent to STAR's `--outSAMunmapped` option."
    limitBAMsortRAM:
        type: int?
        doc: "Equivalent to STAR's `--limitBAMsortRAM` option."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    runThreadN:
        type: int
        default: 4
        doc: "The number of threads to use."
    baseMemory:
        type:
            - int?
            - string?
        doc: "The base amount of memory this job will use."

outputs:
    bamFile:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.outFileNamePrefix + 'Aligned.sortedByCoord.out.bam')"
        doc: "Alignment file."
    logFinalOut:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.outFileNamePrefix + 'Log.final.out')
        doc: "Log information file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

    
requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/star_2.7.5a--0.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: "$(inputs.runThreadN)"
        ramMin: '$(inputs.baseMemory != null ? inputs.baseMemory : Math.max(4096, Math.ceil(((inputs.indexFiles.listing.reduce((s,x)=>s+(x.size||0),0)/1073741824)*1.3+1)*1024)))'

arguments:
      - |
        set -e
        mkdir -p $(inputs.outputDir)
        STAR \
        --readFilesIn $(inputs.inputR1.path) $(inputs.inputR2? inputs.inputR2.path : "") \
        --outFileNamePrefix $(inputs.outputDir + '/' + inputs.outFileNamePrefix) \
        --genomeDir $(inputs.indexFiles.path) \
        --outSAMtype $(inputs.outSAMtype) \
        --outBAMcompression $(inputs.outBAMcompression) \
        --readFilesCommand $(inputs.readFilesCommand) \
        $(inputs.outFilterScoreMin ? "--outFilterScoreMin " + inputs.outFilterScoreMin : "")\
        $(inputs.outFilterScoreMinOverLread ? "--outFilterScoreMinOverLread " + inputs.outFilterScoreMinOverLread : "") \
        $(inputs.outFilterMatchNmin ? "--outFilterMatchNmin " + inputs.outFilterMatchNmin : "") \
        $(inputs.outFilterMatchNminOverLread ? "--outFilterMatchNminOverLread " + inputs.outFilterMatchNminOverLread : "") \
        $(inputs.outSAMunmapped ? "--outSAMunmapped " + inputs.outSAMunmapped : "") \
        $(inputs.runThreadN ? "--runThreadN " + inputs.runThreadN : "") \
        $(inputs.outStd ? "--outStd " + inputs.outStd : "") \
        $(inputs.twopassMode ? "--twopassMode " + inputs.twopassMode : "") \
        $(inputs.limitBAMsortRAM ? "--limitBAMsortRAM " + inputs.limitBAMsortRAM : "") \
        $(inputs.outSAMattrRGline ? "--outSAMattrRGline " + inputs.outSAMattrRGline.join(" , ") : "") 