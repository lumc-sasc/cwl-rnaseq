cwlVersion: v1.2
class: CommandLineTool
baseCommand: bash -c
label: "Samplesheet conversion"
doc: "A CWL Command Line Tool to convert a samplesheet.csv to a JSON format using the biowdl-input-converter."

inputs:
    samplesheet:
        type: File
        default: 
            class: File
            path: ../samplesheet.csv
    outputDir:
        type: string
        default: "."
    filename:
        type: string
        default: "samples.json"
    skipFileCheck:
        type: boolean
        default: true
    checkFileMd5sums:
        type: boolean
        default: false
    old:
        type: boolean
        default: false

outputs:
    dockerImagesList:
        type: File
        outputBinding:
            glob: $(inputs.outputDir)/$(inputs.filename)
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir)"    

requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/biowdl-input-converter:0.3.0--pyhdfd78af_0"
    InlineJavascriptRequirement: {}

arguments: 
          - |
            set -e
            mkdir -p $(inputs.outputDir)
            biowdl-input-converter \
            -o $(inputs.outputDir)/$(inputs.filename) \
            $(inputs.skipFileCheck ? "--skip-file-check" : "") \
            $(inputs.checkFileMd5sums ? "--check-file-md5sums" : "") \
            $(inputs.old ? "--old" : "") \
            $(inputs.samplesheet.path)