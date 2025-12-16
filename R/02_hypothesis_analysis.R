################################################################################
# SCRIPT 02: HYPOTHESIS 1 ANALYSIS - PARTISANSHIP AND AI PERCEPTION
#
# OBJECTIVE: Test the hypothesis that partisan affiliation influences MEPs'
#            perception of AI, using a rigorous methodological approach.
#
# HYPOTHESIS H1: Right-leaning MEPs will have a more optimistic perception
#                of AI than their left-leaning counterparts.
#
################################################################################

# 1. LIBRARIES ----------------------------------------------------------------
if (!require(pacman)) install.packages("pacman")
pacman::p_load(
  dplyr, ggplot2, scales, nnet, brant,
  tidyr, knitr, modelsummary
)

cat("=================================================================\n")
cat("=== SCRIPT 02: H1 - PARTISANSHIP & AI PERCEPTION ANALYSIS ===\n")
cat("=================================================================\n\n")

# 2. LOAD AND PREPARE DATA ----------------------------------------------------
cat("--- STEP 1: Loading and Validating Data ---\n")

# Load main dataset
tryCatch({
  df <- read.csv("data/ai_categorized_paragraphs_reconciled.csv", stringsAsFactors = FALSE)
  df$Perception.IA <- ifelse(is.na(df$Perception.IA) | df$Perception.IA == "", "Contextual", df$Perception.IA)
  
  # Load pre-calculated group positions (from script 01)
  score_groups <- read.csv("output/parliamentary_groups_positions_final.csv", stringsAsFactors = FALSE)
  cat("✓ Main data and political group scores loaded successfully.\n")
}, error = function(e) {
  stop("Data loading error. Ensure '01_calculate_group_positions.R' has been run. Details: ", e$message)
})

# Normalize political group names for consistent merging
normalize_group_names <- function(group_name) {
  if (is.na(group_name)) return(NA)
  group_name <- trimws(group_name)
  canonical_names <- c(
    "Group of the European People's Party (Christian Democrats)",
    "Group of the Progressive Alliance of Socialists and Democrats in the European Parliament",
    "Group of the Greens/European Free Alliance",
    "The Left Group in the European Parliament - GUE/NGL",
    "European Conservatives and Reformists Group",
    "Identity and Democracy Group",
    "Renew Europe Group", "Non-attached Members", "Patriots for Europe Group",
    "Europe of Sovereign Nations Group", "Europe of Freedom and Direct Democracy Group",
    "Confederal Group of the European United Left - Nordic Green Left",
    "Group of the Alliance of Liberals and Democrats for Europe"
  )
  alternatives <- list("Group Renew Europe" = "Renew Europe Group", "Non-Attached Members" = "Non-attached Members")
  if (group_name %in% names(alternatives)) return(alternatives[[group_name]])
  group_lower <- tolower(group_name)
  for (canonical in canonical_names) {
    if (tolower(canonical) == group_lower) return(canonical)
  }
  return(group_name)
}
df$speaker_polgroup_clean <- sapply(df$speaker_polgroup, normalize_group_names)
cat("✓ Political group names processed.\n\n")


# 3. BUILD ANALYTICAL DATASET -----------------------------------------------
cat("--- STEP 2: Building Analytical Dataset ---\n")

n_initial <- nrow(df)
cat("Initial observations:", n_initial, "\n")

# Filter 1: MEPs only
df_meps <- df %>% filter(is_mep == TRUE)

# Filter 2: Valid, non-contextual AI perception for the dependent variable
df_ai_coded <- df_meps %>%
  filter(!is.na(Perception.IA) & Perception.IA %in% c("Optimist", "Pessimist", "Mixed"))
cat("Observations after filtering for MEPs with coded perceptions:", nrow(df_ai_coded), "\n")

# Filter 3: Merge with political scores and keep only groups with sufficient size (>= 20 MEPs)
df_merged <- df_ai_coded %>%
  left_join(score_groups, by = c("speaker_polgroup_clean" = "politicalGroup_normalized")) %>%
  filter(!is.na(weighted_position) & total_meps >= 20)
cat("Final analytical dataset size:", nrow(df_merged), "\n")

# Save a report on the filtering process
filtering_report <- data.frame(
  Step = c("Initial", "MEPs only", "Coded AI Perception", "Final (Merged with Scores)"),
  N = c(n_initial, nrow(df_meps), nrow(df_ai_coded), nrow(df_merged))
)
write.csv(filtering_report, "output/h1_filtering_report.csv", row.names = FALSE)
cat("✓ Filtering report saved.\n\n")

# 4. FEATURE ENGINEERING ----------------------------------------------------
cat("--- STEP 3: Feature Engineering ---\n")
df_final <- df_merged

# Dependent Variable: Ordinal perception
df_final$perception_ordered <- factor(df_final$Perception.IA, 
                                    levels = c("Pessimist", "Mixed", "Optimist"),
                                    ordered = TRUE)

# Control Variables
# Temporal dummy for the post-ChatGPT era
df_final$year <- as.numeric(substr(df_final$event_date, 1, 4))
df_final$post_chatgpt_factor <- factor(ifelse(df_final$year >= 2023, 1, 0),
                                      levels = c(0, 1),
                                      labels = c("Pre-ChatGPT", "Post-ChatGPT"))

# National attitudes towards AI (based on Eurobarometer)
pessimistic_countries <- c("Finland", "Sweden", "Denmark", "Luxembourg")
optimistic_countries <- c("Romania", "Croatia", "Portugal")
df_final$country_ai_attitude <- case_when(
  df_final$speaker_country %in% pessimistic_countries ~ "AI-Pessimistic Countries",
  df_final$speaker_country %in% optimistic_countries ~ "AI-Optimistic Countries",
  TRUE ~ "Other EU Countries"
)
df_final$country_ai_attitude <- factor(df_final$country_ai_attitude,
                                      levels = c("Other EU Countries", "AI-Optimistic Countries", "AI-Pessimistic Countries"))
# Gender
df_final$gender_clean <- factor(df_final$speaker_gender, levels = c("male", "female"))

# Topic controls (dummy variables for major topics)
# Using reconciled intercoder variable for topics
df_final <- df_final %>%
  mutate(
    topic_digital_economy = ifelse(manual_intercoder_reconciled_category == "Digital Economy and Innovation Policy", 1, 0),
    topic_education = ifelse(manual_intercoder_reconciled_category == "Education, Skills Development, and Workforce Transformation", 1, 0),
    topic_social_impacts = ifelse(manual_intercoder_reconciled_category == "Social Impacts and Inclusion in the Digital Transformation", 1, 0)
  )

# Create final complete-case dataset for modeling
model_vars <- c("perception_ordered", "weighted_position", "gender_clean", "country_ai_attitude", "post_chatgpt_factor", 
                "topic_digital_economy", "topic_education", "topic_social_impacts")
df_complete <- df_final[complete.cases(df_final[, model_vars]), ]
cat("✓ Final dataset for modeling created with", nrow(df_complete), "complete observations.\n")
# Save this feature-rich dataset for use in script 03
write.csv(df_complete, "data/h1_analysis_features.csv", row.names = FALSE)
cat("✓ Analysis features saved for use in descriptive analysis.\n\n")


# 5. MODELING -----------------------------------------------------------------
cat("--- STEP 4: Model Estimation and Selection ---
")

# Because the dependent variable is categorical (Pessimist, Mixed, Optimist),
# an ordinal logistic regression is a good starting point.
# However, this model relies on the proportional odds assumption.

# Full ordinal model (equivalent to Model 5 in original script)
model_ordinal <- MASS::polr(
  perception_ordered ~ weighted_position + gender_clean + country_ai_attitude +
  post_chatgpt_factor + topic_digital_economy + topic_education + topic_social_impacts, 
  data = df_complete, Hess = TRUE
)

# Test the proportional odds assumption
cat("Testing Proportional Odds Assumption (Brant Test)...
")
brant_test_result <- brant::brant(model_ordinal)
print(brant_test_result)
# Following the original methodology: only check the Omnibus test p-value (first row)
brant_p_value <- brant_test_result[1, "probability"]
assumption_violated <- brant_p_value < 0.05

# Methodological Decision
cat("\n=== METHODOLOGICAL DECISION ===\n")
cat("Brant Omnibus test p-value:", round(brant_p_value, 4), "\n")

if(assumption_violated) {
  cat("-> ASSUMPTION VIOLATED (p < 0.05)\n")
  cat("-> DECISION: Switching to Multinomial Logistic Regression for final analysis.\n")
  cat("-> JUSTIFICATION: The proportional odds assumption is not met.\n\n")
  
  # Estimate the final multinomial model
  # Set 'Pessimist' as the baseline category for comparison
  df_complete$perception_unordered <- factor(df_complete$perception_ordered, ordered = FALSE)
  
  final_model <- nnet::multinom(
    perception_unordered ~ weighted_position + gender_clean + country_ai_attitude +
    post_chatgpt_factor + topic_digital_economy + topic_education + topic_social_impacts, 
    data = df_complete, trace = FALSE
  )
  model_type <- "Multinomial"
  cat("✓ Final multinomial model estimated.\n")
  
} else {
  cat("-> ASSUMPTION MET (p >= 0.05)\n")
  cat("-> DECISION: Using Ordinal Logistic Regression for final analysis.\n")
  cat("-> JUSTIFICATION: The proportional odds assumption holds.\n\n")
  final_model <- model_ordinal
  model_type <- "Ordinal"
}

# 6. RESULTS AND VISUALIZATION ---------------------------------------------
cat("--- STEP 5: Analyzing and Visualizing Final Model ---
")

# Display a summary of the final model
print(summary(final_model))

# Save model summary to a text file
sink("output/h1_model_summary.txt")
cat(sprintf("=== SUMMARY OF FINAL MODEL (Type: %s) ===\n", model_type))
print(summary(final_model))
cat("\n\n=== ODDS RATIOS (exponentiated coefficients) ===\n")
print(exp(coef(final_model)))
sink()
cat("✓ Model summary saved to 'output/h1_model_summary.txt'.\n")

# Save full model object for inspection
saveRDS(final_model, file = "output/h1_final_model.rds")
cat("✓ Final model object saved to 'output/h1_final_model.rds'.\n")

# Create predicted probabilities plot
cat("Generating predicted probabilities plot...
")

# Create a grid of data for prediction, varying only the key independent variable
pred_data <- expand.grid(
  weighted_position = seq(min(df_complete$weighted_position), max(df_complete$weighted_position), by = 0.1),
  gender_clean = "male",
  country_ai_attitude = "Other EU Countries",
  post_chatgpt_factor = "Pre-ChatGPT",
  topic_digital_economy = 0,
  topic_education = 0,
  topic_social_impacts = 0
)

# Predict probabilities
predictions <- predict(final_model, newdata = pred_data, type = "probs")
pred_data_full <- cbind(pred_data, predictions)

# Reshape data for plotting
pred_long <- pred_data_full %>%
  pivot_longer(cols = c("Pessimist", "Mixed", "Optimist"),
               names_to = "Perception", values_to = "Probability") %>%
  mutate(Perception = factor(Perception, levels = c("Pessimist", "Mixed", "Optimist")))

# Generate the plot
predicted_prob_plot <- ggplot(pred_long, aes(x = weighted_position, y = Probability,
                            color = Perception, linetype = Perception)) + 
  geom_line(linewidth = 1.2, alpha = 0.9) + 
  scale_x_continuous(name = "Political Position (Far Left ⮕ Far Right)") + 
  scale_y_continuous(labels = scales::percent, name = "Predicted Probability", limits = c(0, 1)) + 
  scale_color_manual(values = c("Pessimist" = "black", "Mixed" = "gray40", "Optimist" = "gray70"), name = "AI Perception") + 
  scale_linetype_manual(values = c("Pessimist" = "solid", "Mixed" = "dashed", "Optimist" = "dotted"), name = "AI Perception") + 
  labs(
    title = "Predicted Probability of AI Perception by Political Position",
    subtitle = "Based on multinomial model, holding other variables at their reference categories"
  ) + 
  theme_minimal(base_size = 12) + 
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, color = "gray30"),
    legend.position = "bottom",
    axis.title = element_text(face = "bold")
  )

ggsave("figures/fig_h1_predicted_probabilities.png", predicted_prob_plot, width = 10, height = 7, dpi = 300, bg = "white")
cat("✓ Predicted probabilities plot saved to 'figures/fig_h1_predicted_probabilities.png'.\n")


# Generate coefficient plot
cat("Generating coefficient plot...
")
coef_plot <- modelplot(
  final_model,
  coef_map = c(
    "weighted_position" = "Political Position (Right)",
    "gender_cleanfemale" = "Gender: Female",
    "country_ai_attitudeAI-Pessimistic Countries" = "Country: AI-Pessimistic",
    "country_ai_attitudeAI-Optimistic Countries" = "Country: AI-Optimistic",
    "post_chatgpt_factorPost-ChatGPT" = "Period: Post-ChatGPT",
    "topic_digital_economy" = "Topic: Digital Economy",
    "topic_education" = "Topic: Education",
    "topic_social_impacts" = "Topic: Social Impacts"
  )
) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red") +
  labs(
    title = "Effect of Predictors on AI Perception",
    subtitle = "Odds Ratios from Multinomial Regression (Base category: Pessimist)",
    x = "Odds Ratio (OR)",
    y = "Predictor Variable"
  ) + 
  theme_minimal(base_size = 12) + 
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, color = "gray30"),
    axis.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("figures/fig_h1_coefficient_plot.png", coef_plot, width = 10, height = 8, dpi = 300, bg = "white")
cat("✓ Coefficient plot saved to 'figures/fig_h1_coefficient_plot.png'.\n\n")

cat("======================================================\n")
cat("✓ SCRIPT 02 COMPLETE\n")
cat("======================================================\n")
