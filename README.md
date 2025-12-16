# Replication Package: Partisan Affiliation and AI Perception in the EP

This repository contains the data and code necessary to reproduce the analysis for the article on parliamentary discourses on Artificial Intelligence.

The analysis investigates how the political orientation of Members of the European Parliament (MEPs) influences their perception of AI.

## System Requirements

- **R**: Version 4.0.0 or higher.
- **R Packages**: The analysis requires several R packages. You can install them by running the following command in R:
  ```R
  install.packages("pacman")
  pacman::p_load(dplyr, readr, stringr, ggplot2, forcats, xml2, httr, jsonlite, scales, nnet, brant, tidyr, knitr, modelsummary)
  ```

## Directory Structure

- `data/`: Contains the raw and necessary pre-processed data files.
  - `ai_categorized_paragraphs.csv`: The primary dataset of categorized EP interventions.
  - `xml_parties_successful_mappings.csv`: A pre-computed mapping of EP national parties to Chapel Hill Expert Survey (CHES) party IDs.
  - `chapel_hill/`: Contains the raw CHES data files.
- `R/`: Contains the R scripts for the analysis, which should be run in numerical order.
- `output/`: This directory will be created by the scripts and will contain all generated data tables and model summaries.
- `figures/`: This directory will be created by the scripts and will contain all generated plots and figures.

## Instructions for Reproduction

To reproduce the analysis, please follow these steps:

1.  **Set Working Directory**: Open R or RStudio and set your working directory to the root of this `replication_package` folder.
    ```R
    # Example:
    # setwd("path/to/your/folder/replication_package")
    ```

2.  **Run the Analysis**: You can either run the master script or run each script individually in order.

    **Option A: Run Master Script (Recommended)**
    
    The `run_all.R` script will execute the entire analysis pipeline from start to finish.
    ```R
    source("run_all.R")
    ```

    **Option B: Run Individual Scripts**
    
    If you prefer to run each step manually, execute the scripts in the `R/` folder in the following order:
    ```R
    source("R/01_calculate_group_positions.R")
    source("R/02_hypothesis_analysis.R")
    source("R/03_descriptive_analysis.R")
    ```

## Expected Output

After running the scripts, the `output/` and `figures/` directories will be populated with the results of the analysis, including:
- CSV files with summary statistics.
- A detailed model summary and `.rds` object for the final regression model.
- PNG files for all figures, including the predicted probability plot, coefficient plot, and descriptive visualizations.
