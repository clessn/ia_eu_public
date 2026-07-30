# Replication package

**AI Politics and Regulation in the European Parliament: Ideological Divides and Policy Convergence amid Generative AI's Ascent**
*European Union Politics*

This repository reproduces every table, figure and reported statistic in the article from the coded corpus of parliamentary interventions. A validation script checks each reproduced result against the value printed in the article, and all 53 checks currently pass.

An earlier version of this package accompanied the first submission. It predates the addition of EU integration position to the models and the removal of speaker gender, so it no longer reproduces the published results. It has been removed to avoid confusion.

## What is and is not covered

The package covers the analysis, from the final coded corpus of 666 AI-related interventions through to the regression models, tables and figures.

It does not rebuild the corpus itself. Constructing it involved dictionary-based filtering of the full plenary record, topic discovery with a large language model, and manual double-blind coding by two coders with reconciliation of every disagreement. Those steps cannot be re-run deterministically, since they depend on API calls whose behaviour changes over time, on an internal database, and on human judgment. They are described in Section 3 of the article and in the Online Appendix. What we share here is the product of that work, which is what a reader needs in order to check the statistical claims.

## Requirements

R 4.5 or later (tested on 4.5.3), and:

```r
install.packages(c("dplyr", "tidyr", "MASS", "nnet", "brant", "marginaleffects", "ggplot2", "scales"))
```

`MASS` and `nnet` ship with base R. The versions used for validation were dplyr 1.2.0, MASS 7.3.65, nnet 7.3.20, brant 0.3.0, marginaleffects 0.28.0, ggplot2 3.5.2, tidyr 1.3.2 and scales 1.4.0.

## Running it

From the root of the repository:

```bash
Rscript code/00_run_all.R
Rscript validation/validate.R
```

The first command runs the ten analysis scripts in order and prints the main quantities each one produces. The second compares those outputs against the values reported in the article and prints PASS or FAIL for each one. Everything is written to `output/`.

Scripts can also be run individually in numerical order. Scripts 04, 05, 07 and 09 need `output/df_complete_h1.rds`, which `01_build_analysis_dataset.R` creates. The others read directly from `data/`.

## Data

| File | Description | N |
|---|---|---|
| `data/ai_categorized_paragraphs_reconciled.csv` | The coded corpus. One row per AI-related parliamentary intervention, February 2014 to December 2024, with speaker metadata, the evaluative AI frame (`Perception.IA`), the regulatory position (`Perception.regulation`), the reconciled topic category, and the lower-cased paragraph text (`paragraphLower`) used for dictionary matching. | 666 |
| `data/parliamentary_groups_positions_final.csv` | Left-right (`weighted_position`) and EU integration (`weighted_eu_position`) scores for each parliamentary group, derived from the Chapel Hill Expert Survey and weighted by national party seat counts within each group across parliamentary terms 8 to 10. | 14 groups |
| `data/temporal_analysis_ia_vs_total.csv` | Monthly counts of AI-related interventions against total plenary volume. The full intervention record these are aggregated from runs to roughly 230 MB and is not included, since only the monthly totals are needed for Figure 1. | 113 months |
| `data/source/` | Provenance for the group position scores: the raw Chapel Hill files (1999–2019 and 2024) and the mapping from national parties to CHES party identifiers. These show where `parliamentary_groups_positions_final.csv` comes from. The pipeline does not read them. | — |

## Code

| Script | Reproduces |
|---|---|
| `01_build_analysis_dataset.R` | Sample construction, N = 666 down to 429 |
| `02_table1_group_distribution.R` | Table 1 |
| `03_table2_topic_distribution.R` | Table 2 |
| `04_models_h1_ordinal_and_multinomial.R` | Table 3, Online Appendix Tables 1A and 2A, Brant test |
| `05_figure4_predicted_probabilities.R` | Figure 4 |
| `06_table4_h2_regulation_consensus.R` | Table 4 |
| `07_table3A_robustness.R` | Online Appendix Table 3A |
| `08_table4A_dictionary_coverage.R` | Online Appendix Table 4A |
| `09_figure1A_frames_by_group_period.R` | Online Appendix Figure 1A |
| `10_figure1_temporal_volume.R` | Figure 1 |

`utils_normalize_group_names.R` is a helper sourced by several scripts rather than run on its own.

## Two things worth knowing about the code

Anyone comparing this code against our earlier working scripts will notice two deliberate changes.

The first concerns the choice between the ordinal and multinomial specifications. The Brant test on Model 5 returns an omnibus p of 0.0497, which rounds to the 0.050 reported in the article and sits exactly on the conventional threshold. Selecting the model with an `if (p < 0.05)` rule at runtime is unstable for that reason, since a difference of a few thousandths would switch the reported model and replace Figure 4 with a different plot. Section 3.4 of the article argues that the ordinal specification should be retained, because the two predictors of theoretical interest satisfy the proportional odds assumption comfortably (p = 0.71 and p = 0.26) and only one thematic control fails it. The code follows that argument, reporting the Brant test in full and then holding the ordinal model as the primary specification.

The second concerns parliamentary group names, which the source export records with inconsistent capitalisation across scraping batches, for instance "Group Of The..." against "Group of the...". Grouping or joining on the raw strings splits each group across its variants, so that the EPP's 167 interventions break into a group of 148 and another of 19. Every group-level operation here normalises case first.

## Where each number comes from

`validation/VALIDATION_REPORT.md` sets out the correspondence between the outputs of this package and each table, figure and inline statistic in the article.
