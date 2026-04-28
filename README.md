# Skull-Stripping QC Tool

Interactive quality control viewer for fMRIPrep skull-stripping outputs using native-space T1w images and brain masks.

## Overview

This toolkit extracts native T1w and brain mask files from fMRIPrep derivatives, optionally subsamples them for faster loading, and launches an interactive Shiny app for visual QC overlays.

**What it does:**
- ✅ Copies native T1w and brain mask files from fMRIPrep output
- ✅ Subsamples: Downsamples images by 2x, in this case from 0.5mm to 1.0mm resolution (optional, for performance)
- ✅ Launches interactive viewer with adjustable mask overlay
- ✅ Supports exclusion list for known problematic subjects

---

## Prerequisites

### Software
- **Bash** shell (Linux, macOS, or WSL)
- **FSL** (`fslmaths` command must be available)
- **R** (≥ 4.0)
- **R packages:**
  ```r
  install.packages(c("shiny", "tidyverse", "papayaWidget"))
---

# Why Subsample Images for QC?

## Performance Benefits

### Speed
- **Native files:** 150-250 MB → 8-12 seconds to load
- **Subsampled files:** 10-20 MB → <1 second to load
- **Result:** 10-15x faster loading in browser

### Memory
- **Native:** ~180 MB per subject in browser RAM
- **Subsampled:** ~15 MB per subject
- **Result:** Review 50+ subjects without browser crashes

### Workflow
- Review 50 subjects in **~12 minutes** vs **~40 minutes**
- Smooth scrolling through slices
- No waiting between subjects

---

## Quality Control Perspective

### ✅ Sufficient for Skull-Stripping QC
You're checking for **gross errors** that are visible at 2mm resolution:
- Brain tissue incorrectly removed
- Skull/dura included in mask
- Complete processing failures
- Major motion artifacts

You're **NOT** doing:
- Fine anatomical measurements
- Lesion detection
- Precise boundary analysis

---

## Best Practice Workflow

1. **Quick pass** with subsampled files (50 subjects in 10 min)
2. **Flag suspicious cases**
3. **Check native resolution** only for flagged subjects

This gives you:
- Speed for routine QC
- Detail when needed
- No compromise on quality

---
## When NOT to Subsample

Skip subsampling if:
- < 10 subjects (loading time acceptable)
- Need to inspect fine anatomical detail
- Native files already small (e.g., 2mm acquisition)
- Very fast local storage (NVMe SSD)

---

## Bottom Line

**Subsampling for QC is like using thumbnails before opening full-resolution photos.**

