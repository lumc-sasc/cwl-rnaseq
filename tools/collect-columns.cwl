cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "Collect Columns"
doc: "Combine columns from multiple tables into a single output table."

inputs:
    inputTables:
        type: File[]
        doc: "The tables from which columns should be taken."
    outputFile:
        type: string
        default: collect-collumns.out.tsv
        doc: "The output File name with extension."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    header:
        type: boolean
        default: false
        doc: "Equivalent to the -H flag of collect-columns."
    sumOnDuplicateId:
        type: boolean
        default: false
        doc: "Equivalent to the -S flag of collect-columns."
    featureColumn:
        type: int?
        doc: "Equivalent to the -f option of collect-columns."
    valueColumn:
        type: int?
        doc: "Equivalent to the -c option of collect-columns."
    separator:
        type: int?
        doc: "Equivalent to the -s option of collect-columns."
    sampleNames:
        type: string[]?
        doc: "Equivalent to the -n option of collect-columns."
    additionalAttributes:
        type: string[]?
        doc: "Equivalent to the -a option of collect-columns."
    referenceGtf:
        type: File?
        doc: "Equivalent to the -g option of collect-columns."
    featureAttribute:
        type: string?
        doc: "Equivalent to the -F option of collect-columns."

outputs:
    outputTable:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.outputFile)"
        doc: "All input columns combined into one table."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir)"
        doc: "The output directory."

requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/collect-columns:1.0.0--py_0"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        coresMin: 1
        coresMax: 1
        ramMin: $((4 + Math.ceil(0.5 * inputs.inputTables.length)) * 1024)
        ramMax: $((4 + Math.ceil(0.5 * inputs.inputTables.length)) * 1024 + 1024)


arguments:
      - |
        set -e
        mkdir -p $(inputs.outputDir)
        collect-columns \
        $(inputs.outputDir + '/' + inputs.outputFile) \
        $(inputs.inputTables.map(f => f.path).join(" ")) \
        $(inputs.featureColumn ? ("-f " + inputs.featureColumn) : "") \
        $(inputs.valueColumn ? ("-c " + inputs.valueColumn) : "") \
        $(inputs.separator ? ("-s " + inputs.separator) : "") \
        $(inputs.sampleNames ? ("-n " + inputs.sampleNames.join(" ")) : "") \
        $(inputs.header ? "-H" : "") \
        $(inputs.sumOnDuplicateId ? "-S" : "") \
        $(inputs.additionalAttributes ? ("-a " + inputs.additionalAttributes.join(" ")) : "") \
        $(inputs.referenceGtf ? ("-g " + inputs.referenceGtf.path) : "") \
        $(inputs.featureAttribute ? ("-F " + inputs.featureAttribute) : "")