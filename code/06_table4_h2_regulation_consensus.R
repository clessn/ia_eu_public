# ================================================================================
# 06_table4_h2_regulation_consensus.R
#
# Reproduces Table 4 (AI Framing Stance and Regulatory Position Among MEPs)
# and the chi-square test of association reported for Hypothesis 2.
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/table4_regulation_crosstab.csv
# ================================================================================

suppressPackageStartupMessages(library(dplyr))
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)

df_h2 <- df %>%
  filter(is_mep == TRUE) %>%
  filter(!is.na(Perception.IA)) %>%
  filter(!is.na(Perception.regulation)) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed"))

cat(sprintf("N (H2 sample): %d (expected 224)\n", nrow(df_h2)))
if (nrow(df_h2) != 224) stop("H2 sample size mismatch: expected N = 224.")

table4 <- df_h2 %>%
  mutate(in_favor = Perception.regulation == "In favor") %>%
  group_by(Perception.IA) %>%
  summarise(
    in_favor = sum(in_favor),
    against_or_ambiguous = sum(!in_favor),
    total = n(),
    pct_pro_reg = round(100 * mean(in_favor), 1),
    .groups = "drop"
  ) %>%
  arrange(match(Perception.IA, c("Mixed", "Optimist", "Pessimist")))

write.csv(table4, "output/table4_regulation_crosstab.csv", row.names = FALSE)
print(table4)

ct <- table(df_h2$Perception.IA, df_h2$Perception.regulation == "In favor")
chisq <- chisq.test(ct)
cat(sprintf("\nChi-square test: X2 = %.2f, df = %d, p = %.2f\n",
            chisq$statistic, chisq$parameter, chisq$p.value))
cat(sprintf("Overall: %d in favor of %d total = %.1f%% pro-regulation\n",
            sum(table4$in_favor), sum(table4$total), 100 * sum(table4$in_favor) / sum(table4$total)))
