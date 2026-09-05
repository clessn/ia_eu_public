# ================================================================================
# check_output_drift.R
#
# AI Politics and Regulation in the European Parliament: Ideological Divides
# and Policy Convergence amid Generative AI's Ascent
# Etienne Proulx, Steve Jacob, Arnaud Beaule, Shannon Dinan, Yannick Dufresne
#
# Confirms that the CSVs committed to the repository still match what the
# pipeline produces. Run AFTER code/00_run_all.R, from the repository root:
#
#   Rscript code/00_run_all.R
#   Rscript validation/check_output_drift.R
#
# Numeric columns are compared with a tolerance rather than byte for byte.
# Regression coefficients and predicted probabilities are computed through
# LAPACK, whose last significant digits differ between machines, so a byte
# comparison reports a failure on any machine other than the one that happened
# to generate the committed file.
#
# The tolerance has to sit above one unit in the last digit the CSVs actually
# store. Those are written at six significant digits, so a value near 0.5 that
# falls on a rounding boundary can shift by 1e-6 between machines without
# anything having changed. 1e-5 clears that while staying two orders of
# magnitude tighter than the two and three decimal places the article reports.
#
# Exits 1 if any committed CSV no longer matches a fresh run.
# ================================================================================

TOL <- 1e-5

files <- sort(Sys.glob("output/*.csv"))
if (length(files) == 0) stop("No output CSVs found. Run code/00_run_all.R first.")

# `git show HEAD:output/x.csv` resolves relative to the current directory inside
# whatever repository encloses it. Run from a working copy nested in a larger
# repo, that silently picks up a same-named file from the parent project rather
# than reporting nothing to compare against. Refuse to run unless this directory
# is the root of the repository that tracks these files.
prefix <- suppressWarnings(system2("git", c("rev-parse", "--show-prefix"),
                                   stdout = TRUE, stderr = FALSE))
if (length(prefix) == 0 || !nzchar(prefix[1])) {
  # empty prefix means we are at the repository root, which is what we want
} else {
  cat(sprintf("Skipped: this is '%s' inside a larger repository, so the committed\n",
              sub("/$", "", prefix[1])))
  cat("versions cannot be resolved. Run from the root of clessn/ia_eu_public.\n")
  quit(status = 0)
}

problems <- character()

for (f in files) {
  committed_path <- tempfile(fileext = ".csv")
  status <- suppressWarnings(
    system2("git", c("show", paste0("HEAD:", f)), stdout = committed_path, stderr = FALSE)
  )
  if (status != 0) {
    cat(sprintf("[NEW ] %s (not in HEAD, nothing to compare)\n", f))
    next
  }

  fresh <- read.csv(f, stringsAsFactors = FALSE)
  committed <- read.csv(committed_path, stringsAsFactors = FALSE)

  if (!identical(dim(fresh), dim(committed))) {
    problems <- c(problems, sprintf("%s: dimensions %s vs committed %s", f,
                                    paste(dim(fresh), collapse = "x"),
                                    paste(dim(committed), collapse = "x")))
    cat(sprintf("[FAIL] %s\n", f))
    next
  }
  if (!identical(names(fresh), names(committed))) {
    problems <- c(problems, sprintf("%s: column names differ", f))
    cat(sprintf("[FAIL] %s\n", f))
    next
  }

  worst <- 0
  worst_col <- NA_character_
  for (col in names(fresh)) {
    a <- fresh[[col]]
    b <- committed[[col]]
    if (is.numeric(a) && is.numeric(b)) {
      d <- abs(a - b)
      d[is.na(d)] <- ifelse(is.na(a) & is.na(b), 0, Inf)[is.na(d)]
      if (max(d) > worst) {
        worst <- max(d)
        worst_col <- col
      }
    } else if (!identical(as.character(a), as.character(b))) {
      problems <- c(problems, sprintf("%s: column '%s' differs", f, col))
    }
  }

  if (worst > TOL) {
    problems <- c(problems, sprintf("%s: column '%s' differs by %.3g (tolerance %.0e)",
                                    f, worst_col, worst, TOL))
    cat(sprintf("[FAIL] %-45s max delta %.3g in '%s'\n", f, worst, worst_col))
  } else {
    cat(sprintf("[ OK ] %-45s max delta %.3g\n", f, worst))
  }
}

cat("\n")
if (length(problems)) {
  cat("Committed outputs no longer match a fresh run:\n")
  for (p in problems) cat("  -", p, "\n")
  quit(status = 1)
}
cat(sprintf("All %d committed CSVs match a fresh run within %.0e.\n", length(files), TOL))
