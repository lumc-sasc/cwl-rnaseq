cwlVersion: v1.2
class: CommandLineTool
baseCommand: bash
label: "convert yaml to Json"
doc: "Converts a .yaml file to a .json file using bash and python."

inputs:
    yaml:
        type: File
    outputDir:
        type: string
        default: "."
    script:
        type: File
        default: 
            class: File
            path: yamlToJson.sh
    json:
        type: string

outputs:
    dockerImagesList:
        type: File
        outputBinding:
            glob: $(inputs.outputDir + '/' + inputs.json)
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"

requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/biowdl-input-converter:0.3.0--pyhdfd78af_0"
    InlineJavascriptRequirement: {}

arguments:
  - $(inputs.script.path)
  - $(inputs.yaml.path)
  - $(inputs.outputDir)
  - $(inputs.json)