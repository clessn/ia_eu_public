# ================================================================================
# 07_table3A_robustness.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Reproduces Online Appendix Table 3A: robustness checks replacing the binary
# post-ChatGPT indicator with continuous time, and adding country fixed
# effects (27 EU member states), alone and combined with the main
# specification.
#
# Input:  output/df_complete_h1.rds
# Output: output/table3A_robustness.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(MASS)
})
if (!dir.exists("output")) dir.create("output")

df_complete <- readRDS("output/df_complete_h1.rds")
df_complete$year_centered <- df_complete$year - mean(df_complete$year)

m_main <- polr(perception_ordered ~ weighted_position + weighted_eu_position + country_ai_attitude +
               post_chatgpt_factor + topic_digital_economy + topic_education + topic_social_impacts,
               data = df_complete, Hess = TRUE)

m_conttime <- polr(perception_ordered ~ weighted_position + weighted_eu_position + country_ai_attitude +
                    year_centered + topic_digital_economy + topic_education + topic_social_impacts,
                    data = df_complete, Hess = TRUE)

m_countryfe <- polr(perception_ordered ~ weighted_position + weighted_eu_position + post_chatgpt_factor +
                     topic_digital_economy + topic_education + topic_social_impacts + speaker_country,
                     data = df_complete, Hess = TRUE)

m_both <- polr(perception_ordered ~ weighted_position + weighted_eu_position + year_centered +
               topic_digital_economy + topic_education + topic_social_impacts + speaker_country,
               data = df_complete, Hess = TRUE)

# Estimate, standard error and a two-sided p-value from the normal
# approximation, which is how the significance stars in the appendix table are
# assigned. Returning the p-value as well means the stars can be checked rather
# than taken on trust.
extract <- function(m, var) {
  ct <- coef(summary(m))
  if (!var %in% rownames(ct)) return(c(est = NA, se = NA, p = NA))
  c(est = round(ct[var, "Value"], 3),
    se = round(ct[var, "Std. Error"], 3),
    p = round(2 * pnorm(abs(ct[var, "t value"]), lower.tail = FALSE), 4))
}

blank <- c(est = NA, se = NA, p = NA)

# The National Context rows were estimated but never written out. They are
# absent from the two country fixed-effects models by construction, since
# country attitude is collinear with the country dummies.
table3A <- rbind(
  weighted_position = c(extract(m_main, "weighted_position"), extract(m_conttime, "weighted_position"),
                         extract(m_countryfe, "weighted_position"), extract(m_both, "weighted_position")),
  weighted_eu_position = c(extract(m_main, "weighted_eu_position"), extract(m_conttime, "weighted_eu_position"),
                            extract(m_countryfe, "weighted_eu_position"), extract(m_both, "weighted_eu_position")),
  post_chatgpt = c(extract(m_main, "post_chatgpt_factorPost-ChatGPT"), blank,
                    extract(m_countryfe, "post_chatgpt_factorPost-ChatGPT"), blank),
  year_centered = c(blank, extract(m_conttime, "year_centered"),
                     blank, extract(m_both, "year_centered")),
  ai_optimistic = c(extract(m_main, "country_ai_attitudeAI-Optimistic Countries"),
                     extract(m_conttime, "country_ai_attitudeAI-Optimistic Countries"),
                     blank, blank),
  ai_pessimistic = c(extract(m_main, "country_ai_attitudeAI-Pessimistic Countries"),
                      extract(m_conttime, "country_ai_attitudeAI-Pessimistic Countries"),
                      blank, blank)
)
colnames(table3A) <- c("main_est", "main_se", "main_p",
                        "conttime_est", "conttime_se", "conttime_p",
                        "countryfe_est", "countryfe_se", "countryfe_p",
                        "both_est", "both_se", "both_p")

write.csv(table3A, "output/table3A_robustness.csv")
print(table3A)

aic_row <- c(main = round(AIC(m_main), 1), conttime = round(AIC(m_conttime), 1),
             countryfe = round(AIC(m_countryfe), 1), both = round(AIC(m_both), 1))
cat("\nAIC by specification:\n"); print(aic_row)

saveRDS(list(main = m_main, conttime = m_conttime, countryfe = m_countryfe, both = m_both),
        "output/robustness_models.rds")
