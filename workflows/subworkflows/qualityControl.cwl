cwlVersion: v1.2
class: Workflow
label: "Quality Control Workflow"
doc: "A CWL workflow that performs quality control on sequencing reads using FastQC, trimming adapters or contaminants with Cutadapt when provided, and running FastQC again on the processed reads."

inputs:
    read1:
        type: File
        doc: "The first or single end fastq file to be run through cutadapt."
    read2:
        type: File?
        doc: "An optional second end fastq file to be run through cutadapt."
    outputDir:
        type: string
        default: "."
        doc: "The directory to which the outputs will be written."
    readGroupName:
        type: string
        default: $(inputs.read1.basename.replace(/(\.fastq|\.fq)(\.gz)?$/, ""))
        doc: "The name of the readgroup."
    extractFastqcZip:
        type: boolean
        default: false
        doc: "Whether to extract Fastqc's report zip files."
    adapterForward:
        type: string[]?
        doc: "The adapter to be removed from the reads first or single end reads."
    adapterReverse:
        type: string[]?
        doc: "The adapter to be removed from the reads second end reads."
    contaminations:
        type: string[]?
        doc: "Contaminants/adapters to be removed from the reads."

outputs:
    qcRead1:
        type: File
        outputSource: Cutadapt/cutRead1
        doc: "The first or single end fastq file processed by CutAdapt."
    qcRead2:
        type: File?
        outputSource: Cutadapt/cutRead2
        doc: "An optional second end fastq file processed by CutAdapt."
    read1htmlReport:
        type: File
        outputSource: FastqcRead1/htmlReport
        doc: "Fastqc HTML report for the first or single end fastq file."
    read1reportZip:
        type: File
        outputSource: FastqcRead1/reportZip
        doc: "Fastqc zip archive containing data for the first or single end fastq file."
    read2htmlReport:
        type: File?
        outputSource: FastqcRead2/htmlReport
        doc: "Fastqc HTML report for the optional second end fastq file."
    read2reportZip:
        type: File?
        outputSource: FastqcRead2/reportZip
        doc: "Fastqc zip archive containing data for the optional second end fastq file."
    read1afterHtmlReport:
        type: File?
        outputSource: FastqcRead1After/htmlReport
        doc: "Fastqc HTML report for the first or single end fastq file after CutAdapt processing."
    read1afterReportZip:
        type: File?
        outputSource: FastqcRead1After/reportZip
        doc: "Fastqc zip archive containing data for the first or single end fastq file after CutAdapt processing."
    read2afterHtmlReport:
        type: File?
        outputSource: FastqcRead2After/htmlReport
        doc: "Fastqc HTML report for the optional second end fastq file after CutAdapt processing."
    read2afterReportZip:
        type: File?
        outputSource: FastqcRead2After/reportZip
        doc: "Fastqc zip archive containing data for the optional second end fastq file after CutAdapt processing."
    cutadaptReport:
        type: File?
        outputSource: Cutadapt/report
        doc: "Report from CutAdapt processing of input fastq file(s)."
    cutadaptRead1:
        type: File?
        outputSource: Cutadapt/cutRead1
        doc: "Read 1 FASTQ file after adapter trimming."
    cutadaptRead2:
        type: File?
        outputSource: Cutadapt/cutRead2
        doc: "Read 2 FASTQ file after adapter trimming (if paired-end)."
    fastqcSummaries:
        type: File[]?
        outputSource:
        - FastqcRead1/summary
        - FastqcRead2/summary
        - FastqcRead1After/summary
        - FastqcRead2After/summary
        doc: "Fastqc summary file(s)."
    reports:
        type: File[]?
        outputSource:
        - FastqcRead1/htmlReport
        - FastqcRead1/reportZip
        - FastqcRead2/htmlReport
        - FastqcRead2/reportZip
        - FastqcRead1After/htmlReport
        - FastqcRead1After/reportZip
        - FastqcRead2After/htmlReport
        - FastqcRead2After/reportZip
        - Cutadapt/report
        doc: "Collection of all reports produced by the workflow."
    outputDir:
        type: Directory[]?
        outputSource:
        - FastqcRead1/outputDir
        - FastqcRead2/outputDir
        - Cutadapt/outputDir
        - FastqcRead1After/outputDir
        - FastqcRead2After/outputDir
        doc: "The output directory."

requirements:
    - class: InlineJavascriptRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement

steps:
    FastqcRead1:
        in:
            sequence: read1
            outputDir: outputDir
            extract: extractFastqcZip
        out:
            [htmlReport, reportZip, summary, outputDir]
        run: ../../tools/fastqc_v0_12_1.cwl
    FastqcRead2:
        in:
            sequence: read2
            outputDir: outputDir
            extract: extractFastqcZip
        out:
            [htmlReport, reportZip, summary, outputDir]
        run: ../../tools/fastqc_v0_12_1.cwl
        when: $(inputs.sequence != null)
    Cutadapt:
        in:
            read1: read1
            read2: read2
            read1output: 
                valueFrom: $( 'cutadapt_' + inputs.read1.basename )
            read2output: 
                valueFrom: "$( inputs.read2 ? 'cutadapt_' + inputs.read2.basename : '' )"
            readGroupName: readGroupName
            adapter: adapterForward
            adapterRead2: adapterReverse
            anywhere: contaminations
            anywhereRead2: contaminations
            outputDir: outputDir
            reportPath: 
                valueFrom: $( inputs.readGroupName + '_cutadapt_report.txt' )
        out:
            [cutRead1, cutRead2, report, outputDir]
        run: ../../tools/cutadapt_v2_10.cwl
        when: $((inputs.adapter != null && inputs.adapter.length > 0) || (inputs.adapterRead2 != null && inputs.adapterRead2.length > 0) || (inputs.anywhere != null && inputs.anywhere.length > 0))
    FastqcRead1After:
        in:
            sequence: Cutadapt/cutRead1
            outputDir: outputDir
            extract: extractFastqcZip
        out:
            [htmlReport, reportZip, summary, outputDir]
        run: ../../tools/fastqc_v0_12_1.cwl
        when: $(inputs.sequence != null)
    FastqcRead2After:
        in:
            sequence: Cutadapt/cutRead2
            outputDir: outputDir
            extract: extractFastqcZip
        out:
            [htmlReport, reportZip, summary, outputDir]
        run: ../../tools/fastqc_v0_12_1.cwl
        when: $(inputs.sequence != null)
