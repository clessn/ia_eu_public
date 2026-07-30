# ================================================================================
# 01_build_analysis_dataset.R
#
# Loads the final coded corpus and builds the analysis-ready dataset used by
# every regression model in the paper (Table 3, Table 4A appendix models,
# Table B appendix multinomial, Table D appendix robustness, Figure 4).
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv (N = 666 AI-related
#         parliamentary interventions, double-blind coded)
#         data/parliamentary_groups_positions_final.csv (CHES-weighted
#         left-right and EU-integration positions per parliamentary group)
# Output: output/df_complete_h1.rds (N = 429, the regression sample)
#         output/filtrage_rapport.csv (sample-construction flow, Figure/Table
#         "flowchart of observations")
# ================================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

if (!dir.exists("output")) dir.create("output")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)

# NA on Perception.IA marks interventions that mention AI descriptively without
# an identifiable evaluative stance ("Contextual" in the paper's typology).
df$Perception.IA <- ifelse(is.na(df$Perception.IA) | df$Perception.IA == "", "Contextual", df$Perception.IA)

score_groups <- read.csv("data/parliamentary_groups_positions_final.csv", stringsAsFactors = FALSE)

source("code/utils_normalize_group_names.R")
df$speaker_polgroup_clean <- sapply(df$speaker_polgroup, normalize_group_names)

# --- Sample construction, documented step by step (matches the flow reported
#     in the manuscript methodology) ---
n_initial <- nrow(df)
df_meps <- df %>% filter(is_mep == TRUE)
df_ai_coded <- df_meps %>%
  filter(!is.na(Perception.IA)) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed"))
df_analysis <- df_ai_coded %>% filter(!is.na(speaker_polgroup_clean))
df_merged <- df_analysis %>%
  left_join(score_groups, by = c("speaker_polgroup_clean" = "politicalGroup_normalized")) %>%
  filter(!is.na(weighted_position)) %>%
  filter(total_meps >= 20)

filtrage_rapport <- data.frame(
  step = c("Initial (all AI-related interventions)", "MEPs only", "Evaluative AI perception coded",
           "Parliamentary group identified", "Final (CHES scores + group size >= 20 MEPs)"),
  n = c(n_initial, nrow(df_meps), nrow(df_ai_coded), nrow(df_analysis), nrow(df_merged))
)
write.csv(filtrage_rapport, "output/filtrage_rapport.csv", row.names = FALSE)

# --- Feature engineering ---
df_final <- df_merged
df_final$perception_ordered <- factor(df_final$Perception.IA,
                                       levels = c("Pessimist", "Mixed", "Optimist"), ordered = TRUE)

df_final$year <- as.numeric(substr(df_final$event_date, 1, 4))
df_final$post_chatgpt <- ifelse(df_final$year >= 2023, 1, 0)
df_final$post_chatgpt_factor <- factor(df_final$post_chatgpt, levels = c(0, 1),
                                        labels = c("Pre-ChatGPT", "Post-ChatGPT"))

# Eurobarometer 101.4 (2024), "robots and AI require careful management":
# extreme-percentile countries flagged as national context controls.
pessimistic_countries <- c("Finland", "Sweden", "Denmark", "Luxembourg")
optimistic_countries <- c("Romania", "Croatia", "Portugal")
df_final$country_ai_attitude <- case_when(
  df_final$speaker_country %in% pessimistic_countries ~ "AI-Pessimistic Countries",
  df_final$speaker_country %in% optimistic_countries ~ "AI-Optimistic Countries",
  TRUE ~ "Other EU Countries"
)
df_final$country_ai_attitude <- factor(df_final$country_ai_attitude,
  levels = c("Other EU Countries", "AI-Optimistic Countries", "AI-Pessimistic Countries"))

# Topic dummies (reference category: Ethical, Regulatory, and Governance
# Frameworks for AI, the modal topic).
df_final <- df_final %>%
  mutate(
    topic_digital_economy = ifelse(manual_intercoder_reconciled_category == "Digital Economy and Innovation Policy", 1, 0),
    topic_education = ifelse(manual_intercoder_reconciled_category == "Education, Skills Development, and Workforce Transformation", 1, 0),
    topic_social_impacts = ifelse(manual_intercoder_reconciled_category == "Social Impacts and Inclusion in the Digital Transformation", 1, 0)
  )

vars_model <- c("perception_ordered", "weighted_position", "weighted_eu_position",
                "country_ai_attitude", "post_chatgpt_factor",
                "topic_digital_economy", "topic_education", "topic_social_impacts")
df_complete <- df_final[complete.cases(df_final[vars_model]), ]

saveRDS(df_complete, "output/df_complete_h1.rds")

cat(sprintf("01_build_analysis_dataset.R: N = %d (expected 429)\n", nrow(df_complete)))
if (nrow(df_complete) != 429) stop("Sample size mismatch: expected N = 429.")
