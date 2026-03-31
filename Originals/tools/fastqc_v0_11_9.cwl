cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["/bin/bash", "-c"]
label: "FastQC - Quality Control Tool"
doc: "A CWL Command Line Tool for fastqc."

inputs:
    sequence:
        type: File
        doc: "A fastq file."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    casava:
        type: boolean
        default: false
        doc: "Equivalent to fastqc's --casava flag."
    nano:
        type: boolean
        default: false
        doc: "Equivalent to fastqc's --nano flag."
    noFilter:
        type: boolean
        default: false
        doc: "Equivalent to fastqc's --nofilter flag."
    extract:
        type: boolean
        default: false
        doc: "Equivalent to fastqc's --extract flag."
    nogroup:
        type: boolean
        default: false
        doc: "Equivalent to fastqc's --nogroup flag."
    threads:
        type: int
        default: 1
        doc: "The number of cores to use."
    contaminants:
        type: File?
        doc: "Equivalent to fastqc's --contaminants option."
    adapters:
        type: File?
        doc: "Equivalent to fastqc's --adapters option."
    limits:
        type: File?
        doc: "Equivalent to fastqc's --limits option."
    kmers:
        type: int?
        doc: "Equivalent to fastqc's --kmers option."
    baseMemory:
        type:
            - int
            - string
        default: "2G"
        doc: "The base amount of memory this job will use."
    timeMinutes:
        type: int
        default: 0
        doc: "The maximum amount of time the job will run in minutes."

outputs:
    htmlReport:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.sequence.basename.replace(/\\.gz$/, '').replace(/\\.[^.]*$/, '') + '_fastqc.html')"
        doc: "HTML report file."
    reportZip:
        type: File
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.sequence.basename.replace(/\\.gz$/, '').replace(/\\.[^.]*$/, '') + '_fastqc.zip')"
        doc: "Source data file."
    summary:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.sequence.basename.replace(/\\.gz$/, '').replace(/\\.[^.]*$/, '') + '_fastqc/summary.txt')"
        doc: "Summary file."
    rawReport:
        type: File?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.sequence.basename.replace(/\\.gz$/, '').replace(/\\.[^.]*$/, '') + '_fastqc/fastqc_data.txt')"
        doc: "Raw report file."
    images:
        type: File[]?
        outputBinding:
            glob: "$(inputs.outputDir + '/' + inputs.sequence.basename.replace(/\\.gz$/, '').replace(/\\.[^.]*$/, '') + '_fastqc/Images/*.png')"
        doc: "Images in report file."
    outputDir:
        type: Directory?
        outputBinding:
            glob: "$(inputs.outputDir === '.' ? null : inputs.outputDir.split('/')[0])"
        doc: "The output directory."
 

requirements:
    DockerRequirement:
        dockerImageId: "REPLACEPATH/fastqc_0.11.9--0.sif"
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
        envDef:
        - envName: JAVA_OPTS
          envValue: "-Djava.awt.headless=true"
    ResourceRequirement:
        coresMin: $(inputs.threads)
        ramMin: $(inputs.baseMemory.replace(/G$/,"")*1024)
    ToolTimeLimit:
        class: ToolTimeLimit
        timelimit: '$(inputs.timeMinutes != 0 ? inputs.timeMinutes * 60 : (1 + Math.ceil(inputs.sequence.size / 1000000000)) * 4 * 60)'

arguments:
     - |
        mkdir -p $(inputs.outputDir)
        fastqc -o $(inputs.outputDir) \
        $(inputs.casava ? "--casava" : "") \
        $(inputs.nano ? "--nano" : "") \
        $(inputs.noFilter ? "--nofilter" : "") \
        $(inputs.extract ? "--extract" : "") \
        $(inputs.nogroup ? "--nogroup" : "") \
        --threads $(inputs.threads) \
        $(inputs.contaminants ? ("--contaminants " + inputs.contaminants.path) : "") \
        $(inputs.adapters ? ("--adapters " + inputs.adapters.path) : "") \
        $(inputs.limits ? ("--limits " + inputs.limits.path) : "") \
        $(inputs.kmers != null ? ("--kmers " + inputs.kmers) : "") \
        $(inputs.sequence.path)