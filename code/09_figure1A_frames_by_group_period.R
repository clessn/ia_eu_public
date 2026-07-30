# ================================================================================
# 09_figure1A_frames_by_group_period.R
#
# Reproduces Online Appendix Figure 1A: distribution of evaluative AI frames
# (Pessimist, Mixed/Realist, Optimist) by parliamentary group, split into
# pre-ChatGPT (Feb 2014-Nov 2022) and post-ChatGPT (Dec 2022-Dec 2024).
#
# Input:  output/df_complete_h1.rds
# Output: output/figure1A_frames_by_group_period.png
#         output/figure1A_frames_by_group_period.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(tidyr)
})
if (!dir.exists("output")) dir.create("output")

df <- readRDS("output/df_complete_h1.rds")

group_labels <- c(
  "European Conservatives and Reformists Group" = "ECR",
  "Group of the European People's Party (Christian Democrats)" = "EPP",
  "Group of the Greens/European Free Alliance" = "Greens/EFA",
  "Group of the Progressive Alliance of Socialists and Democrats in the European Parliament" = "S&D",
  "Identity and Democracy Group" = "ID",
  "Non-attached Members" = "NI",
  "Renew Europe Group" = "Renew",
  "The Left Group in the European Parliament - GUE/NGL" = "GUE/NGL"
)
df$group_label <- group_labels[df$speaker_polgroup_clean]

frame_dist <- df %>%
  filter(!is.na(group_label)) %>%
  group_by(group_label, post_chatgpt_factor) %>%
  summarise(
    n = n(),
    pct_pessimist = round(100 * mean(perception_ordered == "Pessimist"), 1),
    pct_mixed = round(100 * mean(perception_ordered == "Mixed"), 1),
    pct_optimist = round(100 * mean(perception_ordered == "Optimist"), 1),
    .groups = "drop"
  ) %>%
  filter(n >= 5) # groups with fewer than 5 interventions in a period are excluded, per manuscript note

write.csv(frame_dist, "output/figure1A_frames_by_group_period.csv", row.names = FALSE)
print(frame_dist, n = 30)

pre_order <- frame_dist %>% filter(post_chatgpt_factor == "Pre-ChatGPT") %>%
  arrange(pct_optimist) %>% pull(group_label)

plot_data <- frame_dist %>%
  pivot_longer(cols = starts_with("pct_"), names_to = "frame", values_to = "pct") %>%
  mutate(
    frame = recode(frame, pct_pessimist = "Pessimist", pct_mixed = "Mixed/Realist", pct_optimist = "Optimist"),
    frame = factor(frame, levels = c("Pessimist", "Mixed/Realist", "Optimist")),
    group_label = factor(group_label, levels = pre_order)
  )

p <- ggplot(plot_data, aes(x = group_label, y = pct, fill = frame)) +
  geom_col(position = "stack") +
  facet_wrap(~post_chatgpt_factor) +
  scale_fill_manual(values = c("Pessimist" = "gray20", "Mixed/Realist" = "gray55", "Optimist" = "gray85")) +
  coord_flip() +
  labs(y = "% of evaluative interventions", x = NULL, fill = "AI Frame") +
  theme_minimal(base_size = 12)

ggsave("output/figure1A_frames_by_group_period.png", p, width = 10, height = 6, dpi = 300, bg = "white")

cat("\nSpot checks against manuscript text:\n")
epp_pre <- frame_dist %>% filter(group_label == "EPP", post_chatgpt_factor == "Pre-ChatGPT") %>% pull(pct_optimist)
greens_pre <- frame_dist %>% filter(group_label == "Greens/EFA", post_chatgpt_factor == "Pre-ChatGPT") %>% pull(pct_optimist)
cat(sprintf("EPP pre-ChatGPT optimistic framing: %.0f%% (manuscript: 61%%)\n", epp_pre))
cat(sprintf("Greens/EFA pre-ChatGPT optimistic framing: %.0f%% (manuscript: 7%%)\n", greens_pre))
