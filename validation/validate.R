# ================================================================================
# validate.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
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
# The against/ambiguous counts and the percentages are checked as well. Before
# the column-name collision in 06 was fixed, every against_or_ambiguous came
# out as zero and every percentage as a hundred times too large, and none of
# the assertions above caught it.
check("Table 4 - Mixed against/ambiguous", tot_row("against_or_ambiguous", "Mixed"), 3)
check("Table 4 - Optimist against/ambiguous", tot_row("against_or_ambiguous", "Optimist"), 6)
check("Table 4 - Pessimist against/ambiguous", tot_row("against_or_ambiguous", "Pessimist"), 1)
check("Table 4 - Mixed % pro-regulation", tot_row("pct_pro_reg", "Mixed"), 96.5, tol = 0.05)
check("Table 4 - Optimist % pro-regulation", tot_row("pct_pro_reg", "Optimist"), 91.0, tol = 0.05)
check("Table 4 - Pessimist % pro-regulation", tot_row("pct_pro_reg", "Pessimist"), 98.6, tol = 0.05)

# The chi-square reported in the manuscript is recomputed here from the corpus
# rather than taken from the text, since an earlier draft carried a value the
# data no longer produced.
h2 <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)
h2 <- h2[h2$is_mep == TRUE & !is.na(h2$Perception.regulation) &
           h2$Perception.IA %in% c("Optimist", "Pessimist", "Mixed"), ]
cs <- suppressWarnings(chisq.test(table(h2$Perception.IA, h2$Perception.regulation == "In favor")))
check("Table 4 - chi-square statistic", round(as.numeric(cs$statistic), 2), 4.91, tol = 0.005)
check("Table 4 - chi-square df", as.numeric(cs$parameter), 2)
check("Table 4 - chi-square p", round(as.numeric(cs$p.value), 2), 0.09, tol = 0.005)

## -- Table 1A: full nested-model coefficients -----------------------------------
t1Af <- read.csv("output/table1A_full_coefficients.csv", stringsAsFactors = FALSE)
coef1A <- function(m, term) t1Af$estimate[t1Af$model == m & t1Af$term == term]
check("Table 1A - Model 1 position", coef1A("Model 1", "weighted_position"), 0.200, tol = 0.001)
check("Table 1A - Model 2 position", coef1A("Model 2", "weighted_position"), 0.288, tol = 0.001)
check("Table 1A - Model 3 position", coef1A("Model 3", "weighted_position"), 0.295, tol = 0.001)
check("Table 1A - Model 4 position", coef1A("Model 4", "weighted_position"), 0.302, tol = 0.001)
check("Table 1A - Model 5 position", coef1A("Model 5", "weighted_position"), 0.265, tol = 0.001)
check("Table 1A - Model 2 EU integration", coef1A("Model 2", "weighted_eu_position"), 0.267, tol = 0.001)
check("Table 1A - Model 4 post-ChatGPT", coef1A("Model 4", "post_chatgpt_factorPost-ChatGPT"), -0.701, tol = 0.001)

## -- Table 3A: national context rows --------------------------------------------
check("Table 3A - main AI-optimistic country", t3A["ai_optimistic", "main_est"], 0.512, tol = 0.001)
check("Table 3A - main AI-pessimistic country", t3A["ai_pessimistic", "main_est"], -0.106, tol = 0.001)
check("Table 3A - cont. time AI-optimistic country", t3A["ai_optimistic", "conttime_est"], 0.474, tol = 0.001)
check("Table 3A - cont. time AI-pessimistic country", t3A["ai_pessimistic", "conttime_est"], -0.130, tol = 0.001)

## -- Figure 2: distribution of framing stances ----------------------------------
f2 <- read.csv("output/figure2_perception_distribution.csv", stringsAsFactors = FALSE)
f2n <- function(lab) f2$interventions[f2$label == lab]
f2p <- function(lab) f2$pct[f2$label == lab]
check("Figure 2 - Pessimist N", f2n("Pessimist"), 136)
check("Figure 2 - Mixed/Realist N", f2n("Mixed/Realist"), 138)
check("Figure 2 - Optimist N", f2n("Optimist"), 155)
check("Figure 2 - Contextual N", f2n("Contextual"), 158)
check("Figure 2 - total N", sum(f2$interventions), 587)
check("Figure 2 - Optimist %", f2p("Optimist"), 26.4, tol = 0.05)
check("Figure 2 - Contextual %", f2p("Contextual"), 26.9, tol = 0.05)

## -- Figure 3: framing stance by parliamentary group ----------------------------
f3 <- read.csv("output/figure3_perceptions_by_group.csv", stringsAsFactors = FALSE)
f3v <- function(g, col) f3[[col]][f3$group_label == g]
check("Figure 3 - EPP optimistic %", f3v("EPP", "pct_optimist"), 52.7, tol = 0.05)
check("Figure 3 - Renew optimistic %", f3v("Renew", "pct_optimist"), 40.0, tol = 0.05)
check("Figure 3 - ID optimistic %", f3v("ID", "pct_optimist"), 37.5, tol = 0.05)
check("Figure 3 - Greens/EFA pessimistic %", f3v("Greens/EFA", "pct_pessimist"), 61.5, tol = 0.05)
check("Figure 3 - S&D pessimistic %", f3v("S&D", "pct_pessimist"), 43.7, tol = 0.05)
check("Figure 3 - ECR pessimistic %", f3v("ECR", "pct_pessimist"), 40.5, tol = 0.05)

## -- Figure 2A: annual counts by framing stance ---------------------------------
f2A <- read.csv("output/figure2A_temporal_perceptions.csv", stringsAsFactors = FALSE)
f2Av <- function(panel, yr) f2A$interventions[f2A$panel == panel & f2A$year == yr]
check("Figure 2A - Pessimist 2022", f2Av("Pessimist", 2022), 23)
check("Figure 2A - Pessimist 2024", f2Av("Pessimist", 2024), 35)
check("Figure 2A - Optimist 2022", f2Av("Optimist", 2022), 18)
check("Figure 2A - Optimist 2024", f2Av("Optimist", 2024), 13)
check("Figure 2A - total N", sum(f2A$interventions), 587)

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
