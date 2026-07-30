# ================================================================================
# 00_run_all.R
#
# Runs the full replication pipeline in order. Run from the
# replication_package/ root directory:
#
#   Rscript code/00_run_all.R
#
# Each step writes its outputs to output/ and prints the key numbers it
# reproduces so they can be checked against the manuscript by eye. Run
# validation/validate.R afterward for an automated pass/fail check against
# every number in the paper.
# ================================================================================

scripts <- c(
  "code/01_build_analysis_dataset.R",
  "code/02_table1_group_distribution.R",
  "code/03_table2_topic_distribution.R",
  "code/04_models_h1_ordinal_and_multinomial.R",
  "code/05_figure4_predicted_probabilities.R",
  "code/06_table4_h2_regulation_consensus.R",
  "code/07_table3A_robustness.R",
  "code/08_table4A_dictionary_coverage.R",
  "code/09_figure1A_frames_by_group_period.R",
  "code/10_figure1_temporal_volume.R"
)

for (s in scripts) {
  cat("\n", strrep("=", 80), "\n", sep = "")
  cat("Running:", s, "\n")
  cat(strrep("=", 80), "\n")
  source(s, echo = FALSE)
}

cat("\n\nAll scripts completed. Run validation/validate.R to check outputs against the manuscript.\n")
