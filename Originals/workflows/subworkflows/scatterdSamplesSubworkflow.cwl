cwlVersion: v1.2
class: Workflow
label: "Single-sample QC and Alignment Workflow"
doc: "Workflow for quality control, alignment, and metrics on a single sample/readgroup. Scatter and flatten are handled externally."

inputs:
    samples:
        type:
            type: record
            name: sample_record
            fields:
                - name: id
                  type: string
                - name: readgroups
                  type:
                      type: array
                      items:
                          type: record
                          name: readgroup_record
                          fields:
                              - name: id
                                type: string
                              - name: R1
                                type: File
                              - name: R1_md5
                                type: string?
                              - name: R2
                                type: File?
                              - name: R2_md5
                                type: string?
                              - name: lib_id
                                type: string
        doc: "Sample definitions with loose sample id and nested readgroups."
    readLocation:
        type: Directory
        doc: "The directory containing the reads referred to in the samples. Please use the first directory in the path referred to as input value."
    adapterForward:
        type: string[]?
        doc: "The adapter to be removed from the reads first or single end reads." 
    adapterReverse: 
        type: string[]?
        doc: "The adapter to be removed from the reads second end reads."
    starIndex:
        type: Directory?
    hisat2Index:
        type: Directory?
    indexFiles:
        type: File[]
        doc: "File array of the index that will be used. (STAR > Hisat2 > GenomeGenerate)"
    umiDeduplication:
        type: boolean
        default: false
    collectUmiStats:
        type: boolean
        default: false
        doc: "Whether or not UMI deduplication stats should be collected. This will potentially cause a massive increase in memory usage of the deduplication step."
    umiSeparator:
        type: string?
        doc: "Separator used for UMIs in the read names."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."

outputs:
    qcRead1:
        type: File?
        outputSource: qualityControl/qcRead1
        doc: "Quality control output file for first read."
    qcRead2:
        type: File?
        outputSource: qualityControl/qcRead2
        doc: "Quality control output file for second read (if paired‑end)."
    read1htmlReport:
        type: File?
        outputSource: qualityControl/read1htmlReport
        doc: "HTML report of QC results for first read."
    read1reportZip:
        type: File?
        outputSource: qualityControl/read1reportZip
        doc: "Compressed QC report archive for first read."
    read1afterHtmlReport:
        type: File?
        outputSource: qualityControl/read1afterHtmlReport
        doc: "HTML QC report for first read after trimming."
    read1afterReportZip:
        type: File?
        outputSource: qualityControl/read1afterReportZip
        doc: "Compressed QC report archive for first read after trimming."
    read2htmlReport:
        type: File?
        outputSource: qualityControl/read2htmlReport
        doc: "HTML report of QC results for second read."
    read2reportZip:
        type: File?
        outputSource: qualityControl/read2reportZip
        doc: "Compressed QC report archive for second read."
    read2afterHtmlReport:
        type: File?
        outputSource: qualityControl/read2afterHtmlReport
        doc: "HTML QC report for second read after trimming."
    read2afterReportZip:
        type: File?
        outputSource: qualityControl/read2afterReportZip
        doc: "Compressed QC report archive for second read after trimming."
    cutadaptReport:
        type: File?
        outputSource: qualityControl/cutadaptReport
        doc: "Report from adapter trimming step."
    cutadaptRead1:
        type: File?
        outputSource: qualityControl/cutadaptRead1
        doc: "Trimmed first‑read FASTQ file."
    cutadaptRead2:
        type: File?
        outputSource: qualityControl/cutadaptRead2
        doc: "Trimmed second‑read FASTQ file (if paired‑end)."
    fastqcSummaries:
        type: File[]?
        outputSource: qualityControl/fastqcSummaries
        doc: "Summary reports from FastQC analyses."
    reports:
        type: File[]?
        outputSource: qualityControl/reports
        doc: "Collection of all QC report files."
    alignedBam:
        type: File?
        outputSource: alignment/bamFile
        doc: "BAM file(s) produced by the alignment step."
    logFile:
        type: File[]?
        outputSource: alignment/logFile
        doc: "Log file(s) from the alignment step."
    outputBam:
        type: File[]?
        outputSource: metrics/outputBam
        doc: "Final BAM file(s) after deduplication and/or recalibration."
    outputBamIndex:
        type: File[]?
        outputSource: metrics/outputBamIndex
        doc: "Index (.bai) file(s) corresponding to the final BAM(s)."
    metrics:
        type: File[]?
        outputSource: metrics/metrics
        doc: "Metrics output file(s) summarising alignment/deduplication statistics."
    outputDir:
        type: Directory[]?
        outputSource: flatOutputDirs/flatArray
        doc: "Directories containing outputs for each sample."
    finalBam:
        type: File
        outputSource: metrics/finalBam
        doc: "The BAM file with which the workflow should continue."
    finalBamIndex:
        type: File
        outputSource: metrics/finalBamIndex
        doc: "The BAM index file with which the workflow should continue."
    editDistance:
        type: File?
        outputSource: metrics/editDistance
        doc: "Report of the (binned) average edit distance between the UMIs at each position."
    umiStats:
        type: File?
        outputSource: metrics/umiStats
        doc: "UMI-level summary statistics."
    positionStats:
        type: File?
        outputSource: metrics/positionStats
        doc: "The counts for unique combinations of UMI and position."

steps:
    qualityControl:
        in:
            sample: samples
            readLocation: readLocation
            read1:
                valueFrom: $(inputs.sample.readgroups[0].R1)
            read2:
                valueFrom: $(inputs.sample.readgroups[0].R2)
            adapterForward: adapterForward
            adapterReverse: adapterReverse
            readGroupName: 
                valueFrom: $(inputs.sample.readgroups[0].R1.basename.replace(/(\.fastq|\.fq)(\.gz)?$/, ""))
            outputDir:
                source: outputDir
                valueFrom: $(self + '/samples/' + inputs.sample.id + '/lib_' + inputs.sample.readgroups[0].lib_id + '--rg_' + inputs.sample.readgroups[0].id)
        out: [qcRead1, qcRead2, read1htmlReport, read1reportZip, read2htmlReport, read2reportZip, read1afterHtmlReport, read1afterReportZip, read2afterHtmlReport, read2afterReportZip, cutadaptReport, cutadaptRead1, cutadaptRead2, fastqcSummaries, reports, outputDir]
        run: qualityControl.cwl

    alignment:
        in:
            sample: samples
            readLocation: readLocation
            read1:
                source: qualityControl/qcRead1
                valueFrom: "$(self !== null ? self : inputs.sample.readgroups[0].R1)"
            read2:
                source: qualityControl/qcRead2
                valueFrom: "$(self !== null ? self : (inputs.sample.readgroups[0].R2 != null ? inputs.sample.readgroups[0].R2 : null))"
            starIndex: starIndex
            hisat2Index: hisat2Index
            indexFiles: indexFiles
            outputDir:
                source: outputDir
                valueFrom: $(self + '/samples/' + inputs.sample.id + '/lib_' + inputs.sample.readgroups[0].lib_id + '--rg_' + inputs.sample.readgroups[0].id)
        out: [bamFile, logFile, outputDir]
        run: alignment.cwl

    metrics:
        in:
            sample: samples
            readLocation: readLocation
            inputBams: 
                source: alignment/bamFile
                valueFrom: $([self])
            sampleName:
                valueFrom: $(inputs.sample.id)
            umiDeduplication: umiDeduplication
            umiSeparator: umiSeparator
            collectUmiStats: collectUmiStats
            outputDir:
                source: outputDir
                valueFrom: $(self + '/samples/' + inputs.sample.id)
        out: [outputBam, outputBamIndex, metrics, outputDir, finalBam, finalBamIndex, editDistance, umiStats, positionStats]
        run: metrics.cwl
    flatOutputDirs:
        in:
            inputData:
                - qualityControl/outputDir
                - alignment/outputDir
                - metrics/outputDir
        out: [flatArray]
        run: ../../tools/array_flatten.cwl
