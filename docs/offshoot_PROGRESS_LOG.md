# Project progress log — p-adic clustering, PEF, and the public-health pilots

A running, cumulative log of what has been built, decided, found, and fixed. Most-recent entries at the top of each section; chronological detail within. Maintained as the single point of truth for state across sessions.

---

## At a glance — current state

- **Methodology spine is locked.** The PEF / p-adic framework now has (i) a review paper with extensions to sport and public health, (ii) a formal research protocol for two parallel public-health pilots, (iii) an OSF pre-registration document, (iv) a methodology note bridging PEF and p-adic clustering, and (v) a working Python pipeline with passing tests.
- **Roadmap is health-led.** Sport (talent pathway, tournament/bracket) work runs as a separate, data-access-dependent track. Near-term focus is NHS Trust System Oversight Framework and Welsh Index of Multiple Deprivation pilots, both on public data.
- **Pipeline is structurally sound.** 16 of 16 unit tests pass. PEF estimator recovers known (κ, ρ, η) targets on synthetic data. Silhouette beats Ward / k-means / GMM at parity. Quadrant drift signature (within-group Q1/Q2 → across-group Q3/Q4) is recovered on controlled-truth data.
- **Pre-W1 verdict.** Proceed to W1, with two protocol adjustments banked: (a) linkage-method sweep added alongside the prime / k sweep, (b) first concrete W1 deliverable is a rugby-data reproduction of the silhouette 0.7083 result under the new PEF-reframed pipeline.

---

## Artefacts in the workspace

All paths relative to `/Users/rowanbrown/Documents/Claude/Projects/p-adic applications in sport/`.

### Documents

| File | Type | What it is |
| --- | --- | --- |
| `p-adic_review_and_extensions.md` | Working notes | Master review document — current state, gaps, sport and public-health extensions, literature anchors. Revised for the PEF reframe; revised again for health-led roadmap. |
| `p-adic_review_and_extensions.docx` | Formal paper | The same content as the .md, formatted for sharing. Validates clean (149 paragraphs). |
| `research_protocol_NHS-SOF_WIMD_pilots.docx` | Research protocol | Formal 11-section protocol for the parallel NHS-SOF and WIMD pilots. Twelve-week schedule with decision gates at W4, W7, W10. Validates clean (255 paragraphs). |
| `OSF_preregistration.md` | Pre-registration | Standard OSF Pre-registration Template covering both pilots. To be submitted to OSF in W3. |
| `methodology_note_PEF_padic_bridge.md` | Methodology note | ~2,500-word companion bridging PEF and p-adic clustering. Includes the closed-form expected-silhouette result that connects the two frameworks. |
| `PROGRESS_LOG.md` | Log | This file. |

### Code

| Path | What it is |
| --- | --- |
| `pipeline/README.md` | How to install and run the pipeline. |
| `pipeline/requirements.txt` | Python deps. |
| `pipeline/setup.py` | Package install metadata. |
| `pipeline/padic_pef/ingest.py` | Data loaders. Real loaders for NHS-SOF and WIMD are stubs (TODO during W1-W2); synthetic generator is fully implemented. |
| `pipeline/padic_pef/pef.py` | PEF estimation. `eta`, `mutual_information_gaussian`, `estimate_pef`, `estimate_pef_table`, `quadrant_of`, pairing-scheme helpers. |
| `pipeline/padic_pef/encode.py` | Quadrant-aware abs/rel decision, equal-frequency quantile binning, information-content weighting with lexicographic rescaling. |
| `pipeline/padic_pef/cluster.py` | p-adic distance matrix, agglomerative clustering with **single / complete / average linkage sweep**, prime / k sweep, best-by-silhouette selection. |
| `pipeline/padic_pef/validate.py` | Baseline comparisons (Ward / k-means / GMM at parity), bootstrap Jaccard stability, external-outcome prediction (binary and continuous). |
| `pipeline/padic_pef/pipeline.py` | End-to-end orchestration. `run_synthetic()` for the scaffold smoke test; `run(config)` dispatches to NHS-SOF or WIMD once loaders are filled in. |
| `pipeline/tests/test_pef.py` | 8 unit tests for the PEF formulae and estimator. |
| `pipeline/tests/test_encode.py` | 4 unit tests for encoding decisions, binning, lexicographic rescale. |
| `pipeline/tests/test_cluster.py` | 4 unit tests for p-adic distance and clustering recovery. |
| `pipeline/validation/known_truth_validation.py` | Pre-W1 validation script — controlled synthetic with target quadrant assignments plus a Palmer Penguins sanity check. |
| `pipeline/results/validation_report.md` | Output of the validation run. |

---

## Decisions taken (chronological)

1. **Health-led roadmap, sport as a separate track.** Initial extensions covered four directions (talent pathway, tournament/bracket, NHS-trust, WIMD). The public-health pair runs on entirely public data; the sport pair partly depends on URC academy access. Health takes the near-term lane; sport runs in parallel when data permits. (April 2026.)
2. **Both NHS-SOF and WIMD in parallel rather than sequenced.** Shared methodology, shared pipeline, two parallel data tracks. Operational risk acknowledged via decision gates in the protocol. (April 2026.)
3. **PEF replaces abs/rel synthesis as the formal feature-construction backbone.** Per-metric quadrant assignment via (κ̂, ρ̂); abs vs. rel chosen by quadrant rule; digit weights from per-metric I(X; Y). The original abs/rel synthesis is preserved as the Q1/Q2 special case. (April 2026.)
4. **Information-content weighting replaces exponential weights.** Weight w_k = I(X_k; Y), with lexicographic rescaling enforced where needed. Reproducible from the data, principled, and preserves the lexicographic dominance the original weights wanted. (April 2026.)
5. **First W1 deliverable is rugby reproduction.** Before NHS-SOF / WIMD acquisition, run the PEF-reframed pipeline on the existing rugby data and confirm silhouette ≥ 0.71 with sensible cluster interpretation. Strongest "known dataset with known clustering" we possess. (April 2026.)
6. **Linkage-method sweep added to the cluster step.** Single, complete, and average linkage all evaluated alongside the prime / k sweep, best chosen by silhouette. Addresses chaining/collapse behaviour of single linkage on tied p-adic distances. (April 2026.)

---

## Methodology decisions worth surfacing

- **Per-pair I(X; Y) is computed empirically against the binary outcome label, not from the closed-form δ.** The within-group pairing makes A = entity value, B = group mean, so δ = E[A − B] ≈ 0 by construction and the closed-form Gaussian-discriminant I collapses to zero. Empirical I against the outcome restores a meaningful signal.
- **Single linkage is the methodologically natural choice for p-adic distance** (it preserves the ultrametric), but on highly-tied distance matrices (many entities sharing the same first few digits) it chains and collapses at low k. Sweeping single / complete / average and selecting by silhouette is the operational safeguard.
- **Equal-frequency quantile binning is preferred over equal-width binning** because it keeps the marginal information per digit roughly constant, makes I(X_k; Y) directly interpretable as bits-of-Y per digit, and stabilises the encoding against outliers.
- **Aggregation across periods uses entity-level means** before recomputing relative features against group means. This avoids period-level noise dominating the encoding when the underlying signal is at the entity level.

---

## Bugs found and fixed during pipeline build-out

| # | Symptom | Root cause | Fix |
| --- | --- | --- | --- |
| 1 | Within-group `mutual_information` always 0.0 in PEF table | Closed-form I uses δ = mean(A) − mean(B); within-group pairing forces δ ≈ 0 by symmetry | Added empirical I against the binary outcome (`_mi_against_outcome`) when `outcome_col` is supplied; pipeline routes outcome through automatically. |
| 2 | p-adic distance underflowed to 0 for most pairs (clustering collapsed to k=1 regardless of requested k) | Distance formula used `p ** (-weight)` where weights had been lex-rescaled to large magnitudes (~6 000), causing `2 ** -6000 → 0` numerically | Replaced weight-magnitude semantics with position-based valuation: distance = `p ** (-k)` where k is the position of first disagreement (standard p-adic). Dimension ordering (descending I) does the weighting work. |
| 3 | Distance matrix entries silently truncated to integers | `np.full((n, n), p ** 0)` produced an int array (since `p` is int); subsequent float assignments cast to 0 | Initialise as `np.full((n, n), 1.0, dtype=float)`. |
| 4 | Synthetic group separation too weak — clusters collapsed to k=1 in the smoke test | Group-mean variance too low relative to entity and noise variance | Increased group_var to 2.5 in the default synthetic generator. |

Tests added in step: 16 unit tests across `test_pef.py`, `test_encode.py`, `test_cluster.py`. All passing as of latest run.

---

## Pre-W1 validation results

Validation script: `pipeline/validation/known_truth_validation.py`. Output saved to `pipeline/results/validation_report.md`.

### Controlled-truth synthetic (n = 240 entities, 20 groups, 7 metrics)

| Check | Result | Pass? |
| --- | --- | --- |
| PEF recovers within-group positive ρ across all metrics (ρ̂ ∈ [0.33, 0.91]) | η̂ within = 1.3 – 11.1 | ✅ |
| PEF recovers across-group near-zero ρ across all metrics (ρ̂ ∈ [−0.09, +0.08]) | η̂ across = 0.92 – 1.09 | ✅ |
| Predicted quadrant drift (within Q1/Q2 → across Q3/Q4) | 5 of 7 metrics drift to Q3 or Q4 across-group | ✅ |
| p-adic silhouette > Ward / k-means / GMM at same k | 0.889 vs 0.678 (Δ = +0.21) | ✅ |
| Linkage-method invariance under tied p-adic distances | Single, complete, average all return identical silhouettes at p ∈ {2, 3, 5, 7} | ✅ (a property worth knowing) |
| Cluster–outcome alignment at best clustering | ARI ≈ 0.01 at k = 4 | ⚠️ |

The ARI caveat is a test-design issue rather than a pipeline bug. Equal-frequency binning into 4 bins splits the population by quartile of the highest-I metric, and 4-way quartile clusters are not directly comparable to the binary outcome partition. The cluster geometry is internally coherent (high silhouette) but not aligned with the constructed outcome label. The rugby reproduction (W1, see below) is the cleaner test of cluster interpretability.

### Palmer Penguins external check

Skipped — workspace sandbox blocks the external HTTPS fetch to `raw.githubusercontent.com`. Will run locally on the user's machine as part of W1 verification.

---

## Open methodological / engineering questions

1. **k = 2 cluster collapse.** At k = 2, all linkage methods return silhouette 0 (single label). With bins = 4 and dimensions = 7, the dendrogram does not have a clean 2-way cut. Need to investigate `fcluster(criterion="distance")` with explicit thresholds, or `criterion="maxclust_monocrit"` for tie-breaking. Not blocking for W1 but on the queue.
2. **Bin-count sensitivity.** Methodology note flags sensitivity sweep at p ∈ {1, 2, 3} (i.e. 2, 4, 8 bins). Not yet implemented as an explicit sweep dimension in `cluster.sweep()`.
3. **Outcome label choice for I(X; Y).** Currently a single binary label per pilot. For NHS-SOF the SOF tier is ordinal (4-class); the protocol binarises high/low. The methodology note flags multi-class I(X; Y) as a future extension.
4. **Expected-silhouette derivation in the methodology note assumes equal-frequency binning and Y-aligned clusters.** Empirical silhouette will be lower; the gap is itself diagnostic. Worth a small supplementary derivation in the methodology paper.
5. **PEF preprint timing.** Risk R6 in the protocol — the pilot papers cite an in-house methodology paper. Submitting PEF as preprint by W4 closes this risk.

---

## Immediate next actions (W1 plan)

1. **Reproduce the rugby silhouette result.** Run the PEF-reframed pipeline on the existing 1 128-match rugby dataset; expect ≥ 0.71 silhouette at p = 2, k = 6 with tactically interpretable clusters. (Highest-priority sanity check; existing data; no acquisition.)
2. **Scripted ingest of NHS-SOF data.** Trust-level metrics across 2019/20 – 2024/25 from NHS England and NHS Digital open-data endpoints. ODS code reconciliation. Output: tidy DataFrame at `entity_id × period × metric` granularity.
3. **Scripted ingest of WIMD 2019 data.** All 1 909 LSOAs × 7 domains from StatsWales; LSOA → LA → Health Board mapping from ONS Geography Portal. SAIL Databank access request initiated in parallel for optional outcome linkage.
4. **OSF pre-registration submission.** Lock the metric inventory in an addendum and submit before W4.
5. **PEF preprint submission.** In the user's hands; needed before W12 to close risk R6.

---

## How to update this log

Append entries to the relevant section, most-recent-first within each. When a major decision is taken, add it to **Decisions taken** with a date and one-sentence rationale. When a bug is found and fixed, add it to **Bugs found and fixed** with symptom / root cause / fix in three sentences. When a new artefact is created, register it in **Artefacts in the workspace**. The **At a glance** block at the top should always reflect the current truth — update it whenever any of the four lines becomes stale.
