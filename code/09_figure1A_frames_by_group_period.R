# ================================================================================
# 09_figure1A_frames_by_group_period.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
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

# The published figure runs the groups along the x axis rather than flipped,
# and prints the number of evaluative interventions behind each bar above it.
# Both facets share the pre-ChatGPT ordering so a group keeps its position
# across periods and the shift is readable across the panels.
n_labels <- frame_dist %>%
  mutate(group_label = factor(group_label, levels = pre_order),
         label = paste0("n=", n))

p <- ggplot(plot_data, aes(x = group_label, y = pct, fill = frame)) +
  geom_col(position = "stack", width = 0.75) +
  geom_text(data = n_labels, aes(x = group_label, y = 104, label = label),
            inherit.aes = FALSE, size = 3, colour = "grey30") +
  facet_wrap(~post_chatgpt_factor) +
  scale_fill_manual(values = c("Pessimist" = "gray10", "Mixed/Realist" = "gray50", "Optimist" = "gray80")) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), breaks = seq(0, 100, 25),
                     limits = c(0, 108)) +
  labs(x = "Political group", y = "Percentage of interventions", fill = "AI frame",
       title = "AI framing by political group: Before and after ChatGPT",
       subtitle = paste("Evaluative frames only (Pessimist, Mixed/Realist, Optimist).",
                        "Groups ordered from most pessimistic to most optimistic in the pre-ChatGPT period.")) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        plot.subtitle = element_text(colour = "grey30", size = 9))

ggsave("output/figure1A_frames_by_group_period.png", p, width = 10, height = 6, dpi = 300, bg = "white")

cat("\nSpot checks against manuscript text:\n")
epp_pre <- frame_dist %>% filter(group_label == "EPP", post_chatgpt_factor == "Pre-ChatGPT") %>% pull(pct_optimist)
greens_pre <- frame_dist %>% filter(group_label == "Greens/EFA", post_chatgpt_factor == "Pre-ChatGPT") %>% pull(pct_optimist)
cat(sprintf("EPP pre-ChatGPT optimistic framing: %.0f%% (manuscript: 61%%)\n", epp_pre))
cat(sprintf("Greens/EFA pre-ChatGPT optimistic framing: %.0f%% (manuscript: 7%%)\n", greens_pre))
