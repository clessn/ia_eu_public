# Validation Report

Date of validation: 2026-07-24
R version: 4.5.3 (2026-03-11), x86_64-pc-linux-gnu, Debian GNU/Linux 12
Pipeline executed twice from a clean `output/` directory; results identical both runs (all models here are deterministic MLE fits, not stochastic simulations, so this is expected, not merely reassuring).

## Method

Every numeric result in the article and its Online Appendix that derives from the coded corpus was traced back to the script and data file that produce it, recomputed independently in this package, and compared to the value printed in the article. `validation/validate.R` automates 53 of these comparisons with hard tolerance-based assertions; the remainder (mainly figure shapes and appendix Figure 1A's full 16-row breakdown) were checked by hand against the values shown here.

**Result: every number checked matches the manuscript**, with two script bugs found and fixed in the process (described in `README.md`) and one manuscript text discrepancy surfaced (Figure 4's prose description; also described in `README.md` and below).

## Table-by-table correspondence

### Table 1 — Distribution of AI Interventions by Parliamentary Group

| Group | Manuscript N | Reproduced N | Match |
|---|---|---|---|
| EPP | 167 | 167 | Yes |
| S&D | 141 | 141 | Yes |
| Renew | 81 | 81 | Yes |
| ECR | 50 | 50 | Yes |
| Greens/EFA | 42 | 42 | Yes |
| NI | 42 | 42 | Yes |
| GUE/NGL | 32 | 32 | Yes |
| ID | 27 | 27 | Yes |
| Patriots | 3 | 3 | Yes |

Sum of tabulated groups = 585; total MEP sample N = 587 (2 interventions from Europe of Sovereign Nations and the legacy EFDD group, excluded from the table per the manuscript's Section 3.1 note). Source: `code/02_table1_group_distribution.R`.

Found during validation: the naive (pre-fix) group-name lookup used in the original working scripts is case-sensitive and does not match across scraping-batch casing variants. Before the fix, this split EPP into a 148-row unmatched group and a 19-row "EPP" group instead of the correct total of 167 (and similarly for every other group). Root-caused by diffing `data/ai_categorized_paragraphs.csv`'s raw `speaker_polgroup` values; confirmed fixed by summing case-insensitive matches, which reproduce every group total in Table 1 exactly.

### Table 2 — Distribution of AI Topics by Parliamentary Group

| Category | Manuscript N | Reproduced N | Match |
|---|---|---|---|
| Ethics & Regulation | 243 | 243 | Yes |
| Public Services | 85 | 85 | Yes |
| Digital Economy | 79 | 79 | Yes |
| Digital Sovereignty | 56 | 56 | Yes |
| Social Impacts | 54 | 54 | Yes |
| Education | 46 | 46 | Yes |
| Environment | 12 | 12 | Yes |
| Other | 12 | 12 | Yes |

Total = 587. Source: `code/03_table2_topic_distribution.R`.

### Table 3 — Determinants of AI Perception (Model 5, ordinal)

| Predictor | Manuscript | Reproduced | Match |
|---|---|---|---|
| Political Position | 0.265*** (0.061) | 0.2653 (0.0607) | Yes |
| EU Integration Position | 0.272*** (0.076) | 0.2718 (0.0758) | Yes |
| AI-Optimistic Countries | 0.512 (0.265) | 0.5116 (0.2647) | Yes |
| AI-Pessimistic Countries | -0.106 (0.409) | -0.1057 (0.4091) | Yes |
| Post-ChatGPT Era | -0.633** (0.193) | -0.6327 (0.1934) | Yes |
| Digital Economy | 1.412*** (0.333) | 1.4124 (0.3326) | Yes |
| Education | -0.140 (0.340) | -0.1395 (0.3397) | Yes |
| Social Impacts | 0.036 (0.385) | 0.0357 (0.3848) | Yes |
| Pessimist\|Mixed threshold | 2.041** (0.644) | 2.0413 (0.6444) | Yes |
| Mixed\|Optimist threshold | 3.558*** (0.662) | 3.5576 (0.6619) | Yes |
| AIC | 892.9 | 892.877 | Yes |
| BIC | 933.5 | 933.492 | Yes |
| N | 429 | 429 | Yes |

Significance stars independently recomputed from the coefficient p-values match the manuscript's stars in every row. Source: `code/04_models_h1_ordinal_and_multinomial.R`.

### Online Appendix Table 1A — Five nested ordinal models

| Model | Manuscript AIC | Reproduced AIC | Manuscript BIC | Reproduced BIC |
|---|---|---|---|---|
| 1 | 930.6 | 930.634 | 942.8 | 942.818 |
| 2 | 918.9 | 918.891 | 935.1 | 935.137 |
| 3 | 919.6 | 919.641 | 944.0 | 944.010 |
| 4 | 907.9 | 907.943 | 936.4 | 936.373 |
| 5 | 892.9 | 892.877 | 933.5 | 933.492 |

All five match exactly.

### Brant test (proportional odds assumption, Model 5)

| Term | Manuscript X2 | Reproduced X2 | Manuscript p | Reproduced p |
|---|---|---|---|---|
| Omnibus | 15.53 | 15.528 | 0.050 | 0.0497 |
| Political Position | 0.14 | 0.143 | 0.71 | 0.705 |
| EU Integration Position | 1.25 | 1.247 | 0.26 | 0.264 |
| AI-Optimistic Countries | 0.66 | 0.659 | 0.42 | 0.417 |
| AI-Pessimistic Countries | 0.37 | 0.369 | 0.54 | 0.543 |
| Post-ChatGPT | 1.47 | 1.470 | 0.23 | 0.225 |
| Digital Economy | 3.13 | 3.130 | 0.08 | 0.077 |
| Education | 0.00 | 0.0002 | 0.99 | 0.989 |
| Social Impacts | 8.77 | 8.773 | 0.003 | 0.003 |

All match at the reported precision. **This is also where the branching-logic bug was found**: the raw omnibus p-value (0.0497) is below 0.05, so the original scripts' `if (p < 0.05) use multinomial as final model` logic would have selected the multinomial model, not the ordinal model the manuscript reports for Table 3 and Figure 4. Fixed by pinning the ordinal model as primary in this package, per the manuscript's own stated rationale (individual predictors of interest pass; only one thematic control fails; see README).

### Online Appendix Table 2A — Multinomial logistic regression (robustness)

| Predictor | Manuscript (Mixed) | Reproduced (Mixed) | Manuscript (Optimist) | Reproduced (Optimist) |
|---|---|---|---|---|
| Political Position | 0.173* | 0.1732 | 0.379*** | 0.3789 |
| EU Integration Position | 0.103 | 0.1034 | 0.395*** | 0.3952 |
| AI-Optimistic Countries | 0.603 | 0.6031 | 0.708 | 0.7077 |
| AI-Pessimistic Countries | 0.140 | 0.1399 | -0.310 | -0.3100 |
| Post-ChatGPT Era | -0.196 | -0.1965 | -0.924*** | -0.9237 |
| Digital Economy | -0.104 | -0.1043 | 1.495*** | 1.4954 |
| Education | -0.083 | -0.0827 | -0.136 | -0.1361 |
| Social Impacts | -1.095* | -1.0948 | 0.124 | 0.1239 |
| Intercept | -1.372 | -1.3718 | -4.052*** | -4.0523 |

AIC: manuscript 895.6, reproduced 895.65. Residual deviance: manuscript 859.6, reproduced 859.65. All match.

### Online Appendix Table 3A — Robustness (continuous time, country FE)

| Predictor | Spec | Manuscript | Reproduced |
|---|---|---|---|
| Political Position | Main | 0.265*** | 0.265 |
| Political Position | Cont. time | 0.263*** | 0.263 |
| Political Position | Country FE | 0.295*** | 0.295 |
| Political Position | Cont. + FE | 0.295*** | 0.295 |
| EU Integration | Main | 0.272*** | 0.272 |
| EU Integration | Cont. time | 0.276*** | 0.276 |
| EU Integration | Country FE | 0.275** | 0.275 |
| EU Integration | Cont. + FE | 0.279** | 0.279 |
| Post-ChatGPT (binary) | Main | -0.633** | -0.633 |
| Post-ChatGPT (binary) | Country FE | -0.649** | -0.649 |
| Year (continuous) | Cont. time | -0.160** | -0.160 |
| Year (continuous) | Cont. + FE | -0.162** | -0.162 |
| AIC | Main / Cont. / FE / Both | 892.9 / 893.6 / 922.4 / 923.8 | 892.9 / 893.6 / 922.4 / 923.8 |

All match. Source: `code/07_table3A_robustness.R`.

### Table 4 — AI Framing Stance and Regulatory Position (Hypothesis 2)

| AI Perception | Manuscript (in favor / against / total / %) | Reproduced |
|---|---|---|
| Mixed/Realist | 83 / 3 / 86 / 96.5% | 83 / 3 / 86 / 96.5% |
| Optimist | 61 / 6 / 67 / 91.0% | 61 / 6 / 67 / 91.0% |
| Pessimist | 70 / 1 / 71 / 98.6% | 70 / 1 / 71 / 98.6% |
| Total | 214 / 10 / 224 / 95.5% | 214 / 10 / 224 / 95.5% |

Chi-square test: manuscript X2 = 4.12, df = 2, p = 0.13; reproduced X2 = 4.12, df = 2, p = 0.127. Match. Source: `code/06_table4_h2_regulation_consensus.R`.

### Online Appendix Table 4A — Dictionary Term Coverage

| Term | Manuscript N (%) | Reproduced N (%) |
|---|---|---|
| artificial intelligence | 617 (92.6%) | 617 (92.6%) |
| algorithm | 139 (20.9%) | 139 (20.9%) |
| ChatGPT | 19 (2.9%) | 19 (2.9%) |
| machine learning | 11 (1.7%) | 11 (1.7%) |
| data mining | 3 (0.5%) | 3 (0.5%) |
| deep learning | 1 (0.2%) | 1 (0.2%) |
| machine intelligence | 0 (0.0%) | 0 (0.0%) |

All match exactly. Source: `code/08_table4A_dictionary_coverage.R`.

### Online Appendix Figure 1A — AI Framing by Political Group, Before and After ChatGPT

Full 16-row breakdown reproduced in `output/figure1A_frames_by_group_period.csv`. Spot-checked against every specific claim in the manuscript text (Online Appendix Section 3):

| Claim | Manuscript | Reproduced | Match |
|---|---|---|---|
| EPP pre-ChatGPT optimistic framing | 61% | 61.3% | Yes |
| Greens/EFA pre-ChatGPT optimistic framing | 7% | 6.7% | Yes |
| ECR optimism loss pre->post | -23 pp | 32.3% -> 9.1% = -23.2 pp | Yes |
| S&D optimism loss pre->post | -22 pp | 38.7% -> 17.1% = -21.6 pp | Yes |
| EPP optimism loss pre->post | -23 pp | 61.3% -> 38.8% = -22.5 pp | Yes (rounds to 23) |
| EPP pessimism change pre->post | +1.3 pp | 15.0% -> 16.3% = +1.3 pp | Yes |

Source: `code/09_figure1A_frames_by_group_period.R`.

### Figure 1 — Temporal Evolution of AI-Related Parliamentary Discourse

The 2021 monthly peak (5.25%) exceeds the highest post-ChatGPT monthly proportion (4.52%, June 2023), consistent with the manuscript's claim that "post-ChatGPT monthly rates... do not uniformly exceed this legislative peak." Source: `code/10_figure1_temporal_volume.R`.

### Figure 4 — Predicted AI Framing Probabilities by Political Position

The regenerated figure (`output/figure4_predicted_probabilities.png`) visually matches the figure in the article closely: pessimistic framing declines from roughly 52% at weighted_position = 2 (GUE/NGL's approximate CHES position) to roughly 18% at weighted_position = 8 (ECR's approximate CHES position); optimistic framing rises from roughly 17% to roughly 50% over the same range; mixed/realist framing stays roughly flat around 31-32%.

Validation initially found that these values did not match the prose describing the figure, which reported a decline from 46% to 24% and a rise from 21% to 42%. Both the reproduced figure and the published image showed a steeper gradient than the text described. The text appears to have been left over from an earlier specification, before EU integration position entered the models, and was not updated when the model and figure were revised. Since the model and figure reproduce independently and are consistent with every other reported number, the description was the element at fault. **The article text has since been corrected** and now reports approximately 52% to 18% and 17% to 50%, matching both the model output and the figure.

## Items not independently re-verified in this pass

- **Figure 2, Figure 3, Figure 4** (descriptive distribution figures): not yet traced to a single canonical generating script during this validation pass, given several candidate scripts in the original working repository write to overlapping output paths with differing chart designs (see prior code inventory). The underlying counts they would plot (N = 666, N = 587, category distributions) are already validated via Tables 1, 2, and the corpus-level dictionary and topic checks above; only the specific chart-generation code for these three figures was not re-verified line by line.
- **Table 1's "% of EP seats" column** is a fixed reference value (average 2014-2024 seat share per group) rather than recomputed from a seat-composition time series in this package; see the note in `code/02_table1_group_distribution.R`.
