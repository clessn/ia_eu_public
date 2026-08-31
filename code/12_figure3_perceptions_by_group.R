# ================================================================================
# 12_figure3_perceptions_by_group.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Reproduces Figure 3: the distribution of evaluative AI frames within each
# parliamentary group, ordered from most to least optimistic. Contextual
# interventions are excluded, since the figure compares evaluative stances.
# Groups with fewer than ten evaluative interventions are dropped, per the
# figure note in the manuscript.
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/figure3_perceptions_by_group.png
#         output/figure3_perceptions_by_group.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
})
source("code/utils_normalize_group_names.R")
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)

group_labels <- c(
  "Group of the European People's Party (Christian Democrats)" = "EPP",
  "Group of the Progressive Alliance of Socialists and Democrats in the European Parliament" = "S&D",
  "Renew Europe Group" = "Renew",
  "European Conservatives and Reformists Group" = "ECR",
  "Non-attached Members" = "Non-attached\nMembers",
  "Group of the Greens/European Free Alliance" = "Greens/EFA",
  "The Left Group in the European Parliament - GUE/NGL" = "GUE/NGL",
  "Identity and Democracy Group" = "ID"
)

df_eval <- df %>%
  filter(is_mep == TRUE) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed")) %>%
  mutate(group_label = group_labels[sapply(speaker_polgroup, normalize_group_names)]) %>%
  filter(!is.na(group_label))

figure3 <- df_eval %>%
  group_by(group_label) %>%
  summarise(
    n = n(),
    pct_pessimist = round(100 * mean(Perception.IA == "Pessimist"), 1),
    pct_mixed = round(100 * mean(Perception.IA == "Mixed"), 1),
    pct_optimist = round(100 * mean(Perception.IA == "Optimist"), 1),
    .groups = "drop"
  ) %>%
  filter(n >= 10) %>%
  arrange(desc(pct_optimist))

write.csv(figure3, "output/figure3_perceptions_by_group.csv", row.names = FALSE)
print(figure3)

plot_data <- figure3 %>%
  pivot_longer(cols = starts_with("pct_"), names_to = "frame", values_to = "pct") %>%
  mutate(
    frame = recode(frame, pct_pessimist = "Pessimist",
                   pct_mixed = "Mixed/Realist", pct_optimist = "Optimist"),
    frame = factor(frame, levels = c("Pessimist", "Mixed/Realist", "Optimist")),
    group_label = factor(group_label, levels = figure3$group_label)
  )

p <- ggplot(plot_data, aes(x = group_label, y = pct, fill = frame)) +
  geom_col(position = "stack", width = 0.75) +
  scale_fill_manual(values = c("Pessimist" = "gray10", "Mixed/Realist" = "gray50",
                               "Optimist" = "gray75")) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), breaks = seq(0, 100, 25),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Political group", y = "Percentage of interventions", fill = "AI perception") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title = element_text(face = "bold"),
        panel.grid.major.x = element_blank())

ggsave("output/figure3_perceptions_by_group.png", p,
       width = 10, height = 6, dpi = 300, bg = "white")

cat("\nSpot checks against manuscript text:\n")
spot <- function(g, col, expected) {
  v <- figure3[[col]][figure3$group_label == g]
  cat(sprintf("  %-20s %-14s %5.1f%% (manuscript: %s)\n", g, col, v, expected))
}
spot("EPP", "pct_optimist", "52.7%")
spot("Renew", "pct_optimist", "40.0%")
spot("ID", "pct_optimist", "37.5%")
spot("Greens/EFA", "pct_pessimist", "61.5%")
spot("S&D", "pct_pessimist", "43.7%")
spot("ECR", "pct_pessimist", "40.5%")
