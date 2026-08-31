[![DOI](https://img.shields.io/badge/DOI-10.17632%2F35zy6p92f6.1-blue)](https://doi.org/10.17632/35zy6p92f6.1)

# maternal-infant-covid-antibodies

Reproducible R analysis for the manuscript:

**Placental transfer dynamics and durability of maternal COVID-19 vaccine-induced antibodies in infants** (Lopez et al., 2024)

## Overview

This repository contains the preprocessing, statistical analysis, and
figure-generation code used to study:

- Maternal-to-infant transfer of COVID-19 vaccine-induced antibodies
- Persistence of IgG subclasses and Fc-receptor binding through 12 months
- Responses to wild-type SARS-CoV-2 and variants of concern
- Effects of maternal vaccination timing on infant antibody profiles
- Multivariate antibody profiles using UMAP, repeated LASSO, and PLSDA

The notebooks are organized by manuscript figure. Each folder begins with a
numbered data-loading notebook, followed by the analyses in the order they
should be run.

## Repository Structure

```text
maternal-infant-covid-antibodies/
│
├── PRE_PROCESSING/
│   ├── 01_import_and_clean_data.Rmd
│   └── 02_prepare_analysis_objects.Rmd
│
├── Figure_1/
│   ├── 01_load_data.Rmd
│   └── 02_antibody_persistence.Rmd
│
├── Figure_2/
│   ├── 01_load_data.Rmd
│   ├── 02_variant_heatmap.Rmd
│   └── 03_omicron_comparison.Rmd
│
├── Figure_3/
│   ├── 01_load_data.Rmd
│   ├── 02_vaccine_timing_groups.Rmd
│   ├── 03_plsda_model.Rmd
│   └── 04_univariate_features.Rmd
│
├── Figure_4/
│   ├── 01_load_data.Rmd
│   ├── 02_polar_profiles.Rmd
│   ├── 03_timing_correlations.Rmd
│   └── 04_correlation_heatmap.Rmd
│
├── Sup_Figs/
│   ├── 01_late_infant_persistence.Rmd
│   ├── 02_umap.Rmd
│   ├── 03_six_month_plsda.Rmd
│   └── 04_six_month_univariate.Rmd
│
├── helpful_functions/
│   ├── data_io.R
│   ├── data_preprocessing.R
│   ├── analysis_functions.R
│   └── plotting_functions.R
│
├── .gitignore
└── README.md
```

## Running the Analysis

### 1. Prepare the data

The participant-level study data are not stored in GitHub. If you have access
to the source workbooks, place them in `INPUT_VARIABLES/raw/`:

```text
INPUT_VARIABLES/raw/merck-data-pbs.xlsx
INPUT_VARIABLES/raw/meta_manifest_FINAL_v2.xlsx
```

Then run the two notebooks in `PRE_PROCESSING/` in numerical order. They create
the seven processed `.RData` files used by the figure analyses.

To keep data elsewhere, set either of these environment variables:

```r
Sys.setenv(COVID_ANTIBODY_RAW_DIR = "/path/to/raw/files")
Sys.setenv(COVID_ANTIBODY_INPUT_DIR = "/path/to/processed/files")
```

### 2. Reproduce a figure

For each figure folder:

1. Run every chunk in `01_load_data.Rmd`.
2. In the same R session, run the remaining notebooks in numerical order.
3. Find generated panels and result tables under `outputs/`.

Supplementary notebooks state which main-figure loading notebook must be run
first.

## Software

The analysis uses R 4.1 or later. Package imports are listed at the top of each
notebook. The multivariate notebooks also require the
[`systemsseRology`](https://github.com/LoosC/systemsseRology) package:

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("ropls")

install.packages("devtools")
devtools::install_github("LoosC/systemsseRology", ref = "reboot")
```

## Analytical Workflow

1. Subtract PBS background and log10-transform systems-serology measurements.
2. Define detection thresholds from negative controls.
3. Compare sample groups using Kruskal-Wallis, Dunn, Wilcoxon, and Spearman
   analyses with the manuscript-specified multiple-testing corrections.
4. Apply UMAP for unsupervised visualization.
5. Repeat LASSO feature selection 100 times and fit PLSDA models.
6. Validate multivariate models using 10-fold cross-validation and 100 label
   permutations.

## Data Availability

The original publication-associated code is archived in
[Mendeley Data](https://doi.org/10.17632/35zy6p92f6.1).

Participant-level data are available from the study team upon reasonable
request, as described in the publication.

## Citation

Lopez PA, Nziza N, Chen T, et al. Placental transfer dynamics and durability
of maternal COVID-19 vaccine-induced antibodies in infants. *iScience*.
2024;27(3):109273.
[https://doi.org/10.1016/j.isci.2024.109273](https://doi.org/10.1016/j.isci.2024.109273)

## Contact

For questions, please open a GitHub Issue or contact the corresponding author.
