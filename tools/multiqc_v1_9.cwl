cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "MultiQC"
doc: "A CWL Command Line Tool for the aggregation of a multiQC report."

inputs:
    reports:
        type: File[]
        doc: "Reports which MultiQC should run on."
    force:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--force` flag."
    dirs:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--dirs` flag."
    fullNames:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--fullnames` flag."
    dataDir:
        type: boolean
        default: false
        doc: "Whether to output a data dir. Sets `--data-dir` or `--no-data-dir` flag."
    zipDataDir:
        type: boolean
        default: true
        doc: "Equivalent to MultiQC's `--zip-data-dir` flag."
    export:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--export` flag."
    flat:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--flat` flag."
    interactive:
        type: boolean
        default: true
        doc: "Equivalent to MultiQC's `--interactive` flag."
    lint:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--lint` flag."
    pdf:
        type: boolean
        default: false
        doc: "Equivalent to MultiQC's `--pdf` flag."
    megaQCUpload:
        type: boolean
        default: false
        doc: "Opposite to MultiQC's `--no-megaqc-upload` flag."
    dirsDepth:
        type: int?
        doc: "Equivalent to MultiQC's `--dirs-depth` option."
    title:
        type: string?
        doc: "Equivalent to MultiQC's `--title` option."
    comment:
        type: string?
        doc: "Equivalent to MultiQC's `--comment` option."
    fileName:
        type: string?
        doc: "Equivalent to MultiQC's `--filename` option."
    template:
        type: string?
        doc: "Equivalent to MultiQC's `--template` option."
    tag:
        type: string?
        doc: "Equivalent to MultiQC's `--tag` option."
    ignore:
        type: string?
        doc: "Equivalent to MultiQC's `--ignore` option."
    ignoreSamples:
        type: string?
        doc: "Equivalent to MultiQC's `--ignore-samples` option."
    sampleNames:
        type: File?
        doc: "Equivalent to MultiQC's `--sample-names` option."
    fileList:
        type: File?
        doc: "Equivalent to MultiQC's `--file-list` option."
    exclude:
        type: string[]?
        doc: "Equivalent to MultiQC's `--exclude` option."
    module:
        type: string[]?
        doc: "Equivalent to MultiQC's `--module` option."
    dataFormat:
        type: string?
        doc: "Equivalent to MultiQC's `--data-format` option."
    config:
        type: Directory?
        doc: "Equivalent to MultiQC's `--config` option."
    clConfig:
        type: File?
        doc: "Equivalent to MultiQC's `--cl-config` option."
    memory:
        type: string?
        doc: "The amount of memory this job will use."
    outputDir:
        type: string
        default: "."
        doc: "The directory to write the output to."

outputs:
    multiQcReport:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir)/$(inputs.fileName ? inputs.fileName : 'multiqc')_report.html"
        doc: "Results from bioinformatics analyses across many samples in a single report."
    multiQcDataZip:
        type: File?
        outputBinding:
            glob:  "$(inputs.outputDir)/$(inputs.fileName ? inputs.fileName : 'multiqc')_data.zip"
        doc: "Results from bioinformatics analyses across many samples in a single report."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."    

requirements:
    DockerRequirement:
        dockerPull: "quay.io/biocontainers/multiqc:1.9--py_1"
    InlineJavascriptRequirement: {}
    ResourceRequirement:
        ramMin: "$(inputs.memory ? inputs.memory * 1024 : (2 + Math.ceil(inputs.reports.size, 'G')) * 1024 || 4096)"
        ramMax: "$(inputs.memory ? inputs.memory * 1024 : (2 + Math.ceil(inputs.reports.size, 'G')) * 1024 || 5120)"

arguments:
      - |
        python3 - <<PYTHON
        import os
        from pathlib import Path
        reports = $(inputs.reports.map(function(r){ return r.path; }))
        report_dir = Path("reports")
        report_dir.mkdir(exist_ok=True)
        for report in reports:
            report_path = Path(report)
            new_path = report_dir / report_path.name
            os.symlink(report_path.resolve(), new_path)
        PYTHON
        mkdir -p $(inputs.outputDir)
        multiqc reports -o $(inputs.outputDir) \
        $(inputs.force ? "--force" : "") \
        $(inputs.dirs ? "--dirs" : "") \
        $(inputs.fullNames ? "--fullnames" : "") \
        $(inputs.dirsDepth ? "--dirs-depth " + inputs.dirsDepth : "") \
        $(inputs.title ? "--title " + inputs.title : "") \
        $(inputs.comment ? "--comment " + inputs.comment : "") \
        $(inputs.fileName ? "--filename " + inputs.fileName : "") \
        $(inputs.template ? "--template " + inputs.template : "") \
        $(inputs.tag ? "--tag " + inputs.tag : "") \
        $(inputs.ignore ? "--ignore " + inputs.ignore : "") \
        $(inputs.ignoreSamples ? "--ignore-samples " + inputs.ignoreSamples : "") \
        $(inputs.sampleNames ? "--sample-names " + inputs.sampleNames.path : "") \
        $(inputs.fileList ? "--file-list " + inputs.fileList.path : "") \
        $(inputs.exclude ? "--exclude " + inputs.exclude.join(" --exclude ") : "") \
        $(inputs.module ? "--module " + inputs.module.join(" --module ") : "") \
        $(inputs.dataDir ? "--data-dir" : "--no-data-dir") \
        $(inputs.dataFormat ? "--data-format " + inputs.dataFormat : "") \
        $(inputs.zipDataDir && inputs.dataDir ? "--zip-data-dir" : "") \
        $(inputs.export ? "--export" : "") \
        $(inputs.flat ? "--flat" : "") \
        $(inputs.interactive ? "--interactive" : "") \
        $(inputs.lint ? "--lint" : "") \
        $(inputs.pdf ? "--pdf" : "") \
        $(inputs.megaQCUpload ? "" : "--no-megaqc-upload") \
        $(inputs.config ? "--config " + inputs.config.path : "") \
        $(inputs.clConfig ? "--cl-config " + inputs.clConfig.path : "")