cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "HTSeq Count"
doc: "A CWL Command Line Tool for HTSeq Count"

inputs:
    inputBams:
        type: File[]
        doc: "The input BAM files."
    gtfFile:
        type: File
        doc: "A GTF/GFF file containing the features of interest."
    outputTable:
        type: string
        default: "output.tsv"
        doc: "The output table file name with extension."
    order:
        type: string
        default: "pos"
        doc: "Equivalent to the -r option of htseq-count."
    stranded:
        type: string
        default: "no"
        doc: "Equivalent to the -s option of htseq-count."
    additionalAttributes:
        type: string[]
        default: []
        doc: "Equivalent to the --additional-attr option of htseq-count."
    featureType:
        type: string?
        doc: "Equivalent to the --type option of htseq-count."
    idattr:
        type: string?
        doc: "Equivalent to the --idattr option of htseq-count."
    nprocesses:
        type: int
        default: 1
        doc: "Number of processes to run htseq with. This may NOT exceed the number of BAM files."
    baseMemory:
        type: string
        default: "8G"
        doc: "The amount of memory the job requires in GB."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."

outputs:
    counts:
        type: File
        outputBinding: 
            glob: $(inputs.outputDir + '/' + inputs.outputTable)
        doc: "Count table based on input BAM file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/htseq_0.12.4--py37h0498b6d_2.sif"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: $(inputs.nprocesses)
        coresMax: $(inputs.nprocesses)
        ramMin: $(inputs.baseMemory.replace(/G$/,"")*1024)
        ramMax: $(inputs.baseMemory.replace(/G$/,"")*1024 + 1024)

arguments:
      - |
        set -e
        mkdir -p $(inputs.outputDir)
        htseq-count \
        --nprocesses $(inputs.nprocesses) \
        -r $(inputs.order) \
        -s $(inputs.stranded) \
        $(inputs.featureType ? "--type " + inputs.featureType : "") \
        $(inputs.idattr ? "--idattr " + inputs.idattr : "") \
        $(inputs.additionalAttributes.length > 0 ? "--additional-attr " + inputs.additionalAttributes.join(" --additional-attr ") : "") \
        $(inputs.inputBams.map(function(f){return f.path}).join(" ")) \
        $(inputs.gtfFile.path)

stdout: $(inputs.outputDir + "/" + inputs.outputTable)