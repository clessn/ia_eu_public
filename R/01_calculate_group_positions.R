################################################################################
# SCRIPT 01 - CALCULATE POSITIONS OF EUROPEAN PARLIAMENTARY GROUPS
#
# Methodology: Weighted mean based on official EP composition and Chapel Hill
#              Expert Survey (CHES) data, following McElroy & Benoit (2007).
# Input: Pre-computed mapping of EP national parties to CHES party IDs,
#        official EP composition data, and CHES data.
# Output: A dataset of EP political groups with their calculated left-right
#         ideological positions.
#
################################################################################

# 1. LIBRARIES ----------------------------------------------------------------
# Ensure pacman is installed to manage packages
if (!require(pacman)) install.packages("pacman")
pacman::p_load(dplyr, readr, stringr, ggplot2, forcats, xml2, httr, jsonlite)

cat("=== SCRIPT 01: CALCULATING EP POLITICAL GROUP POSITIONS ===\n\n")

# 2. LOAD DATA ----------------------------------------------------------------
cat("=== Loading Data ===\n")

# Load the mapping file of EP national parties to Chapel Hill party IDs.
# This file is treated as static data for reproducibility.
if (file.exists("data/xml_parties_successful_mappings.csv")) {
  xml_mapping <- read_csv("data/xml_parties_successful_mappings.csv", show_col_types = FALSE)
  cat(sprintf("✓ National party to CHES mapping loaded: %d matches\n", nrow(xml_mapping)))
} else {
  stop("❌ 'data/xml_parties_successful_mappings.csv' not found. This file is required.")
}

# Load Chapel Hill Expert Survey (CHES) data for party scores
ches_trend <- read_csv("data/chapel_hill/1999-2019_CHES_dataset_means(v3).csv", show_col_types = FALSE)
ches_2024 <- read_csv("data/chapel_hill/CHES_2024_final_v2.csv", show_col_types = FALSE)
cat("✓ CHES source data loaded.\n")

# Country code mapping tables
country_numeric_mapping <- data.frame(
  country_code_numeric = c(1:28),
  country_name = c("Belgium", "Denmark", "Germany", "Greece", "Spain", "France", "Ireland", "Italy", 
                   "Luxembourg", "Netherlands", "Portugal", "United Kingdom", "Austria", "Finland", 
                   "Sweden", "Czechia", "Estonia", "Hungary", "Latvia", "Lithuania", "Poland", 
                   "Slovakia", "Slovenia", "Malta", "Cyprus", "Bulgaria", "Romania", "Croatia"),
  stringsAsFactors = FALSE
)

country_alpha_mapping <- data.frame(
  country_code_alpha = c("aus", "be", "bul", "cro", "cyp", "cz", "dk", "esp", "est", "fin", 
                        "fr", "ge", "gr", "hun", "irl", "it", "lat", "lith", "lux", "mal", 
                        "nl", "pol", "por", "rom", "sle", "slo", "sv", "uk"),
  country_name = c("Austria", "Belgium", "Bulgaria", "Croatia", "Cyprus", "Czechia", 
                   "Denmark", "Spain", "Estonia", "Finland", "France", "Germany", 
                   "Greece", "Hungary", "Ireland", "Italy", "Latvia", "Lithuania", 
                   "Luxembourg", "Malta", "Netherlands", "Poland", "Portugal", 
                   "Romania", "Slovenia", "Slovakia", "Sweden", "United Kingdom"),
  stringsAsFactors = FALSE
)
cat("✓ Country mapping tables loaded.\n")

# 3. PREPARE CHAPEL HILL SCORES ---------------------------------------------
cat("\n=== Preparing Chapel Hill Scores ===\n")

# Clean and combine CHES trend (1999-2019) and 2024 data
ches_trend_clean <- ches_trend %>%
  left_join(country_numeric_mapping, by = c("country" = "country_code_numeric")) %>%
  filter(!is.na(country_name) & !is.na(lrgen) & !is.na(party_id)) %>%
  select(country_name, party_id, year, lrgen) %>%
  mutate(source = "CHES_trend")

ches_2024_clean <- ches_2024 %>%
  left_join(country_alpha_mapping, by = c("country" = "country_code_alpha")) %>%
  filter(!is.na(country_name) & !is.na(lrgen) & !is.na(party_id)) %>%
  select(country_name, party_id, lrgen) %>%
  mutate(year = 2024, source = "CHES_2024")

ches_combined <- bind_rows(ches_trend_clean, ches_2024_clean) %>%
  arrange(country_name, party_id, year)
cat(sprintf("✓ CHES scores combined: %d observations\n", nrow(ches_combined)))

# Function to get the most relevant CHES score for a given party and year
get_chapel_hill_score <- function(country, party_id, year) {
  party_data <- ches_combined %>%
    filter(country_name == country & party_id == !!party_id)
  
  if (nrow(party_data) == 0) return(NA_real_)
  
  # For recent years, prioritize the 2024 survey
  if (year >= 2020) {
    ches_2024_score <- party_data %>% filter(year == 2024) %>% pull(lrgen)
    if (length(ches_2024_score) > 0) return(ches_2024_score[1])
  }
  
  # Try for an exact year match
  exact_match <- party_data %>% filter(year == !!year) %>% pull(lrgen)
  if (length(exact_match) > 0) return(exact_match[1])
  
  # Fallback to the closest year available
  closest_year_score <- party_data %>%
    mutate(year_diff = abs(year - !!year)) %>%
    arrange(year_diff) %>%
    slice(1) %>%
    pull(lrgen)
  return(closest_year_score[1])
}

# 4. DOWNLOAD OFFICIAL EP COMPOSITION -----------------------------------------
# NOTE: This section downloads live data from europarl.europa.eu and web.archive.org.
# This is part of the original data collection process. For pure reproducibility,
# the output of this process could be saved as a static file.
cat("\n=== Downloading Official EP Composition ===\n")

get_meps_composition <- function(term_number) {
  if (term_number == 10) {
    url <- "https://www.europarl.europa.eu/meps/en/full-list/xml"
  } else if (term_number == 9) {
    url <- "https://web.archive.org/web/20230528110813/https://www.europarl.europa.eu/meps/en/full-list/xml"
  } else if (term_number == 8) {
    url <- "https://web.archive.org/web/20181231054120/http://www.europarl.europa.eu/meps/en/full-list/xml"
  } else {
    return(data.frame())
  }
  
  cat(sprintf("Downloading data for EP Term %d...\n", term_number))
  
  tryCatch({
    response <- GET(url, timeout(30))
    if (status_code(response) != 200) {
      cat(sprintf("⚠️ HTTP Error %d for Term %d\n", status_code(response), term_number))
      return(data.frame())
    }
    
    content_text <- content(response, "text", encoding = "UTF-8")
    
    if (term_number == 10) { # Term 10 uses JSON
      meps_data <- fromJSON(content_text)$list %>%
        as.data.frame() %>%
        transmute(term = term_number, fullName, country = countryLabel,
                  politicalGroup = politicalGroupLabel, nationalPoliticalGroup = nationalPoliticalGroupLabel,
                  mep_id = persId)
    } else { # Terms 8 and 9 use XML
      xml_content <- read_xml(content_text)
      meps <- xml_find_all(xml_content, "//mep")
      meps_data <- data.frame(
        term = term_number,
        fullName = xml_text(xml_find_first(meps, "fullName")),
        country = xml_text(xml_find_first(meps, "country")),
        politicalGroup = xml_text(xml_find_first(meps, "politicalGroup")),
        nationalPoliticalGroup = xml_text(xml_find_first(meps, "nationalPoliticalGroup")),
        mep_id = xml_text(xml_find_first(meps, "id")),
        stringsAsFactors = FALSE
      )
    }
    
    meps_data_clean <- meps_data %>%
      filter(if_all(everything(), ~ !is.na(.) & . != "")) %>%
      mutate(across(where(is.character), str_trim))
      
    cat(sprintf("✓ Term %d: %d MEPs extracted\n", term_number, nrow(meps_data_clean)))
    return(meps_data_clean)
    
  }, error = function(e) {
    cat(sprintf("⚠️ Error for Term %d: %s\n", term_number, e$message))
    return(data.frame())
  })
}

all_meps_official <- bind_rows(lapply(c(8, 9, 10), get_meps_composition))
cat(sprintf("✓ Total official MEPs downloaded: %d\n", nrow(all_meps_official)))

# 5. NORMALIZE POLITICAL GROUP NAMES ----------------------------------------
cat("\n=== Normalizing Political Group Names ===\n")
all_meps_official <- all_meps_official %>%
  mutate(
    politicalGroup_original = politicalGroup,
    politicalGroup_normalized = case_when(
      str_detect(str_to_lower(politicalGroup), "left group.*gue") ~ "The Left Group in the European Parliament - GUE/NGL",
      str_detect(str_to_lower(politicalGroup), "greens.*european free alliance") ~ "Group of the Greens/European Free Alliance",
      str_detect(str_to_lower(politicalGroup), "progressive alliance.*socialists.*democrats") ~ "Group of the Progressive Alliance of Socialists and Democrats in the European Parliament",
      str_detect(str_to_lower(politicalGroup), "european people.*party.*christian") ~ "Group of the European People's Party (Christian Democrats)",
      str_detect(str_to_lower(politicalGroup), "european conservatives.*reformists") ~ "European Conservatives and Reformists Group",
      str_detect(str_to_lower(politicalGroup), "renew europe") ~ "Renew Europe Group",
      str_detect(str_to_lower(politicalGroup), "alliance.*liberals.*democrats") ~ "Alliance of Liberals and Democrats for Europe Group",
      str_detect(str_to_lower(politicalGroup), "non.attached") ~ "Non-attached Members",
      str_detect(str_to_lower(politicalGroup), "identity.*democracy") ~ "Identity and Democracy Group",
      str_detect(str_to_lower(politicalGroup), "patriots.*europe") ~ "Patriots for Europe Group",
      str_detect(str_to_lower(politicalGroup), "europe.*sovereign.*nations") ~ "Europe of Sovereign Nations Group",
      str_detect(str_to_lower(politicalGroup), "europe.*freedom.*direct.*democracy") ~ "Europe of Freedom and Direct Democracy Group",
      str_detect(str_to_lower(politicalGroup), "europe.*nations.*freedom") ~ "Europe of Nations and Freedom Group",
      str_detect(str_to_lower(politicalGroup), "confederal.*european.*united.*left") ~ "Confederal Group of the European United Left - Nordic Green Left",
      TRUE ~ str_trim(politicalGroup)
    )
  )
cat("✓ Political group names normalized.\n")

# 6. JOIN WITH CHES MAPPING ------------------------------------------------
cat("\n=== Joining Official MEP list with CHES Mapping ===\n")
meps_with_chapel_hill <- all_meps_official %>%
  left_join(xml_mapping, by = c("country", "nationalPoliticalGroup")) %>%
  filter(!is.na(chapel_hill_party_id))
cat(sprintf("✓ MEPs with a CHES party ID: %d/%d (%.1f%%)\n", 
            nrow(meps_with_chapel_hill), nrow(all_meps_official),
            100 * nrow(meps_with_chapel_hill) / nrow(all_meps_official)))

# 7. ASSIGN CHES SCORES TO MEPS --------------------------------------------
cat("\n=== Assigning CHES Scores to MEPs ===\n")
meps_with_scores <- meps_with_chapel_hill %>%
  mutate(estimated_year = case_when(term == 8 ~ 2016, term == 9 ~ 2021, term == 10 ~ 2024, TRUE ~ 2020)) %>%
  rowwise() %>%
  mutate(lrgen_score = get_chapel_hill_score(country, chapel_hill_party_id, estimated_year)) %>%
  ungroup() %>%
  filter(!is.na(lrgen_score))
cat(sprintf("✓ MEPs with an assigned lrgen score: %d\n", nrow(meps_with_scores)))

# 8. CALCULATE WEIGHTED GROUP POSITIONS -----------------------------------
cat("\n=== Calculating Weighted Group Positions (McElroy & Benoit, 2007) ===\n")
meps_by_party <- meps_with_scores %>%
  count(politicalGroup_normalized, country, nationalPoliticalGroup, chapel_hill_party_name, chapel_hill_party_id, lrgen_score, name = "n_meps")

group_positions <- meps_by_party %>%
  group_by(politicalGroup_normalized) %>%
  summarise(
    weighted_position = sum(lrgen_score * n_meps) / sum(n_meps),
    total_meps = sum(n_meps),
    n_parties = n(),
    n_countries = n_distinct(country),
    .groups = "drop"
  ) %>%
  arrange(weighted_position) %>%
  mutate(
    political_orientation = case_when(
      weighted_position <= 2.5 ~ "Far-left",
      weighted_position <= 4 ~ "Left",
      weighted_position <= 6 ~ "Center",
      weighted_position <= 7.5 ~ "Right",
      TRUE ~ "Far-right"
    ),
    rank_left_right = row_number()
  )
cat("✓ Weighted positions calculated.\n")

# 9. DISPLAY AND EXPORT RESULTS ---------------------------------------------
cat("\n=== Final Political Group Positions ===\n")
results_table <- group_positions %>%
  mutate(position_formatted = sprintf("%.2f", weighted_position)) %>%
  select(Rank = rank_left_right, `Political Group` = politicalGroup_normalized, 
         `L-R Position` = position_formatted, Orientation = political_orientation,
         `Total MEPs` = total_meps, `# Parties` = n_parties)
print(results_table)

if (!dir.exists("output")) dir.create("output")
write_csv(group_positions, "output/parliamentary_groups_positions_final.csv")
cat("\n✓ Group positions saved to 'output/parliamentary_groups_positions_final.csv'\n")

cat("\n======================================================\n")
cat("✓ SCRIPT 01 COMPLETE\n")
cat("======================================================\n")
