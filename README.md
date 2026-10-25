# ECO346 Assignment 1 --- Data Visualization Techniques for Economists

**University:** COMSATS University Islamabad, Lahore Campus\
**Semester:** Fall 2026\
**Course:** ECO346 --- Data Visualization Techniques for Economists\
**Section:** B\
**Variant:** 2 --- Rural Sindh

## Overview

This repository contains the scripts, figures, tables, and presentation
for Assignment 1. The analysis uses the provided PSLM person and
household subset data to examine education spending and literacy
patterns for the assigned population.

## Study Population

The assigned population is **rural Sindh**.

-   `prov_code == 3`: Sindh
-   `urban_rural == 1`: Rural
-   Literacy analysis includes people aged 10--64 with non-missing
    literacy status.
-   Education-spending analysis includes observations where
    `ed_total > 0`.
-   Household weights (`hhweight`) are used for weighted statistics.

Person-level data are linked to household-level information using `hhid`
to attach the household weight, province code, and urban/rural
indicator.

## Repository Structure

``` text
ECO346-A1-<REG-NO>/
├── README.md
├── data/
│   ├── pslm_person_subset.csv
│   └── pslm_hh_subset.csv
├── scripts/
│   ├── 01_default.R
│   ├── 02_distribution.R
│   ├── 03_literacy.R
│   └── 04_second_language.py
├── figures/
│   ├── default.svg
│   ├── distribution.svg
│   ├── literacy_by_age.svg
│   └── literacy_by_age_python.svg
├── tables/
│   ├── band_table_R.csv
│   └── band_table_python.csv
└── slides/
    └── <REG-NO>.pptx
```

Replace `<REG-NO>` with your registration number and make sure the
folder and filenames match the actual repository.

## Assignment Tasks

### Question 2 --- Education Spending Distribution

The script `scripts/02_distribution.R` produces a weighted histogram of
total education spending (`ed_total`) for the assigned population.

The analysis reports: - Number of observations in the education-spending
sample - Weighted and unweighted medians - Weighted 10th and 90th
percentiles - Ratio of the weighted 90th percentile to the weighted 10th
percentile - Number of observations outside the histogram's displayed
range

The histogram uses a logarithmic x-axis and marks the weighted median
and 90th percentile.

### Question 3 --- Literacy by Age Group and Sex

The script `scripts/03_literacy.R` calculates weighted literacy rates
for five-year age groups and sex. The analysis covers ages 10--64 and
uses household weights.

Age groups run from 10--14 through 60--64. Groups with fewer than 30
unweighted observations are marked as thin cells. The script saves a
table and a redesigned SVG figure.

### Question 4 --- Default Figure and Redesign

The script `scripts/01_default.R` creates the default scatterplot of age
and literacy status and saves it as `figures/default.svg`.

The default figure is retained for comparison with the redesigned
literacy-by-age figure.

### Question 5 --- Second-Language Reproduction

The script `scripts/04_second_language.py` reproduces the
literacy-by-age table and figure in Python. The Python output is
compared with the R output to check whether the weighted rates agree to
one decimal place.

## Results

Fill in this section with the values produced by your scripts before
submitting.

### Question 2

-   Education-spending sample size: **\[enter result\]**
-   Weighted median: **\[enter result\]**
-   Unweighted median: **\[enter result\]**
-   Weighted 10th percentile: **\[enter result\]**
-   Weighted 90th percentile: **\[enter result\]**
-   Weighted p90/p10 ratio: **\[enter result\]**
-   Observations excluded from the displayed histogram range: **\[enter
    result\]**

### Question 3

-   Women's literacy rate, ages 15--19: **\[enter result\]%**
-   Men's literacy rate, ages 15--19: **\[enter result\]%**
-   Women's literacy rate, ages 55--59: **\[enter result\]%**
-   Men's literacy rate, ages 55--59: **\[enter result\]%**
-   Age group with the largest literacy-rate gap: **\[enter age group
    and gap\]**

### Question 5

-   Women's literacy rate, ages 15--19, from R: **\[enter result\]%**
-   Women's literacy rate, ages 15--19, from Python: **\[enter
    result\]%**
-   Do the R and Python tables agree to one decimal place? **\[enter
    result\]**

## Methodology

### Weighted literacy rate

For each age group and sex, the weighted literacy rate is calculated as:

\[ `\text{Weighted literacy rate}`{=tex} =
`\frac{\sum_i w_i \cdot \text{literate}_i}{\sum_i w_i}`{=tex} \]

where (w_i) is the household weight and `literate` is the literacy
indicator.

### Weighted quantiles

Weighted quantiles are calculated by sorting observations by the
variable of interest and finding the smallest value at which the
cumulative share of the total weight reaches or exceeds the requested
percentile.

## Running the Scripts

Run the commands from the repository root so that relative paths to
`data/`, `figures/`, and `tables/` resolve correctly.

### R scripts

``` bash
Rscript scripts/01_default.R
Rscript scripts/02_distribution.R
Rscript scripts/03_literacy.R
```

### Python script

Install the required Python packages if needed, then run:

``` bash
python scripts/04_second_language.py
```

The scripts expect the input CSV files to be present in `data/`. Keep
the directory structure consistent with the paths used in the scripts.

## Requirements

-   R
-   R packages: `ggplot2`, `svglite`, and any additional packages
    imported by the scripts
-   Python 3
-   Python packages imported by `04_second_language.py`, including
    `pandas`, `numpy`, and `matplotlib` if used by the script

## Reproducibility Notes

-   Keep the supplied data files in the `data/` directory.
-   Run scripts from the repository root.
-   SVG figures are saved in `figures/`.
-   Generated tables are saved in `tables/`.
-   Replace all `[enter result]` placeholders with actual outputs.
-   Confirm that all listed files exist and that the registration number
    in the repository and presentation filename is correct.
