cwlVersion: v1.2
class: Workflow
label: "RNA-sequencing data analysis pipeline"

inputs:
    sampleConfigFile:
        type: File
        doc: "The samplesheet, including sample IDs, library IDs, readgroup IDs, and fastq file locations. Fastq paths must be relative to the readLocation directory (starting from the directory specified there). Do not use ../ anywhere."
    outputDir:
        type: string
        default: "."
        doc: "The output directory."
    readLocation:
        type: Directory
        doc: "The directory containing the read files referenced in the sampleConfigFile. Use the directory that directly contains the reads as the input value."
    referenceFasta:
        type: File
        doc: "The reference fasta file."
    referenceFastaFai:
        type: File
        doc: "Fasta index (.fai) file of the reference."
    referenceFastaDict:
        type: File
        doc: "Sequence dictionary (.dict) file of the reference."
    platform:
        type: string
        default: "illumina"
        doc: "The platform used for sequencing."
    strandedness:
        type: string
        doc: "The strandedness of the RNA sequencing library preparation. One of 'None' (unstranded), 'FR' (forward-reverse: first read equal transcript) or 'RF' (reverse-forward: second read equals transcript)."
    lncRNAdatabases:
        type: File[]
        default: []
        doc: "A set of GTF files the assembled GTF file should be compared with. Only used if lncRNAdetection is set to `true`."
    variantCalling:
        type: boolean
        default: false
        doc: "Whether or not variantcalling should be performed."
    lncRNAdetection:
        type: boolean
        default: false
        doc: "Whether or not lncRNA detection should be run. This will enable detectNovelTranscript (this cannot be disabled by setting detectNovelTranscript to false). This will require cpatLogitModel and cpatHex to be defined."
    detectNovelTranscripts:
        type: boolean
        default: false
        doc: "Whether or not a transcripts assembly should be used. If set to true Stringtie will be used to create a new GTF file based on the BAM files. This generated GTF file will be used for expression quantification. If `referenceGtfFile` is also provided this reference GTF will be used to guide the assembly."
    dgeFiles:
        type: boolean
        default: false
        doc: "Whether or not input files for DGE should be generated."
    umiDeduplication:
        type: boolean
        default: false
        doc: "Whether or not UMI based deduplication should be performed."
    collectUmiStats:
        type: boolean
        default: false
        doc: "Whether or not UMI deduplication stats should be collected. This will potentially cause a massive increase in memory usage of the deduplication step."
    scatterSizeMillions:
        type: int
        default: 1000
        doc: "Same as scatterSize, but is multiplied by 1000000 to get scatterSize. This allows for setting larger values more easily."
    runStringtieQuantification:
        type: boolean
        default: true
        doc: "Option to disable running stringtie for quantification. This does not affect the usage of stringtie for novel transcript detection."
    dbsnpVCF:
        type: File?
        doc: "dbsnp VCF file used for checking known sites."
    dbsnpVCFIndex:
        type: File?
        doc: "Index (.tbi) file for the dbsnp VCF."
    starIndex:
        type: 
            - File[]?
            - Directory
        doc: "The star index files. Defining this will cause the star aligner to run and be used for downstream analyses. May be ommited if hisat2Index is defined."
    hisat2Index:
        type: 
            - File[]?
            - Directory
        doc: "The hisat2 index files. Defining this will cause the hisat2 aligner to run. Note that if starIndex is also defined the star results will be used for downstream analyses. May be omitted in starIndex is defined."
    adapterForward:
        type: string?
        doc: "The adapter to be removed from the reads first or single end reads."
    adapterReverse:
        type: string?
        doc: "The adapter to be removed from the reads second end reads."
    refflatFile:
        type: File?
        doc: "A refflat files describing the genes. If this is defined RNAseq metrics will be collected."
    referenceGtfFile:
        type: File?
        doc: "A reference GTF file. Used for expression quantification or to guide the transcriptome assembly if detectNovelTranscripts is set to `true` (this GTF won't be be used directly for the expression quantification in that case."
    cpatLogitModel:
        type: File?
        doc: "A logit model for CPAT. Required if lncRNAdetection is `true`."
    cpatHex:
        type: File?
        doc: "A hexamer frequency table for CPAT. Required if lncRNAdetection is `true`."
    scatterSize:
        type: int?
        doc: "The size of the scattered regions in bases for the GATK subworkflows. Scattering is used to speed up certain processes. The genome will be seperated into multiple chunks (scatters) which will be processed in their own job, allowing for parallel processing. Higher values will result in a lower number of jobs. The optimal value here will depend on the available resources."
    XNonParRegions:
        type: File?
        doc: "Bed file with the non-PAR regions of X for variant calling."
    YNonParRegions:
        type: File?
        doc: "Bed file with the non-PAR regions of Y for variant calling."
    variantCallingRegions:
        type: File?
        doc: "A bed file describing the regions to operate on for variant calling."
    starGenomeGenerateMemory:
        type: string?
        doc: "The amount of memory STAR Genome Generate will require to run. Please in '<numbers>G'."

outputs:
    report:
        type: File
        outputSource:
            - multiQC/multiQcReport
        doc: "The MultiQC report."
    # fragmentPerGeneTable:
    #     type: File
    #     outputSource: # expression.fragmentsPerGeneTable
    #     doc: "Table of counts per gene, generated from transcript assembly and alignment."
    dgeDesign:
        type: File?
        outputSource: predex_design/dgeDesign
        doc: "Design matrix template to add sample information for DGE analysis."
    dgeAnnotation:
        type: File?
        outputSource: predex_annotate/dgeAnnotation
        doc: "Annotation file for DGE analysis."
    # FPKMTable:
    #     type: File?
    #     outputSource: # expression.FPKMTable
    #     doc: "Table of normalized gene expression values in FPKM (Fragments Per Kilobase Million)."
    # TPMTable:
    #     type: File?
    #     outputSource: # expression.TPMTable
    #     doc: "Table of normalized gene expression values in TPM (Transcripts Per Million)."
    # mergedGtfFile:
    #     type: File?
    #     outputSource: # expression.mergedGtfFile
    #     doc: "Merged GTF file containing assembled transcripts from StringTie and/or reference GTF."
    # singleSampleVcfs:
    #     type: File[]
    #     outputSource: # select_all(variantcalling.outputVcf)
    #     doc: "VCF files containing variants detected per sample."
    # singleSampleVcfsIndex:
    #     type: File[]
    #     outputSource: # select_all(variantcalling.outputVcfIndex)
    #     doc: "Index files (.tbi) corresponding to the single-sample VCFs."
    # orfSeqs:
    #     type: File?
    #     outputSource: # CPAT.orfSeqs
    #     doc: "Predicted open reading frame (ORF) sequences from CPAT analysis."
    # orfProb:
    #     type: File?
    #     outputSource: # CPAT.orfProb
    #     doc: "Probabilities assigned to ORFs indicating coding potential."
    # orfProbBest:
    #     type: File?
    #     outputSource: # CPAT.orfProbBest
    #     doc: "ORFs with the highest coding potential probability per transcript."
    # noOrf:
    #     type: File?
    #     outputSource: # CPAT.noOrf
    #     doc: "Transcripts for which no valid ORF was predicted."
    # rScript:
    #     type: File?
    #     outputSource: # CPAT.rScript
    #     doc: "R script generated for CPAT analysis of ORFs."
    # annotatedGtf:
    #     type: File[]?
    #     outputSource: # GffCompare.annotated
    #     doc: "GTF file annotated by GffCompare with transcript comparison results."
    bamFiles:
        type: File[]
        outputSource: flatAlingBam/flatArray
        doc: "Aligned BAM files for each sample."
    # bamFilesIndex:
    #     type: File[]
    #     outputSource: # sampleJobs.outputBamIndex
    #     doc: "BAM index files (.bai) corresponding to aligned BAM files."
    recalibratedBamFiles:
        type: File[]
        outputSource: flatBam/flatArray
        doc: "BAM files after base quality score recalibration (BQSR)."
    recalibratedBamFilesIndex:
        type: File[]
        outputSource: flatBamIndex/flatArray
        doc: "Index files (.bai) corresponding to recalibrated BAM files."
    # umiEditDistance:
    #     type: File[]?
    #     outputSource: # sampleJobs.umiEditDistance
    #     doc: "Files reporting UMI edit distance statistics per sample."
    # umiStats:
    #     type: File[]?
    #     outputSource: # sampleJobs.umiStats
    #     doc: "UMI deduplication summary statistics files."
    # umiPositionStats:
    #     type: File[]?
    #     outputSource: # sampleJobs.umiPositionStats
    #     doc: "UMI positional statistics files for each sample."
    generatedStarIndex:
        type: Directory?
        outputSource: genomeGenerate/genomeDir
        doc: "Generated STAR index files used for alignment."
    reports:
        type: File[]?
        outputSource: flatReports/flatArray
        doc: "Collection of all QC and summary reports produced by the workflow."
    # gffCompareFiles:
    #     type: File[]?
    #     outputSource: # gffComparisonFiles
    #     doc: "Files generated by GffCompare comparing assembled transcripts to references."
    outputDir:
        type: Directory[]?
        outputSource: flatOutputDirs/flatArray

requirements:
    InlineJavascriptRequirement: {}
    SubworkflowFeatureRequirement: {}
    ScatterFeatureRequirement: {}
    StepInputExpressionRequirement: {}
    MultipleInputFeatureRequirement: {}

steps:
    sampleConversion:
        in:
            samplesheet: sampleConfigFile
            outputDir: outputDir
        out: [samples, outputDir]
        run: ../tools/sampleConversion_v0_3_0.cwl
    jsonParsed:
        in:
            jsonFile: sampleConversion/samples
            readLocation: readLocation
        out:
            [jsonDict]
        run: ../tools/json_sample_parser.cwl
    predex_design:
        in:
            dgeFiles: dgeFiles
            countTable: expressionQuantification/outputTable
            outputDir:
                source: outputDir
                valueFrom: $(self + '/dgeAnalysis')
        out: [dgeDesign, outputDir]
        run: ../tools/predex-design_v0_9_2.cwl
        when: $(inputs.dgeFiles === true)
    predex_annotate:
        in:
            dgeFiles: dgeFiles
            referenceGtfFile: referenceGtfFile
            referenceFasta: referenceFasta
            referenceFastaFai: referenceFastaFai
            outputDir:
                source: outputDir
                valueFrom: $(self + '/dgeAnalysis')
        out: [dgeAnnotation ,outputDir]
        run: ../tools/predex-annotation_v0_9_2.cwl
        when: $(inputs.dgeFiles === true && inputs.referenceGtfFile != null)
    genomeGenerate:
        in:
            referenceGtf: referenceGtfFile
            referenceFasta: referenceFasta
            baseMemory: starGenomeGenerateMemory
            outputDir: outputDir
        out: [genomeDir, outputDir]
        run: ../tools/starGenomeGenerate_v2_7_3a.cwl
        when: $(inputs.starIndex == null && inputs.hisat2Index == null)
    runSingleSample:
        in:
            samples: jsonParsed/jsonDict
            readLocation: readLocation
            adapterForward:
                source: adapterForward
                valueFrom: "$(self != null ? [self] : [])"
            adapterReverse:
                source: adapterReverse
                valueFrom: "$(self != null ? [self] : [])"
            outputDir: outputDir
            genomeDir: genomeGenerate/genomeDir
            starIndex: 
                source: starIndex
                valueFrom: "$(self != null ? self : inputs.genomeDir)"
            hisat2Index: hisat2Index
            sampleJson: sampleConversion/samples
            umiDeduplication: umiDeduplication
        out:
            - qcRead1
            - qcRead2
            - read1htmlReport
            - read1reportZip
            - read2htmlReport
            - read2reportZip
            - read1afterHtmlReport
            - read1afterReportZip
            - read2afterHtmlReport
            - read2afterReportZip
            - cutadaptReport
            - cutadaptRead1
            - cutadaptRead2
            - fastqcSummaries
            - reports
            - logFile
            - alignedBam
            - outputBam
            - outputBamIndex
            - metrics
            - outputDir
            - finalBam
            - finalBamIndex
        run: subworkflows/scatterdSamplesSubworkflow.cwl
        scatter: samples
        scatterMethod: dotproduct
    flatAlingBam:
        in: 
            inputData: runSingleSample/alignedBam
        out: [flatArray]
        run: ../tools/array_flatten.cwl
    flatBam:
        in: 
            inputData: runSingleSample/outputBam
        out: [flatArray]
        run: ../tools/array_flatten.cwl
    flatBamIndex:
        in: 
            inputData: runSingleSample/outputBamIndex
        out: [flatArray]
        run: ../tools/array_flatten.cwl
    flatContinueBam:
        in:
            inputData: runSingleSample/finalBam
        out: [flatArray]
        run: ../tools/array_flatten.cwl
    expressionQuantification:
        in:
            bamFiles: flatContinueBam/flatArray
            referenceGtf: referenceGtfFile
            detectNovelTranscripts: detectNovelTranscripts
            outputDir:
                source: outputDir
                valueFrom: $(self + '/expression_measures')
        out: [outputTable, looseTables, outputDir]
        run: subworkflows/expressionQuantification.cwl
    flatReports:
        in:
            inputData:
                - runSingleSample/read1reportZip
                - runSingleSample/read2reportZip
                - runSingleSample/read1afterReportZip
                - runSingleSample/read2afterReportZip
                - runSingleSample/metrics
                - expressionQuantification/outputTable
                - expressionQuantification/looseTables
        out: [flatArray]
        run: ../tools/array_flatten.cwl
    multiQC:
        in: 
            reports:
                flatReports/flatArray
            outputDir: outputDir
        out: [multiQcReport, multiQcDataZip, outputDir]
        run: ../tools/multiqc_v1_9.cwl
    flatOutputDirs:
        in:
            inputData:
                - sampleConversion/outputDir
                - predex_design/outputDir
                - predex_annotate/outputDir
                - runSingleSample/outputDir
                - expressionQuantification/outputDir
                - multiQC/outputDir
        out: [flatArray]
        run: ../tools/array_flatten.cwl