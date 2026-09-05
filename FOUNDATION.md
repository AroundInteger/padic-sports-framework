# Foundation

P-adic clustering of hierarchical paired systems. Rugby as the falsification platform; PEF as the feature-construction spine. Swansea University.

**Status:** normative. Where this file disagrees with any other document in either worktree, this file wins and the other document is corrected. Written 25 August 2026. UK English throughout.

This document exists because the project's knowledge is split across two idle worktrees that have drifted apart, and because the MATLAB tree itself carries five mutually inconsistent silhouette numbers for the same 1,128 matches. It replaces none of the papers, scripts or logs; it governs them. Its test is operational: an incoming Research Associate should be able to read this file alone and know what to reproduce in week one, what not to cite, and why.

The rule that shapes every table below. Each entry carries three fields: what it is, why it is that way, and what it obliges someone to do. An entry that cannot fill the third field is background reading, and belongs in a citation rather than a row.

**Citation convention.** Author–year throughout, because compiled [n] numbering does not yet exist and a stale number here would propagate. The prior-art ledger (§3) is the sync source when a numbered bibliography is introduced.

**Path convention.** Paths beginning `docs/`, `data/`, `pipeline/`, `validation_results_*` or `*.m` are relative to this repository (`p-adic-systems`).

- **MATLAB/** = this repository's `.m` scripts (audit of the 2025 runs)
- **PIPELINE/** = `pipeline/padic_pef/` (canonical Python, copied from the off-shoot on 25 August 2026)
- **OFFSHOOT/** = `/Users/rowanbrown/Documents/Claude/Projects/p-adic applications in sport/` (archive; do not edit in parallel)
- **DATA/** = `data/rugby/rugby_analysis_ready.csv`
- **PAPERS/** = `docs/Paper/`

The April–June 2026 off-shoot's pipeline, methodology note, review, OSF draft, protocol and progress log now live in this repository (`pipeline/`, `docs/`). Initialise git here before any further merge. The Claude folder is an archive.

---

## 0. Precedence and scope

| Rank | File | Governs |
|---|---|---|
| 1 | This file | Object definition, parameters, distance convention, tiers, rulings |
| 2 | `docs/methodology_note_PEF_padic_bridge.md` | PEF → encoding → expected-silhouette derivation, subordinate to §1, §5 and §6 here |
| 3 | `docs/p-adic_review_and_extensions.md` | Positioning, literature, extensions |
| 4 | `docs/OSF_preregistration.md` | Health-pilot hypotheses, unsubmitted |
| 5 | `docs/offshoot_PROGRESS_LOG.md` | Off-shoot session state; stale where it treats 0.7083 as known truth |
| 6 | `PAPERS/padic_rugby_latex.tex` | Perfect-to-practical narrative |
| 7 | `PAPERS/padic_rugby_latex_enhanced.tex` | Fragment claiming 0.7083 and 126.7% lift |
| 8 | `enhanced_padic_rugby_pipeline.m` | Reference MATLAB encoding that claimed 0.7083 |
| 9 | `validation_results_phase{1,2,3}*/` and `pipeline/results/matlab_reproduction.md` | Empirical record, including failures and the 25 Aug 2026 Python D2 run |
| 10 | `pipeline/padic_pef/` | Canonical implementation. Rugby ingest and legacy_d2 exist. NHS-SOF / WIMD still stubs |

Ranks 5, 6 and 7 have a specific hazard: all three still present silhouette 0.7083 as an established real-data result. That number was not recovered on the current CSV under a faithful D2 port (ruling R12). Rank 10's `cluster.py` now documents D3; D2 lives only in `legacy_d2.py`.

---

## 1. The object of study

### 1.1 Definition

Fix a finite set of entities $E = e_1,\dots,e_N$ and a finite set of metrics $k = 1,\dots,K$. Each entity is observed through paired measurements $(X_{A,k}(e), X_{B,k}(e))$, where $A$ is the entity and $B$ is a designated counterpart (opponent, regional peer, local-authority mean). A **hierarchical paired system** is this collection together with a distinguished outcome label $Y$, in which the meaningful distance between two entities is dominated by the highest organisational level at which they differ.

Three properties define the class, and each one is load-bearing.

1. **Ultrametric hierarchy.** If $e_i$ and $e_j$ first disagree at level $\ell$, no agreement at finer levels can pull them closer. This is the ultrametric inequality $d(x,z) \le \max\{d(x,y), d(y,z)\}$, and it is why a p-adic (or any ultrametric) distance is not an arbitrary substitute for Euclidean distance. Remove it and the project is ordinary clustering of a hand-weighted feature vector.

2. **Paired measurements.** Absolute and relative features are not two styles of writing the same table. Whether $X_A$ or $X_A - X_B$ carries the signal is an empirical question, answered per metric by the Paired Efficiency Factor (PEF). A single unpaired cloud, or two co-located but non-paired populations, is a different problem — that is the topology grant, not this one.

3. **Defensible categorisation.** Continuous metrics are mapped to digits of a base-$p$ address. This is not a preprocessing convenience: it is what makes the entity a p-adic integer rather than a point in $\mathbb{R}^K$. Whether a new system admits a defensible discretisation (natural tiers, policy thresholds, or equal-frequency bins with a stated $p$) is a question, not an assumption; see the O1 gate in §2.3.

Rugby is the only setting in hand that supplies a full population of adversarially paired trajectories, with expert-readable cluster labels. It is the **falsification platform**, not the contribution. The framework transfers to any hierarchical paired system once PEF is re-estimated and the digit schedule is re-derived — that qualifier travels with the claim, always.

### 1.2 The derived chain

Every quantity in this project is one of seven objects, produced in this order. The chain is fixed; disputes about a number are disputes about a stage of it.

| Stage | Object | Produced by |
|---|---|---|
| 1 | Paired table $(X_{A,k}, X_{B,k})$ | Match-level abs/rel columns; or trust–peer / LSOA–LA pairing |
| 2 | PEF record $(\hat\kappa_k, \hat\rho_k, \hat\eta_k, I(X_k;Y))$ | `pipeline/padic_pef/pef.py` |
| 3 | Feature $f_k \in \{X_{A,k}, X_{A,k}-X_{B,k}\}$ | Quadrant rule, §2.2 |
| 4 | Digit $d_k \in \{0,\dots,b-1\}$ | Equal-frequency quantile binning, $b = 2^p$ in the note, $b=4$ in MATLAB |
| 5 | Address $\mathbf{d}(e) = (d_1,\dots,d_K)$ | Dimensions ordered by descending $I(X_k;Y)$ |
| 6 | Distance $D_{ij} = d_p(\mathbf{d}(e_i), \mathbf{d}(e_j))$ | D3, the position-based p-adic metric of §2.5 |
| 7 | Inference | Hierarchical clustering, silhouette, external $Y$ |

Homology, landscapes and CUSUM are out of scope. They belong to the competitive-collectives grant. This project clusters addresses; it does not persist filtrations.

Four distance functions exist in the two trees. **Only D3 is licensed going forward.**

| Code | Where | What it actually computes | Status |
|---|---|---|---|
| D0 | `rugby_padic_functions.m` | True p-adic norm of a rational approximation to $x_i - y_i$, then max over components | Implemented; unused by the headline pipeline |
| D1 | `perfect_padic_rugby_optimized.m` | Weighted max of scaled component differences. Ultrametric by taking max. Not a p-adic valuation | Synthetic only. Do not call it p-adic in a paper |
| D2 | `enhanced_padic_rugby_pipeline.m` | $\max_k p^{-v_p(\lvert f_{ik}-f_{jk}\rvert)}$ with a special case: any difference $\ge 10{,}000$ is forced to distance 1 | Produced 0.7083. Audit reference only |
| D3 | `pipeline/padic_pef/cluster.py` | $d = p^{-k^*}$ where $k^*$ is the first digit position at which the two addresses disagree (most-significant first). Weights order the digits; they are not exponents | **Canonical.** The MATLAB $w_k$ as exponent underflows at lex-rescaled $I(X;Y)$ (off-shoot bug 2) |

Formally, for addresses in most-significant-first order,

$$d_p(\mathbf{d}, \mathbf{d}') = \begin{cases} 0 & \text{if }\mathbf{d}=\mathbf{d}', \\ p^{-k^*} & \text{if }k^*=\min\{k : d_k \ne d'_k\}. \end{cases}$$

This is the standard p-adic metric on digit strings. It is not the weighted max-norm of D1, and it is not D2's special-case valuation on the raw weighted features.

### 1.3 What is defined but out of scope

A role variable (possession, attacker/defender, trust/peer direction) is defined so that the Standard Grant / health-pilot architecture has a referent, and so that nobody reintroduces it into the rugby paper's clustering by accident. Clustering is on entity-level aggregates. Match-level role inversion is a different object.

Talent-pathway and tournament-bracket encodings are defined in the review (§3 of rank 3) and are data-access-dependent. **Action.** Do not use academy or bracket claims in any rugby deliverable.

Khrennikov ultrametric diffusion is defined so that the health-pilot social-barrier parameter has a name. **Action.** Do not cite it as a result of this project. It is a proposed estimator, not an estimate.

---

## 2. Parameter register

Status codes: **M** measured from data; **C** chosen by convention with a stated reason; **G** gated; **S** synthetic only; **X** defined but out of scope.

### 2.1 System and sampling

| Parameter | Value | Status | Why | Action it obliges |
|---|---|---|---|---|
| Entities $N$ | 16 teams | M | Complete URC/Pro14-era panel in DATA/ | Do not drop teams to chase silhouette. $N=16$ is the population |
| Matches | 1,128 rows, 564 fixtures | M | Seasons 21/22–24/25 | Quote 1,128 as team-match rows, never as independent fixtures |
| Seasons | 21/22, 22/23, 23/24, 24/25 | M | Four complete seasons in the CSV | Leave-one-season-out is the external check |
| Unit of analysis | Team, features averaged over matches | C | Fixture rows are maximally dependent | State the unit in any silhouette or power claim |
| Outcome $Y$ | Match outcome_binary at row level | G | PEF needs $Y$ for $I(X;Y)$ | Lock a team-level $Y$ before the PEF run |
| Perfect system $N$ | 16 synthetic teams, 4 tiers × 4 | S | Hierarchical Dominion construction | Never mix these 16 with the 16 URC names |

### 2.2 Feature encoding (MATLAB headline, then PEF replacement)

The single most error-prone table in the project. Read the last row before using any value.

| Scale / digit | MATLAB value | Status | Why this value | Action |
|---|---|---|---|---|
| Performance tier | $w=10{,}000$; bins on mean final_points_relative: $>10$ Elite, $>2$ Strong, $>-5$ Competitive, else Developing | C | Hand-set so the first digit dominates | Present as a judgement call |
| Attacking style | $w=100$; abs_carries / (abs_passes+1) at 0.8 / 0.6 / 0.4 | C | Abs chosen by intuition | Re-place on $(\kappa,\rho)$ plane under PEF |
| Breakdown | $w=50$; rel turnover differential at $\pm 2$, $0$ | C | Rel chosen by intuition | As above |
| Territory | $w=25$; abs_kicks_from_hand at 20 / 15 / 10 | C | Abs | As above |
| Penetration | $w=12$; rel_clean_breaks at 2 / 0 / $-1$ | C | Rel | As above |
| Discipline | $w=6$; rel_penalties_conceded at $-2$, $0$, $2$ | C | Rel; sign flipped | As above |
| Set piece | $w=3$; abs_scrums_won + abs_lineout_throws_won at 25 / 20 / 15 | C | Abs | As above |
| Prime sweep | MATLAB $2,3,5,7$; note adds $11,13$ | C | $p=2$ won the MATLAB sweep | Report the whole sweep |
| Linkage | MATLAB complete; off-shoot sweeps single / complete / average | C / G | Complete was MATLAB default | Sweep all three; select by silhouette |

**Do not use:** $w_k$ as a p-adic exponent — lex-rescaled $I(X;Y)$ makes $2^{-w_k}$ underflow to 0. Cluster with D3. See ruling R6.

PEF replacement is gated, not yet run on rugby. The MATLAB 10,000→3 schedule is the thing PEF replaces. Until PEF is actually run on DATA/, quote the schedule as a convention, never as information content.

### 2.3 Gates and thresholds

| Gate | Threshold | Action on failure |
|---|---|---|
| MATLAB reproduction | Silhouette 0.7083 at $p=2$, $k=6$, D2 | **Failed in Python (R12).** Cite Python D2 0.5833. Do not proceed as if 0.7083 were confirmed |
| Performance-ablated silhouette | Recorded before any PEF claim | Report both numbers |
| Parity vs Euclidean | p-adic silhouette ≥ Ward/k-means/GMM at same $k$ | Drop the superiority claim |
| PEF rugby run | No silhouette floor (R7) | Report PEF silhouette, D3, linkage, parity table |
| Leave-one-season-out | Mean improvement vs Euclidean baseline | Do not claim temporal generalisation |
| External prediction | Above 50% chance | Say the clustering has not been shown to predict $Y$ |
| Health-pilot start | Rugby parity gate passed or rugby abandoned | Do not fill ingest stubs until this gate |
| Dominion rank recovery | Rank ARI ≥ 0.8 at $k=4$, D3 | Report $\pi$ at first failure; ARI is the gate |

### 2.4 Season design (rugby)

- **Fixtures:** 564 unique, 1,128 team-match rows
- **Clusters at headline:** $k=6$ (sub-tier structure; perfect system has 4 tiers)
- **Headline clusters:** From `padic_rugby_latex_enhanced.tex` — treat as D2 output, recompute under D3/PEF before quoting

### 2.5 Compute and software

- **Canonical distance:** D3: $d = p^{-k^*}$ at first disagreement
- **Python stack:** `pipeline/` — canonical implementation
- **MATLAB stack:** audit of the 2025 0.7083 claim

---

## 3. Prior art ledger

See full ledger in local sync. Key actions:

- **Murtagh (2011); Murtagh & Contreras (2012):** nearest methodological prior art — differentiate on PEF-weighted paired features
- **Bradley (2017):** cite for the diagnostic question — is the rugby table ultrametric, or did we force it to be?
- **Do not import** the ghost citation "Bradley (2009), Ultrametrics and p-adic analysis in persistent homology"
- **PEF paper (in-house, 2026):** companion, not a result of this repo until published

---

## 4. Our own work

### 4.1 Outputs and their status

| Output | Status | Does not license |
|---|---|---|
| Hierarchical Dominion (D3) | Done 25 Aug 2026. E0 silhouette 0.5833, rank ARI 1.0 | That the toy validates rugby; PEF or 0.7083 |
| MATLAB D1 toy | Historical audit. Silhouette 0.9746 | Any real-data result |
| Python D2 port | Done 25 Aug 2026. Silhouette 0.5833 (4 clusters) | 0.7083; Euclidean inferiority |
| Phase 1–3 validation | Corrected Phase 3 **FAILED** | Upgrading failed checks |
| `padic_pef` package | In this repo after sync | NHS-SOF / WIMD ingest (stubs) |

### 4.2 The rugby pilot, exactly

Sixteen URC teams, DATA/, 1,128 team-match rows, four seasons 21/22–24/25.

**Headline (D2, Sep 2025 MATLAB):** Silhouette 0.7083 — **not recovered in Python D2 (0.5833, R12).**

**Parity:** D2 0.5833 vs Ward/k-means/GMM 0.9305 on same 7-d vector. D3 on MATLAB digits: 0.8645 at $p=7$, $k=4$.

**Phase 2 ablation (9 Sep 2025)** — the most important empirical object in the MATLAB tree:

| Condition | Silhouette |
|---|---|
| Full enhanced | 0.7083 |
| No performance tier | 0.6042 |
| No attack style | 0.7292 |
| No breakdown | 0.7120 |
| No territory | 0.7083 |
| No penetration | 0.7135 |
| No discipline | 0.7000 |
| No set piece | 0.7083 |
| Only performance | 1.0000 |
| Only tactical (digits 2–4) | 1.0000 |
| Only physical (digits 5–7) | 0.9375 |
| No weights | 0.3681 |
| Abs only | 0.8153 |
| Rel only | 0.4160 |

Consistent with a dominant first digit, not stable 7-dimensional tactical geometry. "No attack style" raising silhouette is the opposite of a load-bearing dimension.

**Corrected Phase 3:** all four criteria FAILED; prediction 50.0%.

### 4.3 Hierarchical Dominion

Sport-agnostic 16×4 addresses; D3; erosion curve in `pipeline/results/erosion_curve.md`. URC is one adapter (`adapters/rugby.py`), not the definition of the levels.

**Prohibitions:** Do not mix 0.9746 (D1) with rugby results. Do not ratio rugby against 0.9746. A1 uses D3 only.

### 4.4 Academic output priority

| Priority | Output | Do not start until |
|---|---|---|
| A1 | Methods note: Dominion erosion + one rugby reading | Q5 closed |
| A2 | PEF methodology preprint (strip 0.7083) | Can run in parallel with A1 |
| A3 | PEF-reframed rugby paper | Week 3 PEF run |
| A4 | Perfect-to-practical TeX rewrite | A3 numbers |
| A5 | OSF + NHS-SOF / WIMD pilots | Rugby parity gate |
| A6 | Talent pathway; brackets; Khrennikov | A5 or separate grant |

---

## 5. What we investigate

The programme question: given paired measurements on entities whose meaningful geometry is ultrametric, can we decide per metric whether signal lives in $X_A$ or $X_A-X_B$, encode as base-$p$ address, and cluster so hierarchy is respected — with a check that clusters predict something outside the encoding?

### 5.1 A1 questions (Dominion erosion + one rugby reading)

| ID | Question | Status |
|---|---|---|
| Q0 | Does D3 recover planted rank on E0? | **settled** — ARI 1.0 |
| Q1 | E1–E3: rank ARI ≥ 0.8 for all linkage types? | partial |
| Q2 | At what $\pi$ does rank fail under E4/E5? | partial — E4 at 0.1, E5 at 0.3 |
| Q3 | Nested cuts $k \in \{2,4,8\}$ on E0? | open |
| Q4 | Can silhouette rise while ARI collapses under E4? | **settled** |
| Q5 | URC digit permutations — performance-as-rank? | open |
| Q6 | Nearest-row placement stable to linkage/map changes? | open |
| Q7 | D3 beats Euclidean on 4-d integer matrix? | partial — yes under current map |
| Q8 | Nested partition independent of $p>1$? | open |

### 5.2 Later claims (not this pass)

- **C1** — encoding under pairing is well posed (empirical, not yet proved here)
- **C2** — expected silhouette PEF closed form (Tier 5 until evaluated)

---

## 6. The rigour contract

| Tier | Meaning | Permitted verbs |
|---|---|---|
| 1. Cited | Literature | "follows from", "by" |
| 2. Proved here | Proved in project paper | "we prove", "under (H)" |
| 3. Gated | Empirical condition at checkpoint | "we test whether" |
| 4. Demonstrated | Computed under known ground truth | "illustrates" |
| 5. Conjectured | Believed, not established | "we conjecture" |

**Language discipline** (mandatory substitutions):

| Do not write | Write |
|---|---|
| "P-adic analysis of rugby" | "Ultrametric clustering of a base-$p$ encoding of rugby KPIs" |
| "126.7% improvement" | "126.7% over abs-only p-adic 0.3125, same pipeline" |
| "Beats Euclidean clustering" | "Compared with Ward / k-means / GMM at the same $k$" plus table |
| "0.7083 validates the method" | "Python D2 0.5833; MATLAB claimed 0.7083 and it was not recovered" |
| "Sample size 1,128" | "16 teams; 1,128 team-match rows" |

---

## 7. Speculative threads (Tier 5)

Health-led pilots (NHS-SOF, WIMD), talent pathways, tournament brackets, Khrennikov bridge, multi-level PEF — all gated. Collatz/Hasse metaphors: do not use. Armed conflict and quantitative finance: excluded from rugby paper.

---

## 8. Month 1, week by week

**Week 1** — Reproduce MATLAB headline and ablation. Status 25 Aug 2026: Python port is the reproduction that exists. 0.7083 not recovered (R12).

**Week 2** — Port D2 to Python, then replace with D3. Steps 1, 3, 4 done. Step 2 failed — closed as R12.

**Week 2.5** — Hierarchical Dominion + one rugby reading. Erosion curve done. Remaining: Q1–Q3, Q5, Q8.

**Week 3** — PEF on rugby + external checks. Gated on locking team-level $Y$ (R11).

**Week 4** — Paper hygiene + decision (a) proceed with PEF, (b) cautionary note, or (c) abandon rugby for health pilots.

**What the RA should not do in Month 1:** Start NHS-SOF/WIMD ingest. Submit OSF. Splice enhanced TeX as if Phase 3 had not happened. Retry 0.7083 as a coding problem. Run PEF until $Y$ is locked.

---

## 9. Rulings

| Ruling | Status | Summary |
|---|---|---|
| R1 | Closed by R12 | 0.7083 is D2 pipeline output, not established fact |
| R2 | Open in TeX | 126.7% is against 0.3125, not Euclidean |
| R3 | **Standing** | $N$ for clustering is 16, not 1,128 |
| R4 | Open — PI decision | Digit 1 (performance) dominates ablation |
| R5 | **Standing** | Corrected Phase 3 is the external-validation record |
| R6 | Closed in code | D3 canonical; D2 audit only |
| R7 | **Standing** | No PEF silhouette floor ≥ 0.71 |
| R8 | Open | Phase 2 DB numbers are reciprocals |
| R9 | **Standing** | Do not edit both worktrees in parallel |
| R10 | **Standing** | Health ingest downstream of rugby gate |
| R11 | Open | Team-level $Y$ undefined — lock before PEF |
| R12 | **Standing** | 0.7083 not recovered; Python D2 = 0.5833 |
| R13 | **Standing** | Dominion is sport-agnostic; rugby is an adapter |

---

## 10. Sync obligations

A change to distance (D1/D2/D3) sweeps: this file §1.2 and §2.5; `pipeline/padic_pef/cluster.py` and `legacy_d2.py`; methodology note; both TeX files; progress log.

A change to a number goes into §2 or §4 of this file first, then TeX, then review, then methodology note.

**25 Aug 2026** — this file created. Week 1 of §8 is the first empirical act under this constitution.

**25 Aug 2026 (later)** — off-shoot copied; D2 ported; 0.7083 not recovered (R12).

**25 Aug 2026 (later still)** — Dominion D3 erosion curve. A1 is this experiment.

**26 Aug 2026** — §5.1 A1 questions added.

**September 2026** — `padic-sports-framework` merged into this repository as the canonical `p-adic-systems` monorepo. Teaching-bridge MATLAB in `MATLAB/`; full Python pipeline and audit scripts to be synced from local worktree per `docs/MIGRATION.md`.

Before accepting any paper revision: every number traceable to this file; every improvement names its baseline and $k$; $N=16$ stated wherever silhouette appears; D1/D2/D3 named wherever a distance is used; corrected Phase 3 not omitted; 0.7083 not stated as reproduced.
