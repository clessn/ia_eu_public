# ================================================================================
# 10_figure1_temporal_volume.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
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

# The published figure is a monthly histogram with a smoothed trend line over
# it, not a raw series: the month-to-month values are spiky enough that a plain
# line obscures the decade-long trajectory the text describes.
#
# NOTE: proportion_ia is already expressed in percentage points
# (100 * ia_interventions / total_interventions), not a 0-1 fraction.
events <- data.frame(
  date = as.Date(c("2021-01-01", "2022-11-01", "2024-08-01")),
  label = c("Toeslagenaffaire", "ChatGPT released\nto public", "AI Act")
)
trend <- loess(proportion_ia ~ as.numeric(year_month), data = df, span = 0.75)
events$y <- predict(trend, as.numeric(events$date))

p <- ggplot(df, aes(x = year_month, y = proportion_ia)) +
  geom_col(width = 20, fill = "grey75") +
  geom_smooth(method = "loess", span = 0.75, se = FALSE,
              colour = "black", linewidth = 1.1) +
  geom_point(data = events, aes(x = date, y = y),
             shape = 21, fill = "white", colour = "black", size = 2.6) +
  geom_text(data = events, aes(x = date, y = y + 0.55, label = label),
            size = 3.4, lineheight = 0.95, vjust = 0) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y",
               limits = as.Date(c("2013-12-01", "2025-03-01"))) +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Proportion of AI interventions (%)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank())

ggsave("output/figure1_temporal_volume.png", p, width = 10, height = 5, dpi = 300, bg = "white")

peak_2021 <- df %>% filter(format(year_month, "%Y") == "2021") %>% summarise(max(proportion_ia))
peak_post_chatgpt <- df %>% filter(year_month >= as.Date("2022-12-01")) %>% summarise(max(proportion_ia))
cat(sprintf("2021 peak monthly proportion: %.2f%%\n", peak_2021[[1]]))
cat(sprintf("Post-ChatGPT peak monthly proportion: %.2f%%\n", peak_post_chatgpt[[1]]))
