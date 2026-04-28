#!/bin/bash

# Usage
#   bash subsample_all_parallel_native.sh
#
# Description
#   For each subject in sub_list.txt
#     - Finds native T1w and brain mask files
#     - Creates subsampled 1mm versions
#     - Does NOT overwrite originals
#     - Skips if already processed
#   Runs 5 subjects in parallel

SUB_LIST="sub_list.txt"
DATA_DIR="/mnt/f/Miguel_apps/Check_SkullStrip-App/data_for_skullstrip"
N_JOBS=5

process_subject() {

    SUB_ID="$1"
    SUBJ_DIR="${DATA_DIR}/${SUB_ID}"

    if [ ! -d "$SUBJ_DIR" ]; then
        echo "⚠ Skipping $SUB_ID — directory not found"
        return
    fi

    # Find native files (exclude space-* variants)
    T1w_file=$(find "$SUBJ_DIR" -type f \
        -name "sub-${SUB_ID}_desc-preproc_T1w.nii.gz" \
        ! -name "space-*" | head -n 1)

    mask_file=$(find "$SUBJ_DIR" -type f \
        -name "sub-${SUB_ID}_desc-brain_mask.nii.gz" \
        ! -name "space-*" | head -n 1)

    if [ -z "$T1w_file" ] || [ -z "$mask_file" ]; then
        echo "⚠ Skipping $SUB_ID — native files not found"
        return
    fi

    # Define output filenames
    T1w_out="${T1w_file%.nii.gz}_subsamp2.nii.gz"
    mask_out="${mask_file%.nii.gz}_subsamp2.nii.gz"

    # Check each file individually
    processed=0
    
    if [ -f "$T1w_out" ]; then
        echo "→ $SUB_ID: T1w already subsampled, skipping"
    else
        echo "→ $SUB_ID: Subsampling T1w..."
        fslmaths "$T1w_file" -subsamp2 "$T1w_out"
        processed=1
    fi

    if [ -f "$mask_out" ]; then
        echo "→ $SUB_ID: Mask already subsampled, skipping"
    else
        echo "→ $SUB_ID: Subsampling mask..."
        fslmaths "$mask_file" -subsamp2 "$mask_out"
        processed=1
    fi

    if [ $processed -eq 1 ]; then
        echo "✓ $SUB_ID done"
    fi
}

export -f process_subject
export DATA_DIR

echo "Subsampling native T1w files (parallel, ${N_JOBS} jobs)..."
echo

cat "$SUB_LIST" | xargs -P "$N_JOBS" -I {} bash -c 'process_subject "$@"' _ {}

echo
echo "All subjects processed!"
