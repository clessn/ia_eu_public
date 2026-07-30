# ================================================================================
# 03_table2_topic_distribution.R
#
# Reproduces Table 2 (Distribution of AI Topics by Parliamentary Group).
#
# Input:  data/ai_categorized_paragraphs_reconciled.csv
# Output: output/table2_topic_distribution.csv
# ================================================================================

suppressPackageStartupMessages(library(dplyr))
if (!dir.exists("output")) dir.create("output")

source("code/utils_normalize_group_names.R")

df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)
df_meps <- df %>% filter(is_mep == TRUE)
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
df_meps$Group <- group_abbrev[df_meps$group_clean]
df_meps$Group[is.na(df_meps$Group)] <- "Other"

topic_labels <- c(
  "Ethical, Regulatory, and Governance Frameworks for AI" = "Ethics & Regulation",
  "Digital Transformation in Public Services, Security, and Infrastructure" = "Public Services",
  "Digital Economy and Innovation Policy" = "Digital Economy",
  "Digital Sovereignty, Geopolitics, and Global Digital Policy" = "Digital Sovereignty",
  "Social Impacts and Inclusion in the Digital Transformation" = "Social Impacts",
  "Education, Skills Development, and Workforce Transformation" = "Education",
  "Environmental Sustainability and Digital Innovation" = "Environment",
  "Other/Miscellaneous" = "Other"
)
df_meps$topic_label <- topic_labels[df_meps$manual_intercoder_reconciled_category]

table2 <- df_meps %>%
  count(topic_label, name = "n") %>%
  arrange(desc(n))

table2_by_group <- df_meps %>%
  count(topic_label, Group) %>%
  tidyr::pivot_wider(names_from = Group, values_from = n, values_fill = 0)

write.csv(table2, "output/table2_topic_distribution_totals.csv", row.names = FALSE)
write.csv(table2_by_group, "output/table2_topic_distribution_by_group.csv", row.names = FALSE)
print(table2)

cat(sprintf("\n03_table2_topic_distribution.R: N = %d (expected 587)\n", sum(table2$n)))
if (sum(table2$n) != 587) stop("Table 2 total mismatch: expected N = 587.")

expected <- c("Ethics & Regulation" = 243, "Public Services" = 85, "Digital Economy" = 79,
              "Digital Sovereignty" = 56, "Social Impacts" = 54, "Education" = 46,
              "Environment" = 12, "Other" = 12)
actual <- setNames(table2$n, table2$topic_label)[names(expected)]
if (!isTRUE(all.equal(unname(actual), unname(expected)))) {
  stop("Table 2 category counts do not match the manuscript. Actual:\n", paste(capture.output(print(actual)), collapse = "\n"))
}
cat("Table 2 category counts match the manuscript exactly.\n")
