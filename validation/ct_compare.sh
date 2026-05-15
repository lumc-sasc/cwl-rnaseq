#!/bin/bash
# ===================================================================
# Script: compare_count_tables.sh
# Purpose:
#   Compare count table files between two workflow outputs:
#     - CWL workflow
#     - WDL workflow
#   Generates unified diff files for each sample in tmp/
#   Helps track differences between CWL and WDL pipelines.
#
# Directory structure assumed:
# tmp/
#   ├── markdup/
#   │     ├── CWL/
#   │     └── WDL/
#   ├── starAlign/
#   │     ├── CWL/
#   │     └── WDL/
#   └── umimarkdup/
#         ├── CWL/
#         └── WDL/
#
# Output:
#   tmp/diff_<subfolder>_<file>.txt - diff file for each count_table
# ===================================================================

set -euo pipefail  # exit on error, undefined variable, or pipe failure

# -----------------------
# Configuration
# -----------------------
BASE_DIR="tmp"

# List of subfolders to compare
SUBFOLDERS=("markdup" "starAlign" "umimarkdup")

# -----------------------
# Main Loop
# -----------------------
for sub in "${SUBFOLDERS[@]}"; do
    CWL_DIR="$BASE_DIR/$sub/CWL"
    WDL_DIR="$BASE_DIR/$sub/WDL"

    echo "=== Comparing $sub ==="

    # Ensure both CWL and WDL directories exist
    if [ ! -d "$CWL_DIR" ] || [ ! -d "$WDL_DIR" ]; then
        echo "Skipping $sub: missing CWL or WDL directory"
        continue
    fi

    # Compare all *.count_table.tsv files in CWL
    for file in "$CWL_DIR"/*.count_table.tsv; do
        # If no matching files, skip
        [ -f "$file" ] || continue

        base=$(basename "$file")
        wdl_file="$WDL_DIR/$base"

        if [ -f "$wdl_file" ]; then
            echo "Comparing $sub/$base..."
            # Write unified diff to tmp/
            diff -u "$file" "$wdl_file" > "$BASE_DIR/diff_${sub}_${base}.txt"

            if [ $? -eq 0 ]; then
                echo "No differences for $sub/$base"
            else
                echo "Differences saved to diff_${sub}_${base}.txt"
            fi
        else
            echo "File $base not found in WDL/$sub"
        fi
    done
done

# -----------------------
# Notes
# -----------------------
# - Make sure 'tmp/' is in .gitignore to avoid committing generated diff files.
# - The script only compares files that exist in both CWL and WDL.
# - Non-matching files in CWL or WDL are skipped and reported.
# - Output diff files can be viewed with 'less' or applied with 'patch'.