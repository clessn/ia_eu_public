# ================================================================================
# 10_figure1_temporal_volume.R
#
# Reproduces Figure 1: monthly proportion of parliamentary interventions
# mentioning AI, relative to total EP plenary activity, 2014-2024.
#
# Input:  data/temporal_analysis_ia_vs_total.csv (monthly total intervention
#         counts vs AI-related intervention counts, pre-aggregated; the full
#         EP intervention record it is aggregated from is ~230MB and is not
#         included in this package -- see README.md)
# Output: output/figure1_temporal_volume.png
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2)
})
if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/temporal_analysis_ia_vs_total.csv", stringsAsFactors = FALSE)
df$year_month <- as.Date(df$year_month)

cat(sprintf("N months: %d, total interventions: %s, AI interventions: %s\n",
            nrow(df), format(sum(df$total_interventions), big.mark = ","),
            format(sum(df$ia_interventions), big.mark = ",")))

# NOTE: proportion_ia is already expressed in percentage points
# (100 * ia_interventions / total_interventions), not a 0-1 fraction.
p <- ggplot(df, aes(x = year_month, y = proportion_ia)) +
  geom_line(linewidth = 0.8) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = NULL, y = "Monthly proportion of interventions mentioning AI") +
  theme_minimal(base_size = 12)

ggsave("output/figure1_temporal_volume.png", p, width = 10, height = 5, dpi = 300, bg = "white")

peak_2021 <- df %>% filter(format(year_month, "%Y") == "2021") %>% summarise(max(proportion_ia))
peak_post_chatgpt <- df %>% filter(year_month >= as.Date("2022-12-01")) %>% summarise(max(proportion_ia))
cat(sprintf("2021 peak monthly proportion: %.2f%%\n", peak_2021[[1]]))
cat(sprintf("Post-ChatGPT peak monthly proportion: %.2f%%\n", peak_post_chatgpt[[1]]))
