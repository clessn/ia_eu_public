# ================================================================================
# 08_table4A_dictionary_coverage.R
#
# Reproduces Online Appendix Table 4A: number of AI-related interventions
# matched by each of the seven dictionary terms used for corpus construction.
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv (paragraphLower column
#         retains the lower-cased paragraph text used for dictionary matching)
# Output: output/table4A_dictionary_coverage.csv
# ================================================================================

suppressPackageStartupMessages(library(dplyr))
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)
cat(sprintf("N interventions: %d (expected 666)\n", nrow(df)))
if (nrow(df) != 666) stop("Corpus size mismatch: expected N = 666.")

terms <- c("machine learning", "artificial intelligence", "algorithm", "data mining",
           "machine intelligence", "deep learning", "chatgpt")

table4A <- data.frame(
  term = terms,
  interventions_matched = sapply(terms, function(t) sum(grepl(t, df$paragraphLower, fixed = TRUE), na.rm = TRUE))
)
table4A$pct_of_corpus <- round(100 * table4A$interventions_matched / nrow(df), 1)
table4A <- table4A[order(-table4A$interventions_matched), ]

write.csv(table4A, "output/table4A_dictionary_coverage.csv", row.names = FALSE)
print(table4A)
