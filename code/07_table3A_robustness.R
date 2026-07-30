# ================================================================================
# 07_table3A_robustness.R
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

extract <- function(m, var) {
  ct <- coef(summary(m))
  if (!var %in% rownames(ct)) return(c(est = NA, se = NA))
  c(est = round(ct[var, "Value"], 3), se = round(ct[var, "Std. Error"], 3))
}

table3A <- rbind(
  weighted_position = c(extract(m_main, "weighted_position"), extract(m_conttime, "weighted_position"),
                         extract(m_countryfe, "weighted_position"), extract(m_both, "weighted_position")),
  weighted_eu_position = c(extract(m_main, "weighted_eu_position"), extract(m_conttime, "weighted_eu_position"),
                            extract(m_countryfe, "weighted_eu_position"), extract(m_both, "weighted_eu_position")),
  post_chatgpt = c(extract(m_main, "post_chatgpt_factorPost-ChatGPT"), c(est = NA, se = NA),
                    extract(m_countryfe, "post_chatgpt_factorPost-ChatGPT"), c(est = NA, se = NA)),
  year_centered = c(c(est = NA, se = NA), extract(m_conttime, "year_centered"),
                     c(est = NA, se = NA), extract(m_both, "year_centered"))
)
colnames(table3A) <- c("main_est", "main_se", "conttime_est", "conttime_se",
                        "countryfe_est", "countryfe_se", "both_est", "both_se")

write.csv(table3A, "output/table3A_robustness.csv")
print(table3A)

aic_row <- c(main = round(AIC(m_main), 1), conttime = round(AIC(m_conttime), 1),
             countryfe = round(AIC(m_countryfe), 1), both = round(AIC(m_both), 1))
cat("\nAIC by specification:\n"); print(aic_row)

saveRDS(list(main = m_main, conttime = m_conttime, countryfe = m_countryfe, both = m_both),
        "output/robustness_models.rds")
