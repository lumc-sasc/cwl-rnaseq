cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "Cutadapt - Adapter Cutting Tool"
doc: "A CWL Command Line Tool for Cutadapt."

inputs:
    read1:
        type: File
        doc: "The first or single end fastq file to be run through cutadapt."
    read2:
        type: File?
        doc: "An optional second end fastq file to be run through cutadapt."
    read1output:
        type: string
        default: "cut_r1.fq.gz"
        doc: "The name of the resulting first or single end fastq file. Defaults to 'cut_r1.fq.gz'."
    read2output:
        type: string?
        default: "cut_r2.fq.gz"
        doc: "The name of the resulting second end fastq file. Defaults to 'cut_r2.fq.gz' if read2 is provided."
    adapter:
        type: string[]?
        doc: "A list of 3' ligated adapter sequences to be cut from the given first or single end fastq file."
    front:
        type: string[]?
        doc: "A list of 5' ligated adapter sequences to be cut from the given first or single end fastq file."
    anywhere:
        type: string[]?
        doc: "A list of 3' or 5' ligated adapter sequences to be cut from the given first or single end fastq file."
    adapterRead2:
        type: string[]?
        doc: "A list of 3' ligated adapter sequences to be cut from the given second end fastq file."
    frontRead2:
        type: string[]?
        doc: "A list of 5' ligated adapter sequences to be cut from the given second end fastq file."
    anywhereRead2:
        type: string[]?
        doc: "A list of 3' or 5' ligated adapter sequences to be cut from the given second end fastq file."
    reportPath:
        type: string
        default: "cutadapt_report.txt"
        doc: "The name of the file to write cutadapt's stdout to, this contains some metrics."
    compressionLevel:
        type: int
        default: 1
        doc: "The compression level if gzipped output is used."
    interleaved:
        type: boolean?
        doc: "Equivalent to cutadapt's --interleaved flag."
    pairFilter:
        type: string?
        doc: "Equivalent to cutadapt's --pair-filter option."
    errorRate:
        type: float?
        doc: "Equivalent to cutadapt's --error-rate option."
    noIndels:
        type: boolean?
        doc: "Equivalent to cutadapt's --no-indels flag."
    times:
        type: int?
        doc: "Equivalent to cutadapt's --times option."
    overlap:
        type: int?
        doc: "Equivalent to cutadapt's --overlap option."
    matchReadWildcards:
        type: boolean?
        doc: "Equivalent to cutadapt's --match-read-wildcards flag."
    noMatchAdapterWildcards:
        type: boolean?
        doc: "Equivalent to cutadapt's --no-match-adapter-wildcards flag."
    noTrim:
        type: boolean?
        doc: "Equivalent to cutadapt's --no-trim flag."
    maskAdapter:
        type: boolean?
        doc: "Equivalent to cutadapt's --mask-adapter flag."
    cut:
        type: int?
        doc: "Equivalent to cutadapt's --cut option."
    nextseqTrim:
        type: 
            - string?
            - int?
        doc: "Equivalent to cutadapt's --nextseq-trim option."
    qualityCutoff:
        type: 
            - string?
            - int?
        doc: "Equivalent to cutadapt's --quality-cutoff option."
    qualityBase:
        type: int?
        doc: "Equivalent to cutadapt's --quality-base option."
    length:
        type: int?
        doc: "Equivalent to cutadapt's --length option."
    trimN:
        type: boolean?
        doc: "Equivalent to cutadapt's --trim-n flag."
    lengthTag:
        type: string?
        doc: "Equivalent to cutadapt's --length-tag option."
    stripSuffix:
        type: string?
        doc: "Equivalent to cutadapt's --strip-suffix option."
    prefix:
        type: string?
        doc: "Equivalent to cutadapt's --prefix option."
    suffix:
        type: string?
        doc: "Equivalent to cutadapt's --suffix option."
    minimumLength:
        type: int
        default: 2
        doc: "Equivalent to cutadapt's --minimum-length option."
    maximumLength:
        type: int?
        doc: "Equivalent to cutadapt's --maximum-length option."
    maxN:
        type: int?
        doc: "Equivalent to cutadapt's --max-n option."
    discardTrimmed:
        type: boolean?
        doc: "Equivalent to cutadapt's --quality-cutoff option."
    discardUntrimmed:
        type: boolean?
        doc: "Equivalent to cutadapt's --discard-untrimmed option."
    infoFilePath:
        type: string?
        doc: "Equivalent to cutadapt's --info-file option."
    restFilePath:
        type: string?
        doc: "Equivalent to cutadapt's --rest-file option."
    wildcardFilePath:
        type: string?
        doc: "Equivalent to cutadapt's --wildcard-file option."
    tooShortOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --too-short-output option."
    tooLongOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --too-long-output option."
    untrimmedOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --untrimmed-output option."
    tooShortPairedOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --too-short-paired-output option."
    tooLongPairedOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --too-long-paired-output option."
    untrimmedPairedOutputPath:
        type: string?
        doc: "Equivalent to cutadapt's --untrimmed-paired-output option."
    colorspace:
        type: boolean?
        doc: "Equivalent to cutadapt's --colorspace flag."
    doubleEncode:
        type: boolean?
        doc: "Equivalent to cutadapt's --double-encode flag."
    stripF3:
        type: boolean?
        doc: "Equivalent to cutadapt's --strip-f3 flag."
    maq:
        type: boolean?
        doc: "Equivalent to cutadapt's --maq flag."
    bwa:
        type: boolean?
        doc: "Equivalent to cutadapt's --bwa flag."
    zeroCap:
        type: boolean?
        doc: "Equivalent to cutadapt's --zero-cap flag."
    noZeroCap:
        type: boolean?
        doc: "Equivalent to cutadapt's --no-zero-cap flag."
    cores:
        type: int
        default: 4
        doc: "The number of cores to use."
    baseMemory:
        type: 
            - int?
            - string?
        default: "5G"
        doc: "The base amount of memory this job will use"
    outputDir:
        type: string
        default: "."
        doc: "The output directory."

outputs:
    cutRead1:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.read1output)"
        doc: "Trimmed read one."
    report:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.reportPath)"
        doc: "Per-adapter statistics file."
    cutRead2:
        type: File?
        outputBinding:
            glob: "$(inputs.read2 ? inputs.outputDir + '/' + inputs.read2output : null)"
        doc: "Trimmed read two in pair."
    tooLongOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.tooLongOutputPath)"
        doc: "Reads that are too long according to -M."
    tooShortOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.tooShortOutputPath)"
        doc: "Reads that are too short according to -m."
    untrimmedOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.untrimmedOutputPath)"
        doc: "All reads without adapters (instead of the regular output file)."
    tooLongPairedOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.tooLongPairedOutputPath)"
        doc: "Second reads in a pair."
    tooShortPairedOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.tooShortPairedOutputPath)"
        doc: "Second reads in a pair."
    untrimmedPairedOutput:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.untrimmedPairedOutputPath)"
        doc: "The second reads in a pair that were not trimmed."
    infoFile:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.infoFilePath)"
        doc: "Detailed information about where adapters were found in each read."
    restFile:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.restFilePath)"
        doc: "The rest file."
    wildcardFile:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.wildcardFilePath)"
        doc: "The wildcard file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/cutadapt:2.10--py37hf01694f_1"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: $(inputs.cores)
        coresMax: $(inputs.cores)
        ramMin: $(inputs.baseMemory.replace(/G$/,"")*1024)
        ramMax: $(inputs.baseMemory.replace(/G$/,"")*1024)

arguments:
      - |
        set -e
        mkdir -p $(inputs.outputDir)
        cutadapt \
        --cores $(inputs.cores) \
        $(inputs.adapter ? "-a " + inputs.adapter : "") \
        $(inputs.adapterRead2 && inputs.read2 ? "-A " + inputs.adapterRead2 : "") \
        $(inputs.front ? " -g " + inputs.front : "") \
        $(inputs.frontRead2 && inputs.read2 ? " -G " + inputs.frontRead2 : "") \
        $(inputs.anywhere ? " -b " + inputs.anywhere : "") \
        $(inputs.anywhereRead2 && inputs.read2 ? " -B " + inputs.anywhereRead2 : "") \
        --output $(inputs.outputDir + '/' + inputs.read1output) $(inputs.read2 ? "-p " + inputs.outputDir + '/' + inputs.read2output : "") \
        --compression-level $(inputs.compressionLevel) \
        $(inputs.tooShortOutputPath ? "--too-short-output " + inputs.outputDir + "/" + inputs.tooShortOutputPath : "") \
        $(inputs.tooShortPairedOutputPath && inputs.read2 ? "--too-short-paired-output " + inputs.outputDir + "/" + inputs.tooShortPairedOutputPath : "") \
        $(inputs.tooLongOutputPath ? "--too-long-output " + inputs.outputDir + "/" + inputs.tooLongOutputPath : "") \
        $(inputs.tooLongPairedOutputPath && inputs.read2 ? "--too-long-paired-output " + inputs.outputDir + "/" + inputs.tooLongPairedOutputPath : "") \
        $(inputs.untrimmedOutputPath ? "--untrimmed-output " + inputs.outputDir + "/" + inputs.untrimmedOutputPath : "") \
        $(inputs.untrimmedPairedOutputPath && inputs.read2 ? "--untrimmed-paired-output " + inputs.outputDir + "/" + inputs.untrimmedPairedOutputPath : "") \
        $(inputs.pairFilter && inputs.read2 ? "--pair-filter " + inputs.pairFilter : "") \
        $(inputs.errorRate ? "--error-rate " + inputs.errorRate : "") \
        $(inputs.times ? "--times " + inputs.times : "") \
        $(inputs.overlap ? "--overlap " + inputs.overlap : "") \
        $(inputs.cut ? "--cut " + inputs.cut : "") \
        $(inputs.nextseqTrim ? "--nextseq-trim " + inputs.nextseqTrim : "") \
        $(inputs.qualityCutoff ? "--quality-cutoff " + inputs.qualityCutoff : "") \
        $(inputs.qualityBase ? "--quality-base " + inputs.qualityBase : "") \
        $(inputs.length ? "--length " + inputs.length : "") \
        $(inputs.lengthTag ? "--length-tag " + inputs.lengthTag : "") \
        $(inputs.stripSuffix ? "--strip-suffix " + inputs.stripSuffix : "") \
        $(inputs.prefix ? "--prefix " + inputs.prefix : "") \
        $(inputs.suffix ? "--suffix " + inputs.suffix : "") \
        $(inputs.minimumLength ? "--minimum-length " + inputs.minimumLength : "") \
        $(inputs.maximumLength ? "--maximum-length " + inputs.maximumLength : "") \
        $(inputs.maxN ? "--max-n " + inputs.maxN : "") \
        $(inputs.discardUntrimmed ? "--discard-untrimmed" : "") \
        $(inputs.infoFilePath ? "--info-file " + inputs.outputDir + "/" + inputs.infoFilePath : "") \
        $(inputs.restFilePath ? "--rest-file " + inputs.outputDir + "/" + inputs.restFilePath : "") \
        $(inputs.wildcardFilePath ? "--wildcard-file " + inputs.outputDir + "/" + inputs.wildcardFilePath : "") \
        $(inputs.matchReadWildcards ? "--match-read-wildcards" : "") \
        $(inputs.noMatchAdapterWildcards ? "--no-match-adapter-wildcards" : "") \
        $(inputs.noTrim ? "--no-trim" : "") \
        $(inputs.maskAdapter ? "--mask-adapter" : "") \
        $(inputs.noIndels ? "--no-indels" : "") \
        $(inputs.trimN ? "--trim-n": "") \
        $(inputs.interleaved ? "--interleaved" : "") \
        $(inputs.discardTrimmed ? "--discard-trimmed" : "") \
        $(inputs.colorspace ? "--colorspace" : "") \
        $(inputs.doubleEncode ? "--double-enconde" : "") \
        $(inputs.stripF3 ? "--strip-f3" : "") \
        $(inputs.maq ? "--maq" : "") \
        $(inputs.bwa ? "--bwa" : "") \
        $(inputs.zeroCap ? "--zero-cap" : "") \
        $(inputs.noZeroCap ? "--no-zero-cap" : "") \
        $(inputs.read1.path) \
        $(inputs.read2 ? inputs.read2.path : "") \
        > $(inputs.outputDir + '/' + inputs.reportPath)