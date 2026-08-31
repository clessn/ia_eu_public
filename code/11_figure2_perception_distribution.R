# ================================================================================
# 11_figure2_perception_distribution.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Reproduces Figure 2: the distribution of AI framing stances across the 587
# MEP interventions carrying coded framing data. The four categories are the
# three evaluative frames plus Contextual, which the regression analyses drop
# because those interventions express no evaluative stance.
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/figure2_perception_distribution.png
#         output/figure2_perception_distribution.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2)
})
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)

# Interventions with no coded frame are Contextual: AI is mentioned, but no
# evaluative position is taken. Same treatment as 02_table1_group_distribution.R.
df$Perception.IA <- ifelse(is.na(df$Perception.IA) | df$Perception.IA == "",
                           "Contextual", df$Perception.IA)

df_meps <- df %>%
  filter(is_mep == TRUE) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed", "Contextual"))

cat(sprintf("N (MEP interventions with coded framing): %d (expected 587)\n", nrow(df_meps)))
if (nrow(df_meps) != 587) stop("Figure 2 sample size mismatch: expected N = 587.")

figure2 <- df_meps %>%
  count(Perception.IA, name = "interventions") %>%
  mutate(
    label = recode(Perception.IA, Mixed = "Mixed/Realist"),
    label = factor(label, levels = c("Pessimist", "Mixed/Realist", "Optimist", "Contextual")),
    pct = round(100 * interventions / sum(interventions), 1)
  ) %>%
  arrange(label)

write.csv(figure2[, c("label", "interventions", "pct")],
          "output/figure2_perception_distribution.csv", row.names = FALSE)
print(figure2[, c("label", "interventions", "pct")])

p <- ggplot(figure2, aes(x = label, y = pct, fill = label)) +
  geom_col(width = 0.72, colour = "black", linewidth = 0.3) +
  geom_text(aes(label = paste0(interventions, " interventions\n", format(pct, nsmall = 1), "%")),
            vjust = -0.35, size = 3.6, fontface = "bold", lineheight = 1.05) +
  scale_fill_manual(values = c("Pessimist" = "gray20", "Mixed/Realist" = "gray50",
                               "Optimist" = "gray70", "Contextual" = "gray90"),
                    guide = "none") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, 32), breaks = seq(0, 30, 10),
                     expand = expansion(mult = c(0, 0))) +
  labs(x = "AI perception", y = "Percentage of interventions (%)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.x = element_blank(),
        axis.text = element_text(face = "bold"),
        axis.title = element_text(face = "bold"))

ggsave("output/figure2_perception_distribution.png", p,
       width = 10, height = 6, dpi = 300, bg = "white")

cat("\nSpot checks against manuscript text:\n")
for (lab in levels(figure2$label)) {
  row <- figure2[figure2$label == lab, ]
  cat(sprintf("  %-14s N=%3d  %.1f%%\n", lab, row$interventions, row$pct))
}
