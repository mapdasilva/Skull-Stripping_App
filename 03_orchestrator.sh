#!/bin/bash
# Orchestrator script - each script handles its own parallelism

echo "Step 1: Copying files..."
cat sub_list.txt | xargs -P 5 -I {} bash 01_copy_files_for_app.sh {}

echo "Step 2: Subsampling..."
bash 02_subsample.sh  # Don't use xargs - it already handles all subjects

echo "All done!"