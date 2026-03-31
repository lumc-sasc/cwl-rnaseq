cwlVersion: v1.2
class: CommandLineTool
baseCommand: [bash, -c]
label: "Picard MarkDuplicates"
doc: "A CWL CommandLineTool to run picard markduplicates."

inputs:
    inputBams:
        type: File[]
        doc: "The BAM files for which the duplicate reads should be marked."
    outputBam:
        type: string
        doc: "The location where the output BAM file should be written."
    metrics:
        type: string
        doc: "The location where the output metrics file should be written."
    compressionLevel:
        type: int?
        default: 1
        doc: "The compression level at which the BAM files are written."
    useJdkInflater:
        type: boolean?
        default: false
        doc: "True, uses the Java inflater. False, uses the optimized intel inflater."
    useJdkDeflater:
        type: boolean?
        default: true
        doc: "True, uses the Java deflator to compress the BAM files. False uses the optimized intel deflater."
    createMd5File:
        type: boolean?
        default: false
        doc: "Whether to create a md5 file for the created BAM file."
    read_name_regex:
        type: string?
        doc: "Equivalent to the `READ_NAME_REGEX` option of MarkDuplicates."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    javaXmxMb:
        type: int?
        default: 6656
        doc: "The maximum memory available to the program in megabytes. Should be lower than `memoryMb` to accommodate JVM overhead."
    memoryMb:
        type: int?
        default: 7168
        doc: "The amount of memory this job will use in megabytes."

outputs:
    outputBam:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.outputBam)
        secondaryFiles: [^.bai]
        doc: "The duplicate-marked BAM file, with index attached as secondaryFile."
    outputBamIndex:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.outputBam.replace(/\.bam$/, ".bai"))
        doc: "The index file of the duplicate-marked BAM file."
    metricsFile:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.metrics)
        doc: "Picard MarkDuplicates metrics file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/picard_2.23.2--0.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: 1
        ramMin: $(inputs.memoryMb)
        

arguments:
     - |
        mkdir -p $(inputs.outputDir)
        picard -Xmx$(inputs.javaXmxMb)M -XX:ParallelGCThreads=1 \
        MarkDuplicates \
        INPUT=$(inputs.inputBams.map(f => f.path).join(" INPUT=")) \
        OUTPUT=$(inputs.outputBam) \
        METRICS_FILE=$(inputs.metrics) \
        COMPRESSION_LEVEL=$(inputs.compressionLevel) \
        USE_JDK_INFLATER=$(inputs.useJdkInflater ? "true" : "false") \
        USE_JDK_DEFLATER=$(inputs.useJdkDeflater ? "true" : "false") \
        VALIDATION_STRINGENCY=SILENT \
        $(inputs.read_name_regex ? "READ_NAME_REGEX=" + inputs.read_name_regex : "") \
        OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
        CLEAR_DT=false \
        CREATE_INDEX=true \
        ADD_PG_TAG_TO_READS=false \
        CREATE_MD5_FILE=$(inputs.createMd5File ? "true" : "false")
        mv $(inputs.outputBam) $(inputs.outputDir + '/' + inputs.outputBam)
        mv $(inputs.outputBam.replace(/\.bam$/, ".bai")) $(inputs.outputDir + '/' + inputs.outputBam.replace(/\.bam$/, ".bai"))
        mv $(inputs.metrics) $(inputs.outputDir + '/' + inputs.metrics)