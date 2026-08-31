# ================================================================================
# 04_models_h1_ordinal_and_multinomial.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Estimates the five nested ordinal logistic regression models testing
# Hypotheses 1 and 1b, tests the proportional odds assumption (Brant test),
# and estimates the multinomial robustness check.
#
# Reproduces:
#   - Table 3 (main text): Model 5, the final ordinal specification
#   - Online Appendix Table 1A: all five nested models + Brant test
#   - Online Appendix Table 2A: multinomial logistic regression (robustness)
#
# Input:  output/df_complete_h1.rds (produced by 01_build_analysis_dataset.R)
# Output: output/table3_model5_ordinal.csv
#         output/table1A_nested_ordinal_models.csv
#         output/table2A_multinomial.csv
#         output/brant_test_model5.csv
#         output/model5_ordinal.rds, output/model5_multinomial.rds
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(MASS); library(nnet); library(brant)
})
if (!dir.exists("output")) dir.create("output")

df_complete <- readRDS("output/df_complete_h1.rds")

# The corpus carries a `term` column (the parliamentary term, 8 to 10) that no
# model here uses. marginaleffects builds its own `term` column internally, and
# on some versions the collision makes predictions() fail downstream in
# 05_figure4_predicted_probabilities.R. Dropping it keeps the data frame that
# script reads unambiguous.
df_complete$term <- NULL

model1 <- polr(perception_ordered ~ weighted_position, data = df_complete, Hess = TRUE)
model2 <- polr(perception_ordered ~ weighted_position + weighted_eu_position, data = df_complete, Hess = TRUE)
model3 <- polr(perception_ordered ~ weighted_position + weighted_eu_position + country_ai_attitude,
                data = df_complete, Hess = TRUE)
model4 <- polr(perception_ordered ~ weighted_position + weighted_eu_position + country_ai_attitude +
                post_chatgpt_factor, data = df_complete, Hess = TRUE)
model5 <- polr(perception_ordered ~ weighted_position + weighted_eu_position + country_ai_attitude +
                post_chatgpt_factor + topic_digital_economy + topic_education + topic_social_impacts,
                data = df_complete, Hess = TRUE)

models <- list(model1, model2, model3, model4, model5)
table1A <- data.frame(
  model = paste0("Model ", 1:5),
  N = sapply(models, function(m) nrow(df_complete)),
  AIC = round(sapply(models, AIC), 1),
  BIC = round(sapply(models, BIC), 1)
)
write.csv(table1A, "output/table1A_nested_ordinal_models.csv", row.names = FALSE)
print(table1A)

# --- Table 1A: the coefficients themselves, not just the fit statistics ---
# The appendix prints a coefficient for every predictor in each of the five
# nested models. Reproducing the AIC and BIC alone leaves the body of that
# table unchecked, so the estimates, standard errors and p-values are written
# out here in long form, one row per model and term.
table1A_full_coefficients <- do.call(rbind, lapply(seq_along(models), function(i) {
  ct <- coef(summary(models[[i]]))
  data.frame(
    model = paste0("Model ", i),
    term = rownames(ct),
    estimate = round(ct[, "Value"], 3),
    std_error = round(ct[, "Std. Error"], 3),
    t_value = round(ct[, "t value"], 3),
    p_value = round(2 * pnorm(abs(ct[, "t value"]), lower.tail = FALSE), 4),
    row.names = NULL
  )
}))
write.csv(table1A_full_coefficients,
          "output/table1A_full_coefficients.csv", row.names = FALSE)
cat("\nTable 1A, full coefficients:\n")
print(table1A_full_coefficients)

# --- Proportional odds assumption (Brant test on the full specification) ---
brant5 <- brant(model5)
brant_df <- as.data.frame(brant5)
# Written at six significant digits. The full double precision R carries
# here varies in its last digits with the BLAS the machine happens to use,
# which makes the committed outputs impossible to compare byte for byte
# across platforms. Six digits is far beyond anything the article reports.
brant_df[] <- lapply(brant_df, function(x) if (is.numeric(x)) signif(x, 6) else x)
write.csv(brant_df, "output/brant_test_model5.csv")
print(brant_df)

omnibus_p <- brant_df["Omnibus", "probability"]
cat(sprintf("\nBrant omnibus test: p = %.4f\n", omnibus_p))

# --- Model selection: ordinal is retained as primary, per the manuscript's
# explicit methodological argument (Section 3.4). The omnibus test is
# borderline (p ~ 0.05), but both predictors of theoretical interest,
# political position and EU integration position, individually satisfy the
# proportional-odds assumption by a wide margin (p = 0.71 and p = 0.26). Only
# one thematic control variable (Social Impacts) violates it. The manuscript
# therefore retains the ordinal specification for the primary analysis and
# reports the multinomial model as an appendix robustness check.
#
# This decision is fixed here rather than made automatically from the
# omnibus p-value at runtime: because that p-value sits right at the 0.05
# threshold (0.0497 with this exact sample), a naive `if (p < 0.05)` switch
# is not a stable way to select the model that the paper actually reports,
# and toggles the reported Figure 4 between two different plots depending on
# floating-point noise. See replication_package/README.md for details.
cat("\nModel selection: ORDINAL retained as primary (per manuscript Section 3.4).\n")

table3 <- data.frame(
  term = names(coef(model5)),
  estimate = round(coef(model5), 3),
  se = round(sqrt(diag(vcov(model5)))[names(coef(model5))], 3)
)
table3$p_value <- 2 * pnorm(-abs(coef(model5) / sqrt(diag(vcov(model5)))[names(coef(model5))]))
table3$p_value <- signif(table3$p_value, 6)
write.csv(table3, "output/table3_model5_ordinal.csv", row.names = FALSE)
cat("\nTable 3 (Model 5, ordinal):\n"); print(table3)
cat(sprintf("AIC = %.1f, BIC = %.1f, N = %d\n", AIC(model5), BIC(model5), nrow(df_complete)))

saveRDS(model5, "output/model5_ordinal.rds")

# --- Multinomial robustness check (Online Appendix Table 2A) ---
df_complete$perception_unordered <- factor(df_complete$perception_ordered,
                                            levels = c("Pessimist", "Mixed", "Optimist"), ordered = FALSE)
model_multinomial <- multinom(
  perception_unordered ~ weighted_position + weighted_eu_position + country_ai_attitude +
    post_chatgpt_factor + topic_digital_economy + topic_education + topic_social_impacts,
  data = df_complete, trace = FALSE
)
sf <- summary(model_multinomial)
z <- sf$coefficients / sf$standard.errors
p <- 2 * (1 - pnorm(abs(z)))
table2A <- as.data.frame(t(rbind(
  Mixed_est = round(sf$coefficients["Mixed", ], 3),
  Mixed_se = round(sf$standard.errors["Mixed", ], 3),
  Mixed_p = round(p["Mixed", ], 4),
  Optimist_est = round(sf$coefficients["Optimist", ], 3),
  Optimist_se = round(sf$standard.errors["Optimist", ], 3),
  Optimist_p = round(p["Optimist", ], 4)
)))
write.csv(table2A, "output/table2A_multinomial.csv")
cat("\nTable 2A (multinomial):\n"); print(table2A)
cat(sprintf("AIC = %.1f, Residual deviance = %.1f\n", AIC(model_multinomial), model_multinomial$deviance))

saveRDS(model_multinomial, "output/model5_multinomial.rds")
