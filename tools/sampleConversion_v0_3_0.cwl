cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "Samplesheet conversion"
doc: "A CWL Command Line Tool to convert a samplesheet.csv to a JSON format using the biowdl-input-converter."

inputs:
    samplesheet:
        type: File
        doc: "CSV samplesheet to convert."
    outputDir:
        type: string
        default: "."
        doc: "The directory to write the output to."
    filename:
        type: string
        default: "samples.json"
        doc: "Name of the output JSON file."
    skipFileCheck:
        type: boolean
        default: true
        doc: "Skip checking for the existence of input files."
    checkFileMd5sums:
        type: boolean
        default: false
        doc: "Verify MD5 checksums of input files."
    old:
        type: boolean
        default: false
        doc: "Use old-style conversion format."

outputs:
    samples:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.filename)
        doc: "Converted samples JSON file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."

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