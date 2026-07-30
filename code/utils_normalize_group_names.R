# Shared utility: normalize parliamentary group name casing.
#
# The source export records parliamentary group names inconsistently in case
# (e.g. "Group Of The..." vs "Group of the..." across different scraping
# batches). Every script that groups or joins on speaker_polgroup must
# normalize first, or group totals fragment across case-variant duplicates
# and silently undercount every group (verified against Table 1 during
# package validation: EPP fragmented into a 148-row group and a 19-row group
# instead of the correct 167 total, before this fix).
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
    "Renew Europe Group",
    "Non-attached Members",
    "Patriots for Europe Group",
    "Europe of Sovereign Nations Group",
    "Europe of Freedom and Direct Democracy Group",
    "Confederal Group of the European United Left - Nordic Green Left",
    "Group of the Alliance of Liberals and Democrats for Europe"
  )
  alternatives <- list(
    "Group Renew Europe" = "Renew Europe Group",
    "Non-Attached Members" = "Non-attached Members"
  )
  if (group_name %in% names(alternatives)) return(alternatives[[group_name]])
  group_lower <- tolower(group_name)
  for (canonical in canonical_names) if (tolower(canonical) == group_lower) return(canonical)
  return(group_name)
}
