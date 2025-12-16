# Master script to run the entire analysis pipeline for the replication package.
#
# This script sources the individual analysis scripts from the R/ directory
# in the correct order.
#
# INSTRUCTIONS:
# 1. Set your R working directory to the root of the 'replication_package'.
# 2. Run this script using: source("run_all.R")

cat("=================================================================\n")
cat("=== RUNNING FULL REPLICATION PACKAGE PIPELINE ===\n")
cat("=================================================================\n\n")

# Ensure required directories exist
if (!dir.exists("output")) dir.create("output")
if (!dir.exists("figures")) dir.create("figures")

# Step 1: Calculate ideological positions for parliamentary groups
cat("--> STEP 1: Running '01_calculate_group_positions.R'\n")
tryCatch({
  source("R/01_calculate_group_positions.R")
  cat("--> STEP 1 COMPLETED SUCCESSFULLY.\n\n")
}, error = function(e) {
  stop("--> ERROR in script 01: ", e$message)
})

# Step 2: Run the main hypothesis test and modeling
cat("--> STEP 2: Running '02_hypothesis_analysis.R'\n")
tryCatch({
  source("R/02_hypothesis_analysis.R")
  cat("--> STEP 2 COMPLETED SUCCESSFULLY.\n\n")
}, error = function(e) {
  stop("--> ERROR in script 02: ", e$message)
})

# Step 3: Generate descriptive statistics and plots
cat("--> STEP 3: Running '03_descriptive_analysis.R'\n")
tryCatch({
  source("R/03_descriptive_analysis.R")
  cat("--> STEP 3 COMPLETED SUCCESSFULLY.\n\n")
}, error = function(e) {
  stop("--> ERROR in script 03: ", e$message)
})

cat("=================================================================\n")
cat("=== REPLICATION PIPELINE COMPLETED SUCCESSFULLY ===\n")
cat("=================================================================\n")
cat("All scripts have been executed. Please check the 'output' and 'figures' folders for the results.\n")
