#!/bin/bash
IMAGE_DIR="" # Please set an absolute path for the image containing directory
WORKFLOW_ORIGINAL="cwl-rnaseq/Originals" # Location of original files with REPLACEPATH/<image>.sif
WORKFLOW_COPY="cwl-rnaseq/copies" # Location for files with correct container path

mkdir -p "$IMAGE_DIR"

IMAGES=(
    "docker://quay.io/biocontainers/collect-columns:1.0.0--py_0" # collect columns
    "docker://quay.io/biocontainers/cutadapt:2.10--py37hf01694f_1" # cutadapt
    "docker://quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0" # fastqc
    "docker://quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:a8096c2f99091fdceda3457a9b91c9b0553f8296-2" # hisat2
    "docker://quay.io/biocontainers/htseq:2.0.9--py311h8fb3dee_0" # htseq count
    "docker://quay.io/biocontainers/multiqc:1.9--py_1" # multiqc
    "docker://quay.io/biocontainers/picard:2.26.10--hdfd78af_0" # picard markduplicates
    "docker://quay.io/biocontainers/predex:0.9.2--pyh3252c3a_0" # predex annotation & predex design
    "docker://quay.io/biocontainers/biowdl-input-converter:0.3.0--pyhdfd78af_0" # sampleConversion
    "docker://quay.io/biocontainers/star:2.7.3a--0" # star & starGenomeGenerate
    "docker://quay.io/biocontainers/mulled-v2-509311a44630c01d9cb7d2ac5727725f51ea43af:3067b520386698317fd507c413baf7f901666fd4-0" # umi_tools dedup
)

for img in "${IMAGES[@]}"; do
    sif="$IMAGE_DIR/$(basename $img | sed 's|[:/]|_|g').sif"
    if [[ ! -f "$sif" ]]; then
        singularity pull "$sif" "$img"
    fi
done


cp -r "$WORKFLOW_ORIGINAL"/* "$WORKFLOW_COPY"
for file in "$WORKFLOW_ORIGINAL"/*/*.cwl; do
    relpath="${file#$WORKFLOW_ORIGINAL/}"
    dest="$WORKFLOW_COPY/$relpath"
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    sed -i "s|REPLACEPATH|$IMAGE_DIR|g" "$dest"
done

