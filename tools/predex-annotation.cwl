cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "Predex Annotation"
doc: "A CWL Command Line Tool to convert a refernce Fasta-file, Fasta-file-index, and GTF-file into an annotation file for dge analysis."

inputs:
    referenceFasta:
        type: File
        secondaryFiles: 
            - .fai
        doc: "The reference Fasta file."
    referenceGtfFile:
        type: File
        doc: "The reference GTF file."
    outputDir:
        type: string
        default: "."
        doc: "The directory to write the output to."
    memory:
        type: string
        default: "5G"
        doc: "The amount of memory this job will use."

outputs:
    dgeAnnotation:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/annotation.tsv')
        doc: "Annotation file for DGE analysis."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir)"
        doc: "The output directory."
    
requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/predex:0.9.2--pyh3252c3a_0"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        ramMin: $(inputs.memory.replace(/G$/,"")*1024)
        ramMax: $(inputs.memory.replace(/G$/,"")*1024)

arguments:
      - |
        set -e
        mkdir -p $(inputs.outputDir)
        predex annotation \
        --fasta $(inputs.referenceFasta.path) \
        --gtf $(inputs.referenceGtfFile.path) \
        --output $(inputs.outputDir)