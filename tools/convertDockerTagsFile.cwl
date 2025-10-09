cwlVersion: v1.2
class: CommandLineTool
baseCommand: bash
label: "convert Docker yaml to Json"
doc: "Converts a .yaml file to a .json file using bash and python."

inputs:
    yaml:
        type: File
        default: 
            class: File
            path: ../dockerImages.yml
    outputDir:
        type: string
        default: "."
    script:
        type: File
        default: 
            class: File
            path: yamlToJson.sh
    filename:
        type: string
        default: "DockerImages.json"

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
  - $(inputs.script.path)
  - $(inputs.yaml.path)
  - $(inputs.outputDir)
  - $(inputs.filename)