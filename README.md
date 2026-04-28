# Skull-Stripping QC Tool

Interactive quality control viewer for fMRIPrep skull-stripping outputs using native-space T1w images and brain masks.

## Overview

This toolkit extracts native T1w and brain mask files from fMRIPrep derivatives, optionally subsamples them for faster loading, and launches an interactive Shiny app for visual QC overlays.

**What it does:**
- ✅ Copies native T1w and brain mask files from fMRIPrep output
- ✅ Subsamples images to 2mm resolution (optional, for performance)
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
