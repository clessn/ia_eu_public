# ================================================================================
# validate.R
#
# Automated check: does every number this pipeline produces match the number
# reported in the article? Run AFTER code/00_run_all.R
# from the replication_package/ root directory:
#
#   Rscript code/00_run_all.R
#   Rscript validation/validate.R
#
# Prints PASS/FAIL for each assertion and exits with status 1 if anything
# fails.
# ================================================================================

results <- list()
check <- function(label, actual, expected, tol = 1e-6) {
  ok <- isTRUE(all.equal(actual, expected, tolerance = tol))
  results[[label]] <<- ok
  cat(sprintf("[%s] %s : actual=%s expected=%s\n",
              ifelse(ok, "PASS", "FAIL"), label, format(actual), format(expected)))
}

## -- Table 1: group distribution --------------------------------------------
t1 <- read.csv("output/table1_group_distribution.csv", stringsAsFactors = FALSE)
t1 <- t1[order(-t1$interventions), ]
check("Table 1 - EPP N", t1$interventions[t1$Group == "EPP"], 167)
check("Table 1 - S&D N", t1$interventions[t1$Group == "S&D"], 141)
check("Table 1 - Renew N", t1$interventions[t1$Group == "Renew"], 81)
check("Table 1 - ECR N", t1$interventions[t1$Group == "ECR"], 50)
check("Table 1 - Greens/EFA N", t1$interventions[t1$Group == "Greens/EFA"], 42)
check("Table 1 - NI N", t1$interventions[t1$Group == "NI"], 42)
check("Table 1 - GUE/NGL N", t1$interventions[t1$Group == "GUE/NGL"], 32)
check("Table 1 - ID N", t1$interventions[t1$Group == "ID"], 27)
check("Table 1 - Patriots N", t1$interventions[t1$Group == "Patriots"], 3)

## -- Table 2: topic distribution ---------------------------------------------
t2 <- read.csv("output/table2_topic_distribution_totals.csv", stringsAsFactors = FALSE)
row <- function(label) t2$n[t2$topic_label == label]
check("Table 2 - Ethics & Regulation", row("Ethics & Regulation"), 243)
check("Table 2 - Public Services", row("Public Services"), 85)
check("Table 2 - Digital Economy", row("Digital Economy"), 79)
check("Table 2 - Digital Sovereignty", row("Digital Sovereignty"), 56)
check("Table 2 - Social Impacts", row("Social Impacts"), 54)
check("Table 2 - Education", row("Education"), 46)
check("Table 2 - Environment", row("Environment"), 12)
check("Table 2 - Other", row("Other"), 12)

## -- Table 3 / Table 1A: Model 5 (ordinal) -----------------------------------
t3 <- read.csv("output/table3_model5_ordinal.csv", stringsAsFactors = FALSE)
coef_val <- function(term) t3$estimate[t3$term == term]
check("Table 3 - Political Position beta", coef_val("weighted_position"), 0.265, tol = 0.001)
check("Table 3 - EU Integration beta", coef_val("weighted_eu_position"), 0.272, tol = 0.001)
check("Table 3 - AI-Optimistic Countries", coef_val("country_ai_attitudeAI-Optimistic Countries"), 0.512, tol = 0.001)
check("Table 3 - AI-Pessimistic Countries", coef_val("country_ai_attitudeAI-Pessimistic Countries"), -0.106, tol = 0.001)
check("Table 3 - Post-ChatGPT beta", coef_val("post_chatgpt_factorPost-ChatGPT"), -0.633, tol = 0.001)
check("Table 3 - Digital Economy topic", coef_val("topic_digital_economy"), 1.412, tol = 0.001)

t1A <- read.csv("output/table1A_nested_ordinal_models.csv", stringsAsFactors = FALSE)
check("Table 1A - Model 1 AIC", t1A$AIC[1], 930.6, tol = 0.05)
check("Table 1A - Model 2 AIC", t1A$AIC[2], 918.9, tol = 0.05)
check("Table 1A - Model 3 AIC", t1A$AIC[3], 919.6, tol = 0.05)
check("Table 1A - Model 4 AIC", t1A$AIC[4], 907.9, tol = 0.05)
check("Table 1A - Model 5 AIC", t1A$AIC[5], 892.9, tol = 0.05)
check("Table 1A - Model 5 BIC", t1A$BIC[5], 933.5, tol = 0.05)

brant <- read.csv("output/brant_test_model5.csv", stringsAsFactors = FALSE, row.names = 1)
check("Brant omnibus X2", round(brant["Omnibus", "X2"], 2), 15.53, tol = 0.01)
check("Brant omnibus p (rounded)", round(brant["Omnibus", "probability"], 2), 0.05, tol = 0.001)
check("Brant political position p", round(brant["weighted_position", "probability"], 2), 0.71, tol = 0.01)
check("Brant EU integration p", round(brant["weighted_eu_position", "probability"], 2), 0.26, tol = 0.01)
check("Brant social impacts p", round(brant["topic_social_impacts", "probability"], 3), 0.003, tol = 0.001)

## -- Table 2A: multinomial ----------------------------------------------------
t2A <- read.csv("output/table2A_multinomial.csv", row.names = 1)
check("Table 2A - Mixed weighted_position", t2A["weighted_position", "Mixed_est"], 0.173, tol = 0.001)
check("Table 2A - Optimist weighted_position", t2A["weighted_position", "Optimist_est"], 0.379, tol = 0.001)
check("Table 2A - Optimist EU integration", t2A["weighted_eu_position", "Optimist_est"], 0.395, tol = 0.001)
check("Table 2A - Optimist Post-ChatGPT", t2A["post_chatgpt_factorPost-ChatGPT", "Optimist_est"], -0.924, tol = 0.001)
check("Table 2A - Optimist Digital Economy", t2A["topic_digital_economy", "Optimist_est"], 1.495, tol = 0.001)

## -- Table 3A: robustness ------------------------------------------------------
t3A <- read.csv("output/table3A_robustness.csv", row.names = 1)
check("Table 3A - continuous time year coef", t3A["year_centered", "conttime_est"], -0.160, tol = 0.001)
check("Table 3A - country FE position", t3A["weighted_position", "countryfe_est"], 0.295, tol = 0.001)
check("Table 3A - country FE EU integration", t3A["weighted_eu_position", "countryfe_est"], 0.275, tol = 0.001)

## -- Table 4: H2 regulation crosstab --------------------------------------------
t4 <- read.csv("output/table4_regulation_crosstab.csv", stringsAsFactors = FALSE)
tot_row <- function(col, val) t4[[col]][t4$Perception.IA == val]
check("Table 4 - Mixed total", tot_row("total", "Mixed"), 86)
check("Table 4 - Optimist total", tot_row("total", "Optimist"), 67)
check("Table 4 - Pessimist total", tot_row("total", "Pessimist"), 71)
check("Table 4 - overall pro-regulation N", sum(t4$in_favor), 214)

## -- Table 4A: dictionary coverage ----------------------------------------------
t4A <- read.csv("output/table4A_dictionary_coverage.csv", stringsAsFactors = FALSE)
dict_val <- function(term) t4A$interventions_matched[t4A$term == term]
check("Table 4A - artificial intelligence", dict_val("artificial intelligence"), 617)
check("Table 4A - algorithm", dict_val("algorithm"), 139)
check("Table 4A - chatgpt", dict_val("chatgpt"), 19)
check("Table 4A - machine learning", dict_val("machine learning"), 11)

## -- Figure 1A: frame shift spot checks -----------------------------------------
f1A <- read.csv("output/figure1A_frames_by_group_period.csv", stringsAsFactors = FALSE)
epp_pre <- f1A$pct_optimist[f1A$group_label == "EPP" & f1A$post_chatgpt_factor == "Pre-ChatGPT"]
greens_pre <- f1A$pct_optimist[f1A$group_label == "Greens/EFA" & f1A$post_chatgpt_factor == "Pre-ChatGPT"]
check("Figure 1A - EPP pre-ChatGPT optimistic %", round(epp_pre), 61)
check("Figure 1A - Greens/EFA pre-ChatGPT optimistic %", round(greens_pre), 7)

## -- Figure 1: 2021 peak vs post-ChatGPT peak -----------------------------------
temporal <- read.csv("data/temporal_analysis_ia_vs_total.csv", stringsAsFactors = FALSE)
temporal$year_month <- as.Date(temporal$year_month)
peak_2021 <- max(temporal$proportion_ia[format(temporal$year_month, "%Y") == "2021"])
peak_post <- max(temporal$proportion_ia[temporal$year_month >= as.Date("2022-12-01")])
check("Figure 1 - 2021 peak exceeds post-ChatGPT peak", peak_2021 > peak_post, TRUE)

## -- Summary --------------------------------------------------------------------
n_pass <- sum(unlist(results))
n_total <- length(results)
cat(sprintf("\n%d / %d checks passed.\n", n_pass, n_total))
if (n_pass < n_total) {
  cat("FAILED checks:\n")
  print(names(results)[!unlist(results)])
  quit(status = 1)
} else {
  cat("ALL CHECKS PASSED.\n")
}
