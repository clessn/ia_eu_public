# ================================================================================
# 05_figure4_predicted_probabilities.R
#
# Reproduces Figure 4: predicted AI-framing probabilities across the
# left-right spectrum, from the ordinal model (Table 3 / Model 5), holding
# other variables at reference levels (AI-neutral country, pre-ChatGPT
# period, ethics/regulation topic, mean EU integration position).
#
# Input:  output/df_complete_h1.rds, output/model5_ordinal.rds
# Output: output/figure4_predicted_probabilities.png
#         output/figure4_predicted_probabilities.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(MASS); library(ggplot2); library(marginaleffects)
})
if (!dir.exists("output")) dir.create("output")

df_complete <- readRDS("output/df_complete_h1.rds")
model5 <- readRDS("output/model5_ordinal.rds")

pred_data <- expand.grid(
  weighted_position = seq(0, 10, by = 0.25),
  weighted_eu_position = mean(df_complete$weighted_eu_position, na.rm = TRUE),
  country_ai_attitude = "Other EU Countries",
  post_chatgpt_factor = "Pre-ChatGPT",
  topic_digital_economy = 0,
  topic_education = 0,
  topic_social_impacts = 0
)

preds <- predictions(model5, newdata = pred_data, conf_level = 0.95) %>%
  as.data.frame() %>%
  mutate(
    Perception = ifelse(group == "Mixed", "Mixed/Realist", as.character(group)),
    Perception = factor(Perception, levels = c("Pessimist", "Mixed/Realist", "Optimist"))
  )

write.csv(preds[, c("weighted_position", "Perception", "estimate", "conf.low", "conf.high")],
          "output/figure4_predicted_probabilities.csv", row.names = FALSE)

p <- ggplot(preds, aes(x = weighted_position, y = estimate, color = Perception,
                        linetype = Perception, fill = Perception)) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.12, color = NA) +
  geom_line(linewidth = 1.3) +
  scale_x_continuous(name = "Political Position (Far Left -> Far Right)", limits = c(0, 10)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), name = "Predicted Probability", limits = c(0, 1)) +
  scale_color_manual(values = c("Pessimist" = "black", "Mixed/Realist" = "gray40", "Optimist" = "gray70")) +
  scale_fill_manual(values = c("Pessimist" = "black", "Mixed/Realist" = "gray40", "Optimist" = "gray70")) +
  scale_linetype_manual(values = c("Pessimist" = "solid", "Mixed/Realist" = "dashed", "Optimist" = "dotted")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave("output/figure4_predicted_probabilities.png", p, width = 10, height = 7, dpi = 300, bg = "white")

at2 <- preds %>% filter(weighted_position == 2) %>% dplyr::select(Perception, estimate)
at8 <- preds %>% filter(weighted_position == 8) %>% dplyr::select(Perception, estimate)
cat("Predicted probabilities at weighted_position = 2 (far left):\n"); print(at2)
cat("Predicted probabilities at weighted_position = 8 (far right):\n"); print(at8)
cat("\nThese correspond to the values reported for Figure 4 in the article,\n")
cat("approximately 52% to 18% for pessimistic framing and 17% to 50% for\n")
cat("optimistic framing across the left-right range.\n")
