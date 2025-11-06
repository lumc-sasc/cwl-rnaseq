cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "Predex Design"
doc: "A CWL Command Line Tool to convert a countTable into a design matrix."

inputs:
    countTable:
        type: File
        doc: "The created count table from HTseq."
    outputDir:
        type: string
        default: "."
        doc: "The directory to write the output to."
    memory:
        type: string
        default: "5G"
        doc: "The amount of memory this job will use."

outputs:
    dgeDesign:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/design_matrix.tsv')
        doc: "Design matrix template to add sample information for DGE analysis."
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
        predex design \
        --input $(inputs.countTable.path) \
        --output $(inputs.outputDir)