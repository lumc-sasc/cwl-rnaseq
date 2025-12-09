cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "STAR Genome Generate"
doc: "A CWL Command Line Tool for the generation of the STAR index"

inputs:
    genomeDir:
        type: string
        default: "STAR_index"
        doc: "The directory the STAR index should be written to."
    referenceFasta:
        type: File
        doc: "The reference Fasta file."
    referenceGtf:
        type: File?
        doc: "The reference GTF file."
    sjdbOverhang:
        type: int?
        doc: "Equivalent to STAR's `--sjdbOverhang` option."
    runThreadN:
        type: int
        default: 4
        doc: "The number of threads to use."
    baseMemory:
        type: 
            - int?
            - string?
        default: "32G"
        doc: "The base amount of memory this job will use"
    outputDir:
        type: string
        default: "."
        doc: "The output directory."

outputs:
    chrLength:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/chrLength.txt"
        doc: "Text chromosome lengths file."
    chrNameLength:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/chrNameLength.txt"
        doc: "Text chromosome name lengths file."
    chrName:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/chrName.txt"
        doc: "Text chromosome names file."
    chrStart:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/chrStart.txt"
        doc: "Chromosome start sites file."
    genome:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/Genome"
        doc: "Binary genome sequence file."
    genomeParameters:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/genomeParameters.txt"
        doc: "Genome parameters file."
    sa:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/SA"
        doc: "Suffix arrays file."
    saIndex:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/SAindex"
        doc: "Index file of suffix arrays."
    exonGeTrInfo:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/exonGeTrInfo.tab"
        doc: "Exon, gene and transcript information file."
    exonInfo:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/exonInfo.tab"
        doc: "Exon information file."
    geneInfo:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/geneInfo.tab"
        doc: "Gene information file."
    sjdbInfo:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/sjdbInfo.txt"
        doc: "Splice junctions coordinates file."
    sjdbListFromGtfOut:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/sjdbList.fromGTF.out.tab"
        doc: "Splice junctions from input GTF file."
    sjdbListOut:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/sjdbList.out.tab"
        doc: "Splice junction list file."
    transcriptInfo:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/transcriptInfo.tab"
        doc: "Transcripts information file."
    starIndex:
        type: File[]
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.genomeDir)/*"
        doc: "A collection of all STAR index files."
    genomeDir:
        type: Directory
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.genomeDir)
        doc: "Directory containing all STAR index files."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/star_2.7.3a--0.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: $(inputs.runThreadN)
        coresMax: $(inputs.runThreadN)
        ramMin: $(inputs.baseMemory.replace(/G$/,"")*1024)
        ramMax: $(inputs.baseMemory.replace(/G$/,"")*1024)

arguments:
      - |
        mkdir -p $(inputs.outputDir + '/' + inputs.genomeDir)
        STAR \
        --runMode genomeGenerate \
        --runThreadN $(inputs.runThreadN) \
        --genomeDir $(inputs.outputDir + '/' + inputs.genomeDir) \
        --genomeFastaFiles $(inputs.referenceFasta.path) \
        $(inputs.referenceGtf ? "--sjdbGTFfile " + inputs.referenceGtf.path : "") \
        $(inputs.sjdbOverhang ? "--sjdbOverhang " + inputs.sjdbOverhang : "")