#!/bin/bash

set -euo pipefail

SUB_ID="${1:?Usage: bash 01_copy_files_for_app.sh <SUB_ID>}"

root="/mnt/f/MiguelWorkbench/01_preprocessing/01_fMRIprep"
T1w_DIR="${root}/${SUB_ID}/sub-${SUB_ID}/anat"

T1w_image_native="${T1w_DIR}/sub-${SUB_ID}_desc-preproc_T1w.nii.gz"
T1w_mask_native="${T1w_DIR}/sub-${SUB_ID}_desc-brain_mask.nii.gz"

dest_dir="/mnt/f/Miguel_apps/Check_SkullStrip-App/data_for_skullstrip/${SUB_ID}"
mkdir -p "${dest_dir}"

for f in "$T1w_image_native" "$T1w_mask_native"; do
    if [ ! -f "$f" ]; then
        echo "Missing file: $f"
        exit 1
    fi
done

cp --update=none "$T1w_image_native" "$dest_dir/"
cp --update=none "$T1w_mask_native" "$dest_dir/"