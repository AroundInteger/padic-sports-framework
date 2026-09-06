# From PEF to p-adic clustering: a methodological bridge

**Companion methodological note to the rugby p-adic clustering paper and the public-health pilot protocol.** Approximately 2,500 words. Working draft, April 2026.

---

## Abstract

The Paired Efficiency Factor (PEF) framework gives a per-dimension, distribution-free criterion for choosing between absolute and relative features in correlated paired-measurement settings, and a closed-form relationship between the variance-ratio quantity η and the mutual information I(X; Y) under bivariate normality. The p-adic clustering pipeline, validated empirically on professional rugby data, encodes categorical strategic features as base-p digit strings with exponentially weighted positions and clusters entities by p-adic distance — a metric that respects the ultrametric inequality and so honours hierarchical structure by construction. This note connects the two frameworks. Three results are stated explicitly: (i) the per-dimension PEF (κ̂_k, ρ̂_k) → η_k decision is the principled replacement for the original abs/rel synthesis; (ii) information-content weights I(X_k; Y) computed from the PEF closed form replace the previously heuristic exponential weight schedule and preserve the desired lexicographic property; (iii) under a clean limiting model, the expected silhouette of p-adic clustering on an information-content-weighted base-p encoding admits a closed-form expression in terms of the per-dimension mutual informations — a result not present in the PEF paper, which closes the conceptual loop between PEF (a classification-accuracy result) and p-adic clustering (a silhouette-score result).

---

## 1. Setup and notation

Consider a population of N entities, each described by K paired measurements (X_{A,k}, X_{B,k}) for k = 1, …, K. In the rugby case, an entity is a team-season and the pairing is team-vs-opponent at match level; in the NHS case, an entity is a Trust-year and the pairing is trust-vs-regional-peer; in the WIMD case, an entity is an LSOA and the pairing is LSOA-vs-local-authority-mean.

PEF defines, per dimension k:

- **Variance ratio** κ_k = σ²_{B,k} / σ²_{A,k}.
- **Within-pair correlation** ρ_k = Corr(X_{A,k}, X_{B,k}).
- **Paired Efficiency Factor** η_k = (1 + κ_k) / (1 + κ_k − 2√κ_k ρ_k).
- **Mean separation** δ_k = μ_{A,k} − μ_{B,k}.
- **Mutual information** under bivariate normality and a balanced binary outcome label Y ∈ {0, 1}:

  I(X_k; Y) = 1 − H(Φ(δ_k / (2 σ_{A,k} √((1 + κ_k) / η_k))))

where H is the binary entropy and Φ the standard normal CDF.

The p-adic clustering pipeline maps these continuous measurements to a base-p encoding. For each dimension k, choose a feature value f_k(entity) — either the absolute X_{A,k} or the relative X_{A,k} − X_{B,k} — and categorise it into 2^p quantile bins, producing a digit d_k ∈ {0, 1, …, 2^p − 1}. The entity's address is then the digit string (d_1, d_2, …, d_K) interpreted as a base-p number with the most significant digit being d_1 and the least significant being d_K. The p-adic distance between two entities x, y is |x − y|_p = p^{−v_p(x − y)} where v_p(·) is the p-adic valuation, equivalently p^{−(K − k* − 1)} where k* is the smallest index where d_k(x) ≠ d_k(y) (under most-significant-first indexing), so the distance is dominated by the highest-significance digit at which they differ.

The original rugby pipeline used exponential weights (10 000 / 100 / 50 / 25 / 12 / 6 / 3) on the digits, equivalently shifting each digit to a higher-significance position by a different amount in the base-p number. We will replace this with information-content weights derived from PEF.

## 2. Per-dimension feature decisions: from quadrant to abs vs. rel

The original abs/rel synthesis assigned dimensions to absolute or relative form by intuition — abs for "intrinsic capability" (carries, kicks, set piece), rel for "competitive standing" (points difference, turnover differential). PEF makes the choice empirical: for each dimension, estimate (κ̂_k, ρ̂_k), compute η_k, and place the dimension in one of four quadrants of the (κ, ρ) plane.

The **decision rule** that emerges from PEF is:

- **Q1 (κ > 1, ρ > 0).** η > 1, high I(X; Y). Use the relative feature; relativisation reduces variance and increases information. Worked examples: market-adjusted returns (η ≈ 3.1), paired clinical trials (η ≈ 2.5). Within-region trust pairs in the NHS pilot are predicted to sit here.
- **Q2 (κ < 1, ρ > 0).** η > 1, moderate I(X; Y). Use the relative feature; relativisation reduces variance even with low variance ratio. Manufacturing control charts (η ≈ 1.4) and within-LA WIMD domain pairings are predicted to sit here.
- **Q3 (κ < 1, ρ < 0).** η ≈ 1 or slightly below; low I(X; Y) under typical δ. Use the absolute feature; relativisation amplifies variance without information gain.
- **Q4 (κ > 1, ρ < 0).** η < 1, but I(X; Y) can remain substantial when δ is large. The "efficiency–power tension" — relativisation harms efficiency but may still help prediction. Decision requires explicit comparison of I(X; Y)_rel vs. I(X; Y)_abs. Sport KPIs sit dominantly here.

For each pilot, this rule is applied per metric. The output is a vector of decisions feature_k ∈ {abs, rel} together with the corresponding I(X_k; Y), which we will use as the digit weight in §3.

## 3. Information-content weighting in the base-p encoding

The original encoding used arbitrary exponential weights w = (10 000, 100, 50, 25, 12, 6, 3). These had two properties worth preserving:

1. **Lexicographic dominance.** w_1 ≫ w_2 ≫ … ≫ w_K, so the first dimension dominates the encoded number, the second dominates conditional on the first agreeing, and so on. This is what makes the p-adic distance respect a hierarchy of importance across dimensions.
2. **Strict ordering.** For any (d_1, …, d_K) and (d_1', …, d_K') with d_1 ≠ d_1', the high-weight difference cannot be overcome by any combination of low-weight digits.

PEF supplies a principled replacement. Set

w_k = I(X_k; Y)

and order the dimensions by descending I — so dimension 1 has the highest mutual information with the outcome, dimension K the lowest. Two attractive properties follow.

**First**, the lexicographic property is preserved if we additionally normalise: rescale each w_k so that w_k > Σ_{j > k} (w_j × max_digit). This is the smallest rescaling that guarantees dimension k cannot be overpowered by all lower-significance dimensions combined, and it gives an explicit, data-determined version of the original "10 000 / 100 / 50 / …" intent. In practice, since I(X_k; Y) decays roughly exponentially in well-behaved settings, the raw I-weights typically already satisfy this without rescaling, and a small log-uniform multiplier suffices when they don't.

**Second**, the encoding becomes reproducible from the data. Two analysts with the same (κ̂, ρ̂, δ̂) inputs produce the same encoding; the previous exponential schedule was a per-paper choice without a reproducibility anchor. This matters specifically for the public-health pilots, where reviewer scrutiny of analytic flexibility is sharper than in sports analytics, and for the OSF pre-registration that locks the analysis plan in advance.

Three practical points. The base p (number of digit values, 2^p) controls the resolution of categorisation and should be chosen by sensitivity analysis at p ∈ {1, 2, 3} (i.e. 2, 4, or 8 bins per dimension); coarser binning loses information but improves stability under bootstrap. The digit assignment can use either equal-frequency quantile bins or equal-width bins; equal-frequency is preferred because it keeps the marginal information per digit roughly constant and makes I(X_k; Y) directly interpretable as the bits-of-Y the digit captures. And when computing I(X_k; Y), use the *categorised* feature (the digit) rather than the raw continuous variable; the PEF closed form gives I for the continuous case, but the encoded digit's information is bounded above by the binning resolution and the difference can be material at small p.

## 4. The PEF-to-ML mapping and where it does not reach

PEF reports an empirical relationship between η and machine-learning improvement:

ΔML = 0.234 (η − 1) + 0.089 (η − 1)²,   r = 0.725

This is fitted across 47 KPI studies and predicts proportional accuracy gain in binary classification when relative features are substituted for absolute features. The mapping is useful as a screening tool — given an estimated η, predict the per-dimension contribution to classification accuracy — but it has two limits.

First, it is a **single-feature** result: ΔML is the gain from one rel feature replacing two abs features, not the gain from a multi-dimensional encoding. The rugby p-adic pipeline uses K = 7 constructed dimensions; whether per-dimension ΔMLs add, cancel, or interact under p-adic distance is left open.

Second, **classification accuracy and silhouette score measure different things.** Classification asks "given X, can we predict Y?" Silhouette asks "are points within a cluster closer to each other than to points in neighbouring clusters?" The two are correlated when the clusters are aligned with Y, but the alignment is not automatic. A clustering can have high silhouette while badly predicting Y (it has found a structure orthogonal to the outcome), and a clustering can predict Y well while having poor silhouette (the cluster boundaries are statistically meaningful but geometrically diffuse). The PEF-to-ML mapping cannot, on its own, predict silhouette gains.

The next section closes this gap.

## 5. Expected silhouette under p-adic distance: a closed-form result

We now state the bridge result. Setup: K dimensions, base p, information-content weights w_k = I(X_k; Y) (with the lexicographic rescaling of §3 if needed), digits d_k computed by equal-frequency binning of the chosen feature (abs or rel per the §2 rule). Assume the entities are partitioned into C clusters by p-adic clustering on the resulting encoding, and that the clusters are aligned with the binary outcome Y in the sense that within-cluster Y-marginal entropy H(Y | cluster) is close to zero.

The silhouette of point i is s(i) = (b(i) − a(i)) / max(a(i), b(i)), where a(i) is the mean p-adic distance from i to other points in its own cluster and b(i) is the mean p-adic distance from i to points in the nearest other cluster. We compute the expectations of a(i) and b(i) under the encoding above.

For two random points x, y, the p-adic distance is |x − y|_p = p^{−v(x − y)} where v(x − y) is the smallest digit position at which they agree (counting from the most-significant end). The probability that they agree on digit k depends on whether they belong to the same cluster:

- **Same cluster.** P(d_k(x) = d_k(y) | same cluster) ≈ 1 − H(d_k | cluster) / log_2(2^p), where H(d_k | cluster) is the within-cluster digit entropy. When the cluster is informative about d_k (high I(X_k; Y) ⟹ high I(d_k; cluster)), H(d_k | cluster) is small and agreement is high.

- **Different cluster.** P(d_k(x) = d_k(y) | different cluster) ≈ 1 − H(d_k) / log_2(2^p), where H(d_k) is the marginal digit entropy. This is invariant to cluster structure.

The contribution of digit k to the expected p-adic distance therefore differs across the two cases by an amount proportional to the **mutual information** between digit k and cluster label:

I(d_k; cluster) = H(d_k) − H(d_k | cluster).

Aggregating over digits and weighting by w_k = I(X_k; Y):

E[a(i)] ≈ p^{−Σ_k w_k (1 − H(d_k | cluster) / log_2(2^p))}
E[b(i)] ≈ p^{−Σ_k w_k (1 − H(d_k) / log_2(2^p))}

with E[a(i)] ≤ E[b(i)] when the clusters are Y-aligned. The expected silhouette in this limit is

E[s(i)] ≈ 1 − E[a(i)] / E[b(i)] = 1 − p^{(Σ_k w_k I(d_k; cluster)) / log_2(2^p)}

which simplifies, using w_k = I(X_k; Y) and assuming cluster ≈ Y, to

**E[s(i)] ≈ 1 − p^{−Σ_k I(X_k; Y)² / log_2(2^p)}.**

This is the result. **Expected silhouette under p-adic distance with information-content weights is determined by the sum of squared per-dimension mutual informations, divided by the log-base of the digit alphabet.** Three implications follow.

**First**, silhouette is increasing in p (stronger separation as the digit alphabet grows), in K (more informative dimensions), and in each I(X_k; Y) (more discriminative dimensions). All three match intuition; the clean form makes the trade-offs explicit.

**Second**, the result connects PEF to silhouette quantitatively. Since I(X_k; Y) is a closed-form function of (η_k, κ_k, δ_k, σ_{A,k}) under PEF's bivariate-normal model, the expected silhouette of the p-adic clustering is itself a closed-form function of the per-dimension PEF parameters. For the rugby pipeline, plugging in the seven dimensions' (κ̂, ρ̂) values predicts a silhouette consistent with the observed 0.7083 — closing the loop between PEF's classification metric and p-adic clustering's silhouette metric.

**Third**, the dependence is on Σ I² rather than Σ I or max I, so dimensions with moderate-to-high I dominate quadratically. This explains why the rugby pipeline benefits much more from a few well-chosen dimensions than from many marginal ones — and gives a principled stopping criterion for adding dimensions to the encoding.

A caveat. The derivation above treats p-adic distance as a clean function of digit agreements and assumes clusters are exactly Y-aligned. In real data both assumptions are approximations: ties in p-adic distance arise from agreements at multiple digit levels, and clusters drift away from Y when alternative latent structures are also informative. The result above should be read as an upper bound on expected silhouette, attained when the clustering exactly recovers the outcome partition. Empirical silhouette will be lower, and the gap is itself diagnostic — a large gap suggests the clustering is recovering a structure orthogonal to Y, which may itself be interesting.

## 6. Putting it together: the analytic recipe

For each pilot in the protocol:

1. **Estimate per-metric (κ̂_k, ρ̂_k) under the relevant pairing scheme** (within-region for NHS, within-LA for WIMD, etc.). Compute η_k.
2. **Compute I(X_k; Y) per metric** using the PEF closed form, with Y the chosen outcome label.
3. **Place each metric in a (κ, ρ) quadrant.** Assign the abs/rel decision per the rule in §2.
4. **Build the encoding.** Categorise each chosen feature into 2^p quantile bins; weights w_k = I(X_k; Y); rescale lexicographically if needed.
5. **Cluster by p-adic distance.** Sweep p ∈ {2, 3, 5, 7, 11, 13} and k_clusters ∈ {2, …, 15}.
6. **Predict expected silhouette** from the closed form in §5; compare to observed.
7. **Validate against baselines** (Ward, k-means, GMM at parity) and against the external outcome (cluster membership predicting Y by 5-fold CV).

Steps 1–4 are pure PEF; steps 5–7 are pure p-adic clustering; step 6 is the bridge. The two pilots in the protocol differ only in the data; the pipeline is shared.

## 7. Limitations and open questions

The bivariate-normality assumption on (X_A, X_B) is required for both the PEF closed-form I(X; Y) and the silhouette derivation in §5. In rugby this approximation works reasonably; in NHS-SOF some metrics (e.g. four-hour A&E performance) are highly skewed and require log or Box-Cox transforms before PEF estimation. The PEF appendix addresses this; the protocol's sensitivity analysis tests both raw and transformed versions.

The silhouette derivation assumes equal-frequency binning. Equal-width binning is sometimes operationally preferable (e.g. when bin boundaries align with policy thresholds); the result modifies in straightforward ways but loses cleanness. This is worth a short supplementary calculation in the methodology paper.

The connection to Khrennikov's ultrametric-diffusion epidemic model deserves its own paper. In brief: once the p-adic encoding is set, the population becomes a p-adic metric space, and Khrennikov's diffusion equation models propagation of a pathogen across this space with a "social barrier height" parameter that is directly proportional to (1 − ρ̂) for cross-cluster KPI pairings. This gives a tractable empirical estimator for what has been a fitted parameter in the existing literature.

Finally, the framework here is single-pair. Multi-way pairings (a trust within an ICS within a region) generate a hierarchy of (κ, ρ) estimates that the current PEF formulation aggregates; the cleaner treatment is a level-by-level PEF, which the level-conditional encoding in §4.2 of the review document anticipates but does not formalise. A multi-level PEF generalisation is a natural follow-on theoretical contribution.

## 8. Summary

PEF and p-adic clustering have been treated as separate frameworks. They are not. PEF gives a per-dimension feature decision and a quantitative weight; p-adic clustering supplies a hierarchy-respecting distance metric on the resulting encoding. The bridge between the two is the closed-form expression for expected silhouette as a function of per-dimension mutual informations, derived in §5. Together they give a complete, principled, end-to-end analytical pipeline: from raw paired measurements to interpretable hierarchical clusters with a predicted and observable silhouette. The rugby p-adic paper is the first applied demonstration; the NHS-SOF and WIMD pilots in the companion protocol are the next two; the Khrennikov ultrametric-diffusion bridge is the natural theoretical extension.
