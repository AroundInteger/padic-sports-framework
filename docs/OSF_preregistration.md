# OSF Pre-Registration: PEF / p-adic clustering pilots in NHS Trust performance and Welsh population health

**Template:** OSF Pre-Registration Template (general)

**Working draft, April 2026 — for submission to OSF before week 4 of the protocol.**

---

## 1. Title

Hierarchy-respecting clustering of NHS Trusts (England) and Welsh LSOAs via the Paired Efficiency Factor and p-adic distance: two parallel pre-registered pilots.

## 2. Authors

[To be completed]

## 3. Description (≤500 words)

Two parallel pilot studies test whether p-adic clustering, with feature decisions and digit weights driven by the Paired Efficiency Factor (PEF) framework, outperforms standard Euclidean clustering on hierarchically structured public-health data. Pilot A clusters ~150 NHS Trusts in England across ~30 publicly released System Oversight Framework (SOF) metrics over five years (2019/20 – 2024/25). Pilot B clusters all 1,909 Welsh Lower Layer Super Output Areas (LSOAs) across the seven Welsh Index of Multiple Deprivation (WIMD) 2019 domains.

Both pilots share a methodology. For each metric, we estimate the variance ratio κ̂ and within-pair correlation ρ̂ under a pairing scheme (within-region trust pairs for Pilot A; within-local-authority LSOA pairs for Pilot B) and across-pair scheme (across-region; across-LA). We compute η = (1+κ)/(1+κ − 2√κ ρ) and the per-metric mutual information I(X; Y) under bivariate normality, where Y is a pilot-specific binary outcome (SOF tier high/low for Pilot A; WIMD overall quintile top/bottom for Pilot B). Each metric is placed in a quadrant of the (κ, ρ) plane. Per-metric decisions on absolute vs. relative feature form follow the PEF quadrant rule. The chosen features are categorised into 2^p quantile bins, encoded as base-p digit strings with weights set to per-metric I(X; Y), and clustered using p-adic agglomerative clustering with single linkage. Prime sweep p ∈ {2, 3, 5, 7, 11, 13}; k_clusters sweep ∈ {2, …, 15}. Baselines at parity: Ward's hierarchical clustering with Euclidean distance, k-means, and Gaussian mixtures.

Hypotheses (six in total, three per pilot) cover (i) the predicted within-pair vs. across-pair quadrant drift; (ii) silhouette improvement of PEF-weighted p-adic clustering over Ward's-Euclidean baseline; (iii) external-outcome predictive lift of cluster membership over a null benchmark.

This pre-registration locks the analysis plan before per-metric PEF estimation results are available. Deviations from the registered analysis will be documented transparently in the eventual paper.

## 4. Hypotheses

### Pilot A — NHS-SOF

**H1 (quadrant drift).** Within-region trust pairings have systematically higher η than across-region trust pairings, with the within-region distribution dominantly in Q1/Q2 (η > 1) and the across-region distribution drifting toward Q3/Q4 (η ≤ 1). Tested by Wilcoxon signed-rank test on per-metric η across the two pairing schemes.

**H2 (clustering quality).** PEF-weighted p-adic clustering achieves silhouette ≥ 0.15 above Ward's-Euclidean baseline at the same number of clusters k. Evaluated by paired bootstrap (10,000 resamples) over trusts.

**H3 (outcome validation).** Cluster membership predicts standardised hospital-level mortality (SHMI) above a null model of region + size, with AUC improvement ≥ 0.05 by 5-fold cross-validation.

### Pilot B — WIMD

**H4 (quadrant drift).** Within-LA WIMD domain pairings sit dominantly in Q1/Q2 (η > 1); across-LA pairings drift toward Q3/Q4 (η ≤ 1). Tested by Wilcoxon signed-rank test on per-domain η across pairing schemes.

**H5 (encoding).** Level-conditional p-adic encoding (rel within LA, abs across LA) achieves silhouette ≥ 0.10 above flat encoding (uniform abs or uniform rel). Evaluated by paired bootstrap over LSOAs.

**H6 (outcome validation).** Cluster membership predicts emergency admission rate or healthy life expectancy (whichever is more reliably available) above the official WIMD overall quintile, with R² improvement ≥ 0.05 in OLS regression.

All hypotheses are one-sided (improvement in the predicted direction). Type-I error α = 0.05 family-wise across the six hypotheses, controlled by Bonferroni–Holm. Power calculations assume the effect sizes above with sample sizes n = 150 (Pilot A) and n = 1,909 (Pilot B); both yield observed power > 0.85 under the registered effect-size thresholds.

## 5. Design plan

**Study type.** Observational, secondary analysis of publicly released datasets. No interventions; no participant contact.

**Blinding.** Not applicable — analysts have access to outcome labels for I(X; Y) computation. Analytic flexibility controlled by this pre-registration.

**Study design.** Two parallel pilots with shared methodology. Each pilot is a cross-sectional clustering analysis with five years of data for Pilot A and a single-year cross-section for Pilot B (with 2014 WIMD as a sensitivity check).

## 6. Sampling plan

**Existing data.** Both datasets exist at the time of pre-registration; neither has been opened or analysed by the pre-registrants beyond inspecting metric names and counts. The PEF estimation has not been run on either dataset.

**Data source.** Pilot A: NHS England System Oversight Framework annual publications and NHS Digital benchmarking files; SHMI from NHS Digital; CQC ratings from CQC public register. Pilot B: Welsh Government StatsWales for WIMD 2019 (and 2014 archive); ONS Geography Portal for LSOA→LA→Health Board mapping; StatsWales / Public Health Wales for emergency admission rates and healthy life expectancy. SAIL Databank linkage is conditional on a separate access application and used only for supplementary outcome validation if available by week 9.

**Sample size.** Pilot A: all NHS Trusts in scope of SOF (~150). Pilot B: all 1,909 Welsh LSOAs. No power-based sample-size determination — both populations are taken in full.

**Sample size rationale.** Both populations are exhaustive at their respective scales; statistical power is determined by the population-level n and the effect-size thresholds in §4.

**Stopping rule.** Not applicable — no sequential data collection.

## 7. Variables

### Manipulated variables
None.

### Measured variables — Pilot A

**Predictors (per trust × year):**
- Approximately 30 SOF metrics across the five SOF domains (quality of care; access; finance and use of resources; leadership and capability; people; local strategic priorities). Exact metric list locked at the end of week 2 in a separate addendum to this pre-registration.
- Region and ICS membership; trust attributes (size, type).

**Outcome:**
- SOF tier (1–4, ordinal; binarised as high/low for the I(X; Y) computation, treated ordinal for cluster validation).

**Validation outcomes:**
- Standardised Hospital-Level Mortality Indicator (SHMI), trust × quarter.
- Care Quality Commission overall rating (Outstanding / Good / Requires Improvement / Inadequate).

### Measured variables — Pilot B

**Predictors (per LSOA):**
- Seven WIMD 2019 domain scores: income, employment, health, education, access to services, housing, community safety.
- Local authority and Health Board membership.

**Outcome:**
- WIMD 2019 overall quintile (1–5; binarised as top/bottom for I(X; Y)).

**Validation outcomes:**
- LSOA-level emergency admission rate (most recent year available).
- Local-authority-level healthy life expectancy (most recent year available).

## 8. Analysis plan

### Statistical models

**Per-metric PEF estimation.** For each metric k and each pairing scheme:
- Sample variance ratio κ̂_k = s²_B / s²_A.
- Sample Pearson correlation ρ̂_k.
- η_k = (1 + κ̂_k) / (1 + κ̂_k − 2√κ̂_k ρ̂_k).
- I(X_k; Y) under PEF's bivariate-normal closed form using (η_k, κ̂_k, δ̂_k, σ̂_{A,k}) and the binary Y above.

**Quadrant assignment.** Each metric placed in Q1, Q2, Q3 or Q4 by signs of (κ̂_k − 1, ρ̂_k).

**Feature selection per metric.**
- Q1, Q2: relative feature.
- Q3: absolute feature.
- Q4: relative if I(X; Y)_rel > I(X; Y)_abs; absolute otherwise.

**p-adic encoding.** Each chosen feature categorised into 2^p quantile bins. Encoding weights w_k = I(X_k; Y) (with lexicographic rescaling if Σ_{j > k} w_j × max_digit ≥ w_k).

**p-adic clustering.** Pairwise p-adic distance computed from the encoded digit strings; agglomerative clustering with single linkage; prime sweep p ∈ {2, 3, 5, 7, 11, 13}; k_clusters sweep ∈ {2, …, 15}; optimum chosen by silhouette score with Davies–Bouldin and Calinski–Harabasz reported as secondary criteria.

**Baselines.** Ward's hierarchical clustering with Euclidean distance, k-means, Gaussian mixture — all on the same continuous feature set, same k sweep.

**Hypothesis tests.**
- H1, H4: Wilcoxon signed-rank on per-metric η_within − η_across.
- H2, H5: Paired bootstrap (10,000 resamples) on silhouette difference.
- H3, H6: 5-fold cross-validation; AUC (H3) or R² (H6) improvement vs. null model.

### Transformations

Skewed metrics (Shapiro–Wilk p < 0.05, |skewness| > 1) log-transformed before PEF estimation. Sensitivity analysis reports both raw and transformed results.

### Inference criteria

- α = 0.05, family-wise across the six hypotheses, Bonferroni–Holm controlled.
- Bootstrap CIs (10,000 resamples) reported alongside p-values.
- Effect sizes: Cohen's d for hypothesis tests; ΔSilhouette for clustering quality; ΔAUC and ΔR² for outcome validation.

### Data exclusion

- Trusts with > 50% missing metrics over the 5-year window excluded from Pilot A.
- LSOAs with missing domain scores in WIMD 2019 excluded from Pilot B (expected: < 1%).
- No outlier exclusion at the analysis stage; winsorisation at 1st/99th percentiles applied to variance estimation only and reported as such.

### Missing data

Median imputation within stratum (trust × year for Pilot A; LSOA neighbours for Pilot B) for predictors with < 20% missingness; multiple imputation as sensitivity check. Outcomes with > 20% missingness handled by listwise deletion at the validation step only.

### Exploratory analyses

Reported separately from confirmatory hypothesis tests above. Include: temporal evolution of clusters across SOF years (Pilot A); clusters of LSOAs by Health Board × WIMD pattern (Pilot B); cross-pilot comparison of (κ, ρ) distributions; hypothesis-generating analyses around policy-relevant outliers.

## 9. Other

**Code and data.** All analysis code published openly under MIT licence at acceptance of the first paper. Pre-registered analyses and exploratory analyses tagged separately in the codebase.

**Preprint.** PEF methodology paper (in-house, draft) will be deposited as preprint by week 4 of the pilot protocol; this pre-registration cites that preprint when available.

**Deviation policy.** Any deviation from this pre-registration will be documented in the corresponding paper's methods section, with the deviation explicitly flagged and the original registered analysis reported as a sensitivity check.

**Conflicts of interest.** None to declare at the time of pre-registration.

**Funding.** [To be completed.]

---

## Submission notes

- Submit to OSF at end of week 3, before per-metric PEF estimation runs in week 4.
- Lock the SOF metric list (Pilot A) in a separate dated addendum by end of week 2.
- Cite the PEF preprint DOI in the registered version once the preprint is live.
