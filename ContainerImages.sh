#!/bin/bash
IMAGE_DIR="" # Please set an absolute path for the image containing directory
WORKFLOW_ORIGINAL="Originals" # Location of original files with REPLACEPATH/<image>.sif
WORKFLOW_COPY="copies" # Location for files with correct container path

if [[ -z "$IMAGE_DIR" ]]; then
    echo "Error: IMAGE_DIR is empty." >&2
    exit 1
fi

if [[ -z "$WORKFLOW_ORIGINAL" ]]; then
    echo "Error: WORKFLOW_ORIGINAL is not set." >&2
    exit 1
fi

if [[ ! -e "$WORKFLOW_ORIGINAL" ]]; then
    echo "Error: WORKFLOW_ORIGINAL does not exist: $WORKFLOW_ORIGINAL" >&2
    exit 1
fi

if [[ -z "$WORKFLOW_COPY" ]]; then
    echo "Error: WORKFLOW_COPY is not set." >&2
    exit 1
fi

mkdir -p "$IMAGE_DIR"
mkdir -p "$WORKFLOW_COPY"

if [[ ! -d "$IMAGE_DIR" ]]; then
    echo "Error: IMAGE_DIR does not exist: $IMAGE_DIR" >&2
    exit 1
fi

IMAGES=(
    "docker://quay.io/biocontainers/collect-columns:1.0.0--py_0" # collect columns
    "docker://quay.io/biocontainers/cutadapt:2.10--py37hf01694f_1" # cutadapt
    "docker://quay.io/biocontainers/fastqc:0.11.9--0" # fastqc
    "docker://quay.io/biocontainers/mulled-v2-a97e90b3b802d1da3d6958e0867610c718cb5eb1:2880dd9d8ad0a7b221d4eacda9a818e92983128d-0" # hisat2
    "docker://quay.io/biocontainers/htseq:0.12.4--py37h0498b6d_2" # htseq count
    "docker://quay.io/biocontainers/multiqc:1.9--pyh9f0ad1d_0" # multiqc
    "docker://quay.io/biocontainers/picard:2.23.2--0" # picard markduplicates
    "docker://quay.io/biocontainers/predex:0.9.2--pyh3252c3a_0" # predex annotation & predex design
    "docker://quay.io/biocontainers/biowdl-input-converter:0.2.1--py_0" # sampleConversion
    "docker://quay.io/biocontainers/star:2.7.5a--0" # star & starGenomeGenerate
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

