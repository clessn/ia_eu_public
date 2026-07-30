# ================================================================================
# 02_table1_group_distribution.R
#
# Reproduces Table 1 (Distribution of AI Interventions by Parliamentary Group).
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/table1_group_distribution.csv
# ================================================================================

suppressPackageStartupMessages(library(dplyr))
if (!dir.exists("output")) dir.create("output")

source("code/utils_normalize_group_names.R")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)
df$Perception.IA <- ifelse(is.na(df$Perception.IA) | df$Perception.IA == "", "Contextual", df$Perception.IA)
df_meps <- df %>%
  filter(is_mep == TRUE) %>%
  filter(!is.na(Perception.IA)) %>%
  filter(Perception.IA %in% c("Optimist", "Pessimist", "Mixed", "Contextual"))

df_meps$group_clean <- sapply(df_meps$speaker_polgroup, normalize_group_names)

group_abbrev <- c(
  "Group of the European People's Party (Christian Democrats)" = "EPP",
  "Group of the Progressive Alliance of Socialists and Democrats in the European Parliament" = "S&D",
  "Renew Europe Group" = "Renew",
  "European Conservatives and Reformists Group" = "ECR",
  "Non-attached Members" = "NI",
  "Group of the Greens/European Free Alliance" = "Greens/EFA",
  "The Left Group in the European Parliament - GUE/NGL" = "GUE/NGL",
  "Identity and Democracy Group" = "ID",
  "Patriots for Europe Group" = "Patriots"
)

# Average 2014-2024 EP seat share per group, from the official composition
# records (output/ep_composition_2014_2024_real.csv in the parent research
# repo). Reported here as fixed reference values, consistent with the
# manuscript's Table 1 note; not recomputed in this package because it
# requires the full multi-term seat-composition scrape, which is out of
# scope for this analysis-only replication package (see README).
seats_pct <- c(EPP = 30.4, `S&D` = 24.4, Renew = 8.7, ECR = 9.7, `Greens/EFA` = 8.3,
               NI = 3.5, `GUE/NGL` = 4.2, ID = 3.5, Patriots = 4.8)

table1 <- df_meps %>%
  mutate(Group = group_abbrev[group_clean]) %>%
  filter(!is.na(Group)) %>%
  count(Group, name = "interventions") %>%
  mutate(
    pct_of_corpus = round(100 * interventions / sum(interventions), 1),
    pct_of_ep_seats = seats_pct[Group],
    repr_ratio = round(pct_of_corpus / pct_of_ep_seats, 2)
  ) %>%
  arrange(desc(interventions))

write.csv(table1, "output/table1_group_distribution.csv", row.names = FALSE)
print(table1)

n_shown <- sum(table1$interventions)
cat(sprintf("\n02_table1_group_distribution.R: N shown = %d (expected 585; N = 587 total MEPs, 2 in minor groups not tabulated, per manuscript Section 3.1)\n", n_shown))
if (n_shown != 585) stop("Table 1 total mismatch: expected 585 across the 9 tabulated groups.")
