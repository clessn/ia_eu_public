# ================================================================================
# 13_figure2A_temporal_perceptions.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Reproduces Online appendix Figure 2A: the annual count of MEP interventions
# in each framing category, with the Dutch childcare benefits scandal and the
# public release of ChatGPT marked.
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/figure2A_temporal_perceptions.png
#         output/figure2A_temporal_perceptions.csv
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
})
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)

df$Perception.IA <- ifelse(is.na(df$Perception.IA) | df$Perception.IA == "",
                           "Contextual", df$Perception.IA)

df_meps <- df %>%
  filter(is_mep == TRUE) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed", "Contextual")) %>%
  mutate(year = as.integer(format(as.Date(event_date), "%Y")))

cat(sprintf("N: %d (expected 587), years %d to %d\n",
            nrow(df_meps), min(df_meps$year), max(df_meps$year)))
if (nrow(df_meps) != 587) stop("Figure 2A sample size mismatch: expected N = 587.")

# Years with no interventions in a category still need a zero, otherwise the
# lines jump across the gap rather than passing through it.
figure2A <- df_meps %>%
  count(year, Perception.IA, name = "interventions") %>%
  complete(year = seq(min(df_meps$year), max(df_meps$year)),
                  Perception.IA = c("Optimist", "Pessimist", "Mixed", "Contextual"),
                  fill = list(interventions = 0)) %>%
  mutate(panel = recode(Perception.IA, Mixed = "Mixed/Realist"),
         panel = factor(panel, levels = c("Optimist", "Pessimist", "Mixed/Realist", "Contextual")))

write.csv(figure2A[, c("year", "panel", "interventions")],
          "output/figure2A_temporal_perceptions.csv", row.names = FALSE)

# ChatGPT was released in November 2022, so the marker sits at the very end of
# that year rather than on the 2022 tick.
events <- data.frame(
  x = c(2021, 2022.92),
  label = c("Toeslagenaffaire", "ChatGPT released")
)

p <- ggplot(figure2A, aes(x = year, y = interventions)) +
  geom_vline(data = events, aes(xintercept = x),
             linetype = "dashed", colour = "grey35", linewidth = 0.5) +
  geom_text(data = events, aes(x = x, y = 40, label = label),
            inherit.aes = FALSE, angle = 90, vjust = -0.4, hjust = 1,
            size = 3, colour = "grey45") +
  geom_line(linewidth = 1.1, colour = "grey20") +
  facet_wrap(~panel, ncol = 2) +
  scale_x_continuous(breaks = seq(2014, 2024, 2)) +
  scale_y_continuous(limits = c(0, 41), breaks = seq(0, 40, 10)) +
  labs(x = NULL, y = "Number of interventions") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold", hjust = 0, size = 12),
        axis.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

ggsave("output/figure2A_temporal_perceptions.png", p,
       width = 10, height = 6.5, dpi = 300, bg = "white")

cat("\nSpot checks against the manuscript text:\n")
pick <- function(cat_, yr) {
  figure2A$interventions[figure2A$Perception.IA == cat_ & figure2A$year == yr]
}
cat(sprintf("  Pessimist 2022 -> 2024: %d -> %d (manuscript: 23 -> 35)\n",
            pick("Pessimist", 2022), pick("Pessimist", 2024)))
cat(sprintf("  Optimist  2022 -> 2024: %d -> %d (manuscript: 18 -> 13)\n",
            pick("Optimist", 2022), pick("Optimist", 2024)))
