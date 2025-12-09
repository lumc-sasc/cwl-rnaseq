cwlVersion: v1.2
class: ExpressionTool
label: "Create subdirectory paths"
doc: "Creates strings for the paths to the subdirectories used to organise the output in the outputDir."

inputs:
    outputDir:
        type: string
        doc: "The output directory."

outputs:
    expressionDir:
        type: string
        doc: "The directory for expression analysis results. Defaults to a subdirectory of outputDir."
    genotypingDir:
        type: string
        doc: "The directory for variant calling and genotyping results. Defaults to a subdirectory of outputDir."

requirements:
    InlineJavascriptRequirement: {}

expression: |
    ${
        return {
            expressionDir: inputs.outputDir + "/expression_measures/",
            genotypingDir: inputs.outputDir + "/multisample_variants/"
        };
    }
