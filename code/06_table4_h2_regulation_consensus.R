# ================================================================================
# 06_table4_h2_regulation_consensus.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
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

# The logical flag is named favors_regulation rather than in_favor. summarise()
# evaluates its arguments in order and each one sees the columns created before
# it, so `in_favor = sum(in_favor)` would rebind the name to a scalar count and
# the following `sum(!in_favor)` would negate that count instead of the flag,
# returning zero for every group.
table4 <- df_h2 %>%
  mutate(favors_regulation = Perception.regulation == "In favor") %>%
  group_by(Perception.IA) %>%
  summarise(
    in_favor = sum(favors_regulation),
    against_or_ambiguous = sum(!favors_regulation),
    total = n(),
    pct_pro_reg = round(100 * mean(favors_regulation), 1),
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
