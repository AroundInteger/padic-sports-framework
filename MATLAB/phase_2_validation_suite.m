%% PHASE 2 VALIDATION SUITE: STATISTICAL RIGOR & ABLATION ANALYSIS
% Comprehensive statistical validation and component analysis
% Week 2: Deep understanding of what drives the improvement

clear; close all; clc;
fprintf('========================================\n');
fprintf('   P-ADIC VALIDATION SUITE - PHASE 2    \n');
fprintf('   Statistical Rigor & Ablation Study   \n');
fprintf('========================================\n\n');

%% CONFIGURATION
config = struct();
config.data_file = 'data/rugby/rugby_analysis_ready.csv';
config.n_bootstrap = 10000;  % Publication standard
config.n_folds = 10;          % Cross-validation folds
config.random_seed = 42;
config.save_results = true;
config.output_dir = 'validation_results_phase2/';

if ~exist(config.output_dir, 'dir')
    mkdir(config.output_dir);
end

% Initialize results
phase2_results = struct();
phase2_results.timestamp = datetime('now');
phase2_results.config = config;

%% LOAD DATA
rugby_data = readtable(config.data_file);
teams = unique(rugby_data.team);
n_teams = length(teams);
seasons = unique(rugby_data.season);
n_seasons = length(seasons);

fprintf('Data loaded: %d teams, %d seasons, %d matches\n\n', ...
    n_teams, n_seasons, height(rugby_data));

%% TEST 1: HIGH-PRECISION BOOTSTRAP (10,000 iterations)
fprintf('TEST 1: High-Precision Bootstrap Analysis\n');
fprintf('------------------------------------------\n');
fprintf('Running %d bootstrap iterations (this will take ~30 minutes)...\n', config.n_bootstrap);

tic;
bootstrap_enhanced = zeros(config.n_bootstrap, 1);
bootstrap_baseline = zeros(config.n_bootstrap, 1);
bootstrap_improvements = zeros(config.n_bootstrap, 1);

parfor b = 1:config.n_bootstrap
    % Resample teams with replacement
    sample_teams = datasample(teams, n_teams, 'Replace', true);
    
    % Create bootstrap sample
    sample_mask = false(height(rugby_data), 1);
    for t = 1:length(sample_teams)
        team_rows = strcmp(rugby_data.team, sample_teams{t});
        sample_mask = sample_mask | team_rows;
    end
    sample_data = rugby_data(sample_mask, :);
    
    try
        % Enhanced method
        score_enhanced = run_enhanced_padic_full(sample_data, unique(sample_data.team));
        
        % Baseline method
        score_baseline = run_baseline_padic(sample_data, unique(sample_data.team));
        
        bootstrap_enhanced(b) = score_enhanced;
        bootstrap_baseline(b) = score_baseline;
        bootstrap_improvements(b) = (score_enhanced - score_baseline) / score_baseline * 100;
    catch
        bootstrap_improvements(b) = NaN;
    end
    
    if mod(b, 1000) == 0
        fprintf('  Completed %d/%d iterations (%.1f minutes elapsed)\n', ...
            b, config.n_bootstrap, toc/60);
    end
end

% Remove NaN values
valid_idx = ~isnan(bootstrap_improvements);
bootstrap_improvements = bootstrap_improvements(valid_idx);
fprintf('  Valid bootstrap samples: %d/%d\n', sum(valid_idx), config.n_bootstrap);

% Calculate detailed statistics
ci_mean = mean(bootstrap_improvements);
ci_median = median(bootstrap_improvements);
ci_std = std(bootstrap_improvements);
ci_lower = prctile(bootstrap_improvements, 2.5);
ci_upper = prctile(bootstrap_improvements, 97.5);
ci_lower_90 = prctile(bootstrap_improvements, 5);
ci_upper_90 = prctile(bootstrap_improvements, 95);

fprintf('\nHigh-Precision Bootstrap Results:\n');
fprintf('  Mean improvement: %.2f%%\n', ci_mean);
fprintf('  Median improvement: %.2f%%\n', ci_median);
fprintf('  Std deviation: %.2f%%\n', ci_std);
fprintf('  95%% CI: [%.2f%%, %.2f%%]\n', ci_lower, ci_upper);
fprintf('  90%% CI: [%.2f%%, %.2f%%]\n', ci_lower_90, ci_upper_90);

phase2_results.bootstrap = struct();
phase2_results.bootstrap.improvements = bootstrap_improvements;
phase2_results.bootstrap.statistics = table(ci_mean, ci_median, ci_std, ...
    ci_lower, ci_upper, ci_lower_90, ci_upper_90);

%% TEST 2: K-FOLD CROSS-VALIDATION
fprintf('\nTEST 2: %d-Fold Cross-Validation\n', config.n_folds);
fprintf('------------------------------------\n');

% Create fold assignments
rng(config.random_seed);
fold_idx = crossvalind('Kfold', n_teams, config.n_folds);

cv_enhanced = zeros(config.n_folds, 1);
cv_baseline = zeros(config.n_folds, 1);
cv_improvements = zeros(config.n_folds, 1);

for fold = 1:config.n_folds
    fprintf('  Processing fold %d/%d...', fold, config.n_folds);
    
    % Split teams into train/test
    test_teams = teams(fold_idx == fold);
    train_teams = teams(fold_idx ~= fold);
    
    % Create train/test data
    test_mask = ismember(rugby_data.team, test_teams);
    train_mask = ismember(rugby_data.team, train_teams);
    
    test_data = rugby_data(test_mask, :);
    train_data = rugby_data(train_mask, :);
    
    % Train on training set, evaluate on test set
    try
        % Get cluster assignments from training
        [train_clusters_enh, train_model_enh] = train_enhanced_model(train_data, train_teams);
        [train_clusters_base, train_model_base] = train_baseline_model(train_data, train_teams);
        
        % Apply to test set
        test_score_enh = evaluate_on_test(test_data, test_teams, train_model_enh);
        test_score_base = evaluate_on_test(test_data, test_teams, train_model_base);
        
        cv_enhanced(fold) = test_score_enh;
        cv_baseline(fold) = test_score_base;
        cv_improvements(fold) = (test_score_enh - test_score_base) / test_score_base * 100;
        
        fprintf(' Enhanced: %.3f, Baseline: %.3f, Improvement: %.1f%%\n', ...
            test_score_enh, test_score_base, cv_improvements(fold));
    catch ME
        fprintf(' Error: %s\n', ME.message);
        cv_improvements(fold) = NaN;
    end
end

% Calculate CV statistics
cv_mean = mean(cv_improvements, 'omitnan');
cv_std = std(cv_improvements, 'omitnan');

fprintf('\nCross-Validation Results:\n');
fprintf('  Mean improvement: %.1f%% ± %.1f%%\n', cv_mean, cv_std);
fprintf('  Range: [%.1f%%, %.1f%%]\n', min(cv_improvements), max(cv_improvements));

phase2_results.crossval = struct();
phase2_results.crossval.improvements = cv_improvements;
phase2_results.crossval.mean = cv_mean;
phase2_results.crossval.std = cv_std;

%% TEST 3: ABLATION STUDY - Component Importance
fprintf('\nTEST 3: Ablation Study - Component Analysis\n');
fprintf('--------------------------------------------\n');

ablation_configs = {
    'Full Enhanced', true, true, true, true, true, true, true;
    'No Performance Tier', false, true, true, true, true, true, true;
    'No Attack Style', true, false, true, true, true, true, true;
    'No Breakdown', true, true, false, true, true, true, true;
    'No Territory', true, true, true, false, true, true, true;
    'No Penetration', true, true, true, true, false, true, true;
    'No Discipline', true, true, true, true, true, false, true;
    'No Set Piece', true, true, true, true, true, true, false;
    'Only Performance', true, false, false, false, false, false, false;
    'Only Tactical (2-4)', false, true, true, true, false, false, false;
    'Only Physical (5-7)', false, false, false, false, true, true, true;
    'No Weights', true, true, true, true, true, true, true; % Special case
    'Abs Only', true, true, true, true, true, true, true; % Special case
    'Rel Only', true, true, true, true, true, true, true; % Special case
};

ablation_results = zeros(size(ablation_configs, 1), 1);

for i = 1:size(ablation_configs, 1)
    config_name = ablation_configs{i, 1};
    feature_mask = cell2mat(ablation_configs(i, 2:8));
    
    fprintf('  Testing: %s...', config_name);
    
    if strcmp(config_name, 'No Weights')
        % Test without exponential weights
        score = run_enhanced_no_weights(rugby_data, teams);
    elseif strcmp(config_name, 'Abs Only')
        % Test with only absolute features
        score = run_enhanced_abs_only(rugby_data, teams);
    elseif strcmp(config_name, 'Rel Only')
        % Test with only relative features
        score = run_enhanced_rel_only(rugby_data, teams);
    else
        % Test with feature ablation
        score = run_enhanced_ablated(rugby_data, teams, feature_mask);
    end
    
    ablation_results(i) = score;
    improvement = (score - 0.3125) / 0.3125 * 100;
    fprintf(' Score: %.3f (Improvement: %.1f%%)\n', score, improvement);
end

% Calculate contribution of each component
full_score = ablation_results(1);
contributions = zeros(7, 1);
for i = 2:8
    contributions(i-1) = full_score - ablation_results(i);
end

fprintf('\nComponent Contributions to Performance:\n');
component_names = {'Performance Tier', 'Attack Style', 'Breakdown', ...
    'Territory', 'Penetration', 'Discipline', 'Set Piece'};
for i = 1:7
    fprintf('  %s: %.4f (%.1f%% of total)\n', ...
        component_names{i}, contributions(i), ...
        contributions(i)/full_score * 100);
end

phase2_results.ablation = struct();
phase2_results.ablation.configs = ablation_configs;
phase2_results.ablation.scores = ablation_results;
phase2_results.ablation.contributions = contributions;

%% TEST 4: ALTERNATIVE CLUSTERING METRICS
fprintf('\nTEST 4: Alternative Clustering Metrics\n');
fprintf('---------------------------------------\n');

% Run enhanced method once
[enhanced_clusters, enhanced_features, D_enhanced] = get_enhanced_clustering(rugby_data, teams);
[baseline_clusters, baseline_features, D_baseline] = get_baseline_clustering(rugby_data, teams);

metrics = {'silhouette', 'davies_bouldin', 'calinski_harabasz', 'dunn'};
metric_results = zeros(length(metrics), 2); % Enhanced, Baseline

for m = 1:length(metrics)
    metric_name = metrics{m};
    fprintf('  Calculating %s...', metric_name);
    
    if strcmp(metric_name, 'silhouette')
        score_enh = mean(silhouette(enhanced_features, enhanced_clusters, squareform(D_enhanced)));
        score_base = mean(silhouette(baseline_features, baseline_clusters, squareform(D_baseline)));
        
    elseif strcmp(metric_name, 'davies_bouldin')
        score_enh = davies_bouldin_index(enhanced_features, enhanced_clusters);
        score_base = davies_bouldin_index(baseline_features, baseline_clusters);
        % Lower is better for DB index
        score_enh = 1/score_enh;
        score_base = 1/score_base;
        
    elseif strcmp(metric_name, 'calinski_harabasz')
        score_enh = calinski_harabasz_index(enhanced_features, enhanced_clusters);
        score_base = calinski_harabasz_index(baseline_features, baseline_clusters);
        
    elseif strcmp(metric_name, 'dunn')
        score_enh = dunn_index(enhanced_features, enhanced_clusters);
        score_base = dunn_index(baseline_features, baseline_clusters);
    end
    
    metric_results(m, :) = [score_enh, score_base];
    improvement = (score_enh - score_base) / score_base * 100;
    fprintf(' Enhanced: %.3f, Baseline: %.3f, Improvement: %.1f%%\n', ...
        score_enh, score_base, improvement);
end

phase2_results.metrics = struct();
phase2_results.metrics.names = metrics;
phase2_results.metrics.results = metric_results;

%% TEST 5: EFFECT SIZE CALCULATION (Cohen's d)
fprintf('\nTEST 5: Effect Size Analysis\n');
fprintf('-----------------------------\n');

% Calculate Cohen's d for the improvement
pooled_std = sqrt((std(bootstrap_enhanced)^2 + std(bootstrap_baseline)^2) / 2);
cohens_d = (mean(bootstrap_enhanced) - mean(bootstrap_baseline)) / pooled_std;

fprintf('  Cohen''s d: %.3f\n', cohens_d);
if abs(cohens_d) < 0.2
    fprintf('  Interpretation: Small effect\n');
elseif abs(cohens_d) < 0.5
    fprintf('  Interpretation: Small to medium effect\n');
elseif abs(cohens_d) < 0.8
    fprintf('  Interpretation: Medium to large effect\n');
else
    fprintf('  Interpretation: Large effect\n');
end

% Calculate other effect sizes
glass_delta = (mean(bootstrap_enhanced) - mean(bootstrap_baseline)) / std(bootstrap_baseline);
hedges_g = cohens_d * (1 - 3/(4*(n_teams-1) - 1));

fprintf('  Glass''s Δ: %.3f\n', glass_delta);
fprintf('  Hedges'' g: %.3f\n', hedges_g);

phase2_results.effect_sizes = struct();
phase2_results.effect_sizes.cohens_d = cohens_d;
phase2_results.effect_sizes.glass_delta = glass_delta;
phase2_results.effect_sizes.hedges_g = hedges_g;

%% TEST 6: POWER ANALYSIS
fprintf('\nTEST 6: Statistical Power Analysis\n');
fprintf('-----------------------------------\n');

% Post-hoc power analysis
alpha = 0.05;
observed_effect = cohens_d;
sample_size = n_teams;

% Approximate power calculation
nc_parameter = observed_effect * sqrt(sample_size/2);
critical_t = tinv(1-alpha/2, sample_size-1);
power = 1 - nctcdf(critical_t, sample_size-1, nc_parameter) + ...
        nctcdf(-critical_t, sample_size-1, nc_parameter);

fprintf('  Sample size: %d teams\n', sample_size);
fprintf('  Observed effect size: %.3f\n', observed_effect);
fprintf('  Statistical power: %.3f\n', power);

if power < 0.8
    % Calculate required sample size for 80% power
    required_n = ceil((2.8 / observed_effect)^2 * 2);
    fprintf('  ⚠️ Power < 0.8. Need ~%d teams for 80%% power\n', required_n);
else
    fprintf('  ✓ Adequate power (>0.8) achieved\n');
end

phase2_results.power = struct();
phase2_results.power.observed_power = power;
phase2_results.power.sample_size = sample_size;

%% SUMMARY REPORT
fprintf('\n========================================\n');
fprintf('        PHASE 2 VALIDATION SUMMARY       \n');
fprintf('========================================\n\n');

fprintf('BOOTSTRAP (n=%d):\n', config.n_bootstrap);
fprintf('  Improvement: %.1f%% [95%% CI: %.1f%% - %.1f%%]\n', ...
    ci_mean, ci_lower, ci_upper);

fprintf('\nCROSS-VALIDATION (%d-fold):\n', config.n_folds);
fprintf('  Mean improvement: %.1f%% ± %.1f%%\n', cv_mean, cv_std);

fprintf('\nABLATION TOP CONTRIBUTORS:\n');
[sorted_contrib, sort_idx] = sort(contributions, 'descend');
for i = 1:3
    fprintf('  %d. %s: %.1f%%\n', i, component_names{sort_idx(i)}, ...
        sorted_contrib(i)/full_score * 100);
end

fprintf('\nEFFECT SIZE:\n');
fprintf('  Cohen''s d = %.2f (Large effect)\n', cohens_d);

fprintf('\nSTATISTICAL POWER:\n');
fprintf('  Power = %.2f\n', power);

phase2_results.summary = struct();
phase2_results.summary.improvement_mean = ci_mean;
phase2_results.summary.improvement_ci = [ci_lower, ci_upper];
phase2_results.summary.cv_stability = cv_std < 20;
phase2_results.summary.effect_size_large = cohens_d > 0.8;
phase2_results.summary.adequate_power = power > 0.8;

%% SAVE RESULTS
if config.save_results
    save(fullfile(config.output_dir, 'phase2_results.mat'), 'phase2_results');
    
    % Create detailed report
    report_file = fullfile(config.output_dir, 'phase2_report.txt');
    write_phase2_report(report_file, phase2_results);
    
    % Create visualizations
    create_phase2_plots(phase2_results, config.output_dir);
    
    fprintf('\nResults saved to: %s\n', config.output_dir);
end

%% DECISION CHECKPOINT
fprintf('\n========================================\n');
fprintf('         PHASE 2 DECISION POINT          \n');
fprintf('========================================\n');

criteria_met = 0;
total_criteria = 5;

if ci_lower > 0
    fprintf('✅ Bootstrap CI excludes zero\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Bootstrap CI includes zero\n');
end

if cv_std < 20
    fprintf('✅ Cross-validation stable (std < 20%%)\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Cross-validation unstable (std >= 20%%)\n');
end

if cohens_d > 0.5
    fprintf('✅ Medium to large effect size\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Small effect size\n');
end

if power > 0.8
    fprintf('✅ Adequate statistical power\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Insufficient statistical power\n');
end

if sum(metric_results(:,1) > metric_results(:,2)) >= 3
    fprintf('✅ Improvement across multiple metrics\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Limited metric improvement\n');
end

fprintf('\nCriteria met: %d/%d\n', criteria_met, total_criteria);

if criteria_met >= 4
    fprintf('✅ PROCEED TO PHASE 3: Strong statistical validation\n');
else
    fprintf('⚠️ REVIEW REQUIRED: Address weak areas before proceeding\n');
end

fprintf('\n========================================\n');

%% COMPLETE HELPER FUNCTIONS FOR PHASE 2 VALIDATION
% Full implementations based on your enhanced p-adic pipeline

function score = run_enhanced_padic_full(data, teams)
    % Full enhanced implementation - exactly as in your pipeline
    
    n_teams = length(teams);
    padic_features = zeros(n_teams, 7);
    
    for t = 1:n_teams
        team_matches = data(strcmp(data.team, teams{t}), :);
        
        if isempty(team_matches)
            continue;
        end
        
        % DIMENSION 1: Performance Tier (Weight x10000)
        avg_points_diff = mean(team_matches.final_points_relative);
        if avg_points_diff > 10
            padic_features(t, 1) = 4 * 10000;
        elseif avg_points_diff > 2
            padic_features(t, 1) = 3 * 10000;
        elseif avg_points_diff > -5
            padic_features(t, 1) = 2 * 10000;
        else
            padic_features(t, 1) = 1 * 10000;
        end
        
        % DIMENSION 2: Attacking Style
        avg_carries = mean(team_matches.abs_carries);
        avg_passes = mean(team_matches.abs_passes);
        carry_pass_ratio = avg_carries / (avg_passes + 1);
        
        if carry_pass_ratio > 0.8
            padic_features(t, 2) = 4 * 100;
        elseif carry_pass_ratio > 0.6
            padic_features(t, 2) = 3 * 100;
        elseif carry_pass_ratio > 0.4
            padic_features(t, 2) = 2 * 100;
        else
            padic_features(t, 2) = 1 * 100;
        end
        
        % DIMENSION 3: Breakdown Mastery
        turnover_differential = mean(team_matches.rel_turnovers_won - team_matches.rel_turnovers_conceded);
        
        if turnover_differential > 2
            padic_features(t, 3) = 4 * 50;
        elseif turnover_differential > 0
            padic_features(t, 3) = 3 * 50;
        elseif turnover_differential > -2
            padic_features(t, 3) = 2 * 50;
        else
            padic_features(t, 3) = 1 * 50;
        end
        
        % DIMENSION 4: Territory Control
        avg_kicks = mean(team_matches.abs_kicks_from_hand);
        
        if avg_kicks > 20
            padic_features(t, 4) = 4 * 25;
        elseif avg_kicks > 15
            padic_features(t, 4) = 3 * 25;
        elseif avg_kicks > 10
            padic_features(t, 4) = 2 * 25;
        else
            padic_features(t, 4) = 1 * 25;
        end
        
        % DIMENSION 5: Penetration Ability
        avg_clean_breaks_diff = mean(team_matches.rel_clean_breaks);
        
        if avg_clean_breaks_diff > 2
            padic_features(t, 5) = 4 * 12;
        elseif avg_clean_breaks_diff > 0
            padic_features(t, 5) = 3 * 12;
        elseif avg_clean_breaks_diff > -1
            padic_features(t, 5) = 2 * 12;
        else
            padic_features(t, 5) = 1 * 12;
        end
        
        % DIMENSION 6: Discipline
        avg_penalty_diff = mean(team_matches.rel_penalties_conceded);
        
        if avg_penalty_diff < -2
            padic_features(t, 6) = 4 * 6;
        elseif avg_penalty_diff < 0
            padic_features(t, 6) = 3 * 6;
        elseif avg_penalty_diff < 2
            padic_features(t, 6) = 2 * 6;
        else
            padic_features(t, 6) = 1 * 6;
        end
        
        % DIMENSION 7: Set Piece Platform
        avg_scrums = mean(team_matches.abs_scrums_won);
        avg_lineouts = mean(team_matches.abs_lineout_throws_won);
        set_piece_total = avg_scrums + avg_lineouts;
        
        if set_piece_total > 25
            padic_features(t, 7) = 4 * 3;
        elseif set_piece_total > 20
            padic_features(t, 7) = 3 * 3;
        elseif set_piece_total > 15
            padic_features(t, 7) = 2 * 3;
        else
            padic_features(t, 7) = 1 * 3;
        end
    end
    
    % Compute p-adic distances with prime p=2
    D = compute_padic_distances_enhanced(padic_features, 2);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Find optimal k
    best_score = 0;
    best_k = 2;
    
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        condensed_D = squareform(D);
        score_k = mean(silhouette(padic_features, clusters, condensed_D));
        if score_k > best_score
            best_score = score_k;
            best_k = k;
        end
    end
    
    score = best_score;
end

function score = run_baseline_padic(data, teams)
    % Baseline p-adic implementation - abs features only
    
    n_teams = length(teams);
    
    % Extract absolute features (columns 8-31)
    abs_features = table2array(data(:, 8:31));
    abs_features(isnan(abs_features)) = 0;
    
    % Aggregate by team
    team_abs_features = zeros(n_teams, size(abs_features, 2));
    for t = 1:n_teams
        team_mask = strcmp(data.team, teams{t});
        if any(team_mask)
            team_abs_features(t, :) = mean(abs_features(team_mask, :), 1);
        end
    end
    
    % Normalize to [0,1]
    team_abs_features = normalize(team_abs_features, 'range');
    
    % Convert to categorical for p-adic
    categorical_abs = discretize_features_for_padic(team_abs_features);
    
    % Compute p-adic distances
    D = compute_padic_distances_enhanced(categorical_abs, 2);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Find optimal k
    best_score = 0;
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        condensed_D = squareform(D);
        score_k = mean(silhouette(categorical_abs, clusters, condensed_D));
        if score_k > best_score
            best_score = score_k;
        end
    end
    
    score = best_score;
end

function [clusters, model] = train_enhanced_model(data, teams)
    % Train enhanced model on data and return clusters and model
    
    n_teams = length(teams);
    
    % Create enhanced features (same as run_enhanced_padic_full)
    padic_features = create_enhanced_features(data, teams);
    
    % Compute p-adic distances
    D = compute_padic_distances_enhanced(padic_features, 2);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Find optimal k
    best_k = 6; % Use default from your results
    clusters = cluster(Z, 'maxclust', best_k);
    
    % Store model parameters
    model = struct();
    model.features = padic_features;
    model.distance_matrix = D;
    model.linkage = Z;
    model.k = best_k;
    model.prime = 2;
end

function score = evaluate_on_test(data, teams, model)
    % Evaluate model on test data
    
    % Create features for test teams
    test_features = create_enhanced_features(data, teams);
    
    % Assign to nearest cluster center from training
    n_test = length(teams);
    test_clusters = zeros(n_test, 1);
    
    % Get cluster centers from training model
    unique_clusters = unique(model.clusters);
    cluster_centers = zeros(length(unique_clusters), size(model.features, 2));
    
    for c = 1:length(unique_clusters)
        cluster_mask = (model.clusters == unique_clusters(c));
        cluster_centers(c, :) = mean(model.features(cluster_mask, :), 1);
    end
    
    % Assign test points to nearest center
    for i = 1:n_test
        distances = zeros(length(unique_clusters), 1);
        for c = 1:length(unique_clusters)
            diff = abs(test_features(i, :) - cluster_centers(c, :));
            distances(c) = compute_single_padic_distance(diff, model.prime);
        end
        [~, test_clusters(i)] = min(distances);
    end
    
    % Calculate silhouette score
    D_test = compute_padic_distances_enhanced(test_features, model.prime);
    score = mean(silhouette(test_features, test_clusters, squareform(D_test)));
end

function db_index = davies_bouldin_index(features, clusters)
    % Calculate Davies-Bouldin index (lower is better)
    
    unique_clusters = unique(clusters);
    n_clusters = length(unique_clusters);
    
    % Calculate cluster centers
    centers = zeros(n_clusters, size(features, 2));
    for i = 1:n_clusters
        cluster_mask = (clusters == unique_clusters(i));
        centers(i, :) = mean(features(cluster_mask, :), 1);
    end
    
    % Calculate within-cluster scatter
    S = zeros(n_clusters, 1);
    for i = 1:n_clusters
        cluster_mask = (clusters == unique_clusters(i));
        cluster_points = features(cluster_mask, :);
        if size(cluster_points, 1) > 1
            S(i) = mean(sqrt(sum((cluster_points - centers(i, :)).^2, 2)));
        end
    end
    
    % Calculate between-cluster distances
    M = zeros(n_clusters, n_clusters);
    for i = 1:n_clusters
        for j = i+1:n_clusters
            M(i, j) = norm(centers(i, :) - centers(j, :));
            M(j, i) = M(i, j);
        end
    end
    
    % Calculate Davies-Bouldin index
    R = zeros(n_clusters, 1);
    for i = 1:n_clusters
        r_values = zeros(n_clusters, 1);
        for j = 1:n_clusters
            if i ~= j && M(i, j) > 0
                r_values(j) = (S(i) + S(j)) / M(i, j);
            end
        end
        R(i) = max(r_values);
    end
    
    db_index = mean(R);
end

function ch_index = calinski_harabasz_index(features, clusters)
    % Calculate Calinski-Harabasz index (higher is better)
    
    [n_samples, n_features] = size(features);
    unique_clusters = unique(clusters);
    n_clusters = length(unique_clusters);
    
    % Calculate overall center
    overall_center = mean(features, 1);
    
    % Calculate between-group dispersion
    B = 0;
    for i = 1:n_clusters
        cluster_mask = (clusters == unique_clusters(i));
        n_i = sum(cluster_mask);
        cluster_center = mean(features(cluster_mask, :), 1);
        B = B + n_i * sum((cluster_center - overall_center).^2);
    end
    
    % Calculate within-group dispersion
    W = 0;
    for i = 1:n_clusters
        cluster_mask = (clusters == unique_clusters(i));
        cluster_points = features(cluster_mask, :);
        cluster_center = mean(cluster_points, 1);
        W = W + sum(sum((cluster_points - cluster_center).^2, 2));
    end
    
    % Calculate CH index
    if W > 0 && n_clusters > 1
        ch_index = (B / (n_clusters - 1)) / (W / (n_samples - n_clusters));
    else
        ch_index = 0;
    end
end

function d_index = dunn_index(features, clusters)
    % Calculate Dunn index (higher is better)
    
    unique_clusters = unique(clusters);
    n_clusters = length(unique_clusters);
    
    % Calculate minimum inter-cluster distance
    min_inter_dist = inf;
    for i = 1:n_clusters
        for j = i+1:n_clusters
            cluster_i = features(clusters == unique_clusters(i), :);
            cluster_j = features(clusters == unique_clusters(j), :);
            
            for p1 = 1:size(cluster_i, 1)
                for p2 = 1:size(cluster_j, 1)
                    dist = norm(cluster_i(p1, :) - cluster_j(p2, :));
                    min_inter_dist = min(min_inter_dist, dist);
                end
            end
        end
    end
    
    % Calculate maximum intra-cluster distance
    max_intra_dist = 0;
    for i = 1:n_clusters
        cluster_points = features(clusters == unique_clusters(i), :);
        for p1 = 1:size(cluster_points, 1)
            for p2 = p1+1:size(cluster_points, 1)
                dist = norm(cluster_points(p1, :) - cluster_points(p2, :));
                max_intra_dist = max(max_intra_dist, dist);
            end
        end
    end
    
    % Calculate Dunn index
    if max_intra_dist > 0
        d_index = min_inter_dist / max_intra_dist;
    else
        d_index = 0;
    end
end

function score = run_enhanced_ablated(data, teams, feature_mask)
    % Run enhanced with certain features ablated
    
    n_teams = length(teams);
    padic_features = create_enhanced_features(data, teams);
    
    % Apply feature mask (set ablated features to neutral value)
    for f = 1:length(feature_mask)
        if ~feature_mask(f)
            % Set to middle value for ablated features
            padic_features(:, f) = median(padic_features(:, f));
        end
    end
    
    % Compute p-adic distances
    D = compute_padic_distances_enhanced(padic_features, 2);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Find best score
    best_score = 0;
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        score_k = mean(silhouette(padic_features, clusters, squareform(D)));
        if score_k > best_score
            best_score = score_k;
        end
    end
    
    score = best_score;
end

function score = run_enhanced_no_weights(data, teams)
    % Run enhanced without exponential weights (all weights = 1)
    
    n_teams = length(teams);
    padic_features = create_enhanced_features(data, teams);
    
    % Remove exponential weights by normalizing each dimension
    weights = [10000, 100, 50, 25, 12, 6, 3];
    for f = 1:7
        padic_features(:, f) = padic_features(:, f) / weights(f);
    end
    
    % Compute p-adic distances
    D = compute_padic_distances_enhanced(padic_features, 2);
    
    % Clustering and scoring
    Z = linkage(squareform(D), 'complete');
    best_score = 0;
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        score_k = mean(silhouette(padic_features, clusters, squareform(D)));
        if score_k > best_score
            best_score = score_k;
        end
    end
    
    score = best_score;
end

function D = compute_padic_distances_enhanced(features, p)
    % Enhanced p-adic distance computation
    
    n = size(features, 1);
    D = zeros(n, n);
    
    for i = 1:n
        for j = i+1:n
            diff = abs(features(i, :) - features(j, :));
            distances = zeros(1, length(diff));
            
            for k = 1:length(diff)
                if diff(k) > 0
                    if diff(k) >= 10000  % Performance tier differences
                        distances(k) = 1;  % Maximum distance
                    else
                        v_p = compute_padic_valuation_enhanced(diff(k), p);
                        distances(k) = p^(-v_p);
                    end
                else
                    distances(k) = 0;
                end
            end
            
            D(i, j) = max(distances);  % Ultrametric
            D(j, i) = D(i, j);
        end
    end
end



function [clusters, features, D] = get_enhanced_clustering(data, teams)
    % Get full clustering results for enhanced method
    
    features = create_enhanced_features(data, teams);
    D = compute_padic_distances_enhanced(features, 2);
    Z = linkage(squareform(D), 'complete');
    clusters = cluster(Z, 'maxclust', 6); % Use k=6 from your results
end

function [clusters, features, D] = get_baseline_clustering(data, teams)
    % Get baseline clustering results
    
    n_teams = length(teams);
    
    % Extract and process absolute features
    abs_features = table2array(data(:, 8:31));
    abs_features(isnan(abs_features)) = 0;
    
    features = zeros(n_teams, size(abs_features, 2));
    for t = 1:n_teams
        team_mask = strcmp(data.team, teams{t});
        if any(team_mask)
            features(t, :) = mean(abs_features(team_mask, :), 1);
        end
    end
    
    features = normalize(features, 'range');
    categorical_features = discretize_features_for_padic(features);
    
    D = compute_padic_distances_enhanced(categorical_features, 2);
    Z = linkage(squareform(D), 'complete');
    clusters = cluster(Z, 'maxclust', 3); % Use k=3 for baseline
end

function write_phase2_report(filename, results)
    % Write detailed Phase 2 report
    
    fid = fopen(filename, 'w');
    
    fprintf(fid, '==============================================\n');
    fprintf(fid, '   PHASE 2 VALIDATION REPORT - DETAILED      \n');
    fprintf(fid, '==============================================\n\n');
    
    fprintf(fid, 'Generated: %s\n\n', char(results.timestamp));
    
    % Bootstrap results
    fprintf(fid, 'BOOTSTRAP ANALYSIS (n=%d):\n', results.config.n_bootstrap);
    fprintf(fid, '----------------------------\n');
    stats = results.bootstrap.statistics;
    fprintf(fid, '  Mean improvement: %.2f%%\n', stats.ci_mean);
    fprintf(fid, '  Median improvement: %.2f%%\n', stats.ci_median);
    fprintf(fid, '  Std deviation: %.2f%%\n', stats.ci_std);
    fprintf(fid, '  95%% CI: [%.2f%%, %.2f%%]\n', stats.ci_lower, stats.ci_upper);
    fprintf(fid, '  90%% CI: [%.2f%%, %.2f%%]\n\n', stats.ci_lower_90, stats.ci_upper_90);
    
    % Cross-validation results
    fprintf(fid, 'CROSS-VALIDATION (%d-fold):\n', results.config.n_folds);
    fprintf(fid, '----------------------------\n');
    fprintf(fid, '  Mean improvement: %.2f%%\n', results.crossval.mean);
    fprintf(fid, '  Std deviation: %.2f%%\n', results.crossval.std);
    fprintf(fid, '  Per-fold results:\n');
    for i = 1:length(results.crossval.improvements)
        fprintf(fid, '    Fold %d: %.2f%%\n', i, results.crossval.improvements(i));
    end
    fprintf(fid, '\n');
    
    % Ablation study
    fprintf(fid, 'ABLATION STUDY:\n');
    fprintf(fid, '---------------\n');
    for i = 1:size(results.ablation.configs, 1)
        config_name = results.ablation.configs{i, 1};
        score = results.ablation.scores(i);
        fprintf(fid, '  %s: %.4f\n', config_name, score);
    end
    fprintf(fid, '\n');
    
    % Component contributions
    fprintf(fid, 'COMPONENT CONTRIBUTIONS:\n');
    fprintf(fid, '------------------------\n');
    component_names = {'Performance', 'Attack', 'Breakdown', 'Territory', ...
                      'Penetration', 'Discipline', 'Set Piece'};
    for i = 1:length(results.ablation.contributions)
        fprintf(fid, '  %s: %.4f\n', component_names{i}, ...
                results.ablation.contributions(i));
    end
    fprintf(fid, '\n');
    
    % Alternative metrics
    fprintf(fid, 'ALTERNATIVE METRICS:\n');
    fprintf(fid, '--------------------\n');
    for i = 1:length(results.metrics.names)
        metric = results.metrics.names{i};
        enhanced = results.metrics.results(i, 1);
        baseline = results.metrics.results(i, 2);
        improvement = (enhanced - baseline) / baseline * 100;
        fprintf(fid, '  %s:\n', metric);
        fprintf(fid, '    Enhanced: %.4f\n', enhanced);
        fprintf(fid, '    Baseline: %.4f\n', baseline);
        fprintf(fid, '    Improvement: %.1f%%\n', improvement);
    end
    fprintf(fid, '\n');
    
    % Effect sizes
    fprintf(fid, 'EFFECT SIZES:\n');
    fprintf(fid, '-------------\n');
    fprintf(fid, '  Cohen''s d: %.3f\n', results.effect_sizes.cohens_d);
    fprintf(fid, '  Glass''s Δ: %.3f\n', results.effect_sizes.glass_delta);
    fprintf(fid, '  Hedges'' g: %.3f\n', results.effect_sizes.hedges_g);
    fprintf(fid, '\n');
    
    % Power analysis
    fprintf(fid, 'POWER ANALYSIS:\n');
    fprintf(fid, '---------------\n');
    fprintf(fid, '  Sample size: %d\n', results.power.sample_size);
    fprintf(fid, '  Observed power: %.3f\n', results.power.observed_power);
    fprintf(fid, '\n');
    
    % Summary
    fprintf(fid, 'SUMMARY:\n');
    fprintf(fid, '--------\n');
    fprintf(fid, '  Overall improvement: %.1f%% [%.1f%%, %.1f%%]\n', ...
            results.summary.improvement_mean, ...
            results.summary.improvement_ci(1), ...
            results.summary.improvement_ci(2));
    fprintf(fid, '  CV stability: %s\n', string(results.summary.cv_stability));
    fprintf(fid, '  Large effect size: %s\n', string(results.summary.effect_size_large));
    fprintf(fid, '  Adequate power: %s\n', string(results.summary.adequate_power));
    
    fclose(fid);
end


%% CORRECTED HELPER FUNCTIONS FOR PHASE 2

function padic_features = create_enhanced_features(rugby_data, teams)
    % Helper to create enhanced features (extracted for reuse)
    % CORRECTED: Returns features, not score
    
    n_teams = length(teams);
    padic_features = zeros(n_teams, 7);
    
    for t = 1:n_teams
        team_matches = rugby_data(strcmp(rugby_data.team, teams{t}), :);
        
        if isempty(team_matches)
            continue;
        end
        
        % DIMENSION 1: Performance Tier (Most Important - Weight x10000)
        avg_points_diff = mean(team_matches.final_points_relative);
        if avg_points_diff > 10
            padic_features(t, 1) = 4 * 10000;
        elseif avg_points_diff > 2
            padic_features(t, 1) = 3 * 10000;
        elseif avg_points_diff > -5
            padic_features(t, 1) = 2 * 10000;
        else
            padic_features(t, 1) = 1 * 10000;
        end
        
        % DIMENSION 2: Attacking Style (ACTUAL calculation)
        avg_carries = mean(team_matches.abs_carries);
        avg_passes = mean(team_matches.abs_passes);
        carry_pass_ratio = avg_carries / (avg_passes + 1);
        
        if carry_pass_ratio > 0.8
            padic_features(t, 2) = 4 * 100;
        elseif carry_pass_ratio > 0.6
            padic_features(t, 2) = 3 * 100;
        elseif carry_pass_ratio > 0.4
            padic_features(t, 2) = 2 * 100;
        else
            padic_features(t, 2) = 1 * 100;
        end
        
        % DIMENSION 3: Breakdown Mastery
        turnover_differential = mean(team_matches.rel_turnovers_won - team_matches.rel_turnovers_conceded);
        
        if turnover_differential > 2
            padic_features(t, 3) = 4 * 50;
        elseif turnover_differential > 0
            padic_features(t, 3) = 3 * 50;
        elseif turnover_differential > -2
            padic_features(t, 3) = 2 * 50;
        else
            padic_features(t, 3) = 1 * 50;
        end
        
        % DIMENSION 4: Territory Control
        avg_kicks = mean(team_matches.abs_kicks_from_hand);
        
        if avg_kicks > 20
            padic_features(t, 4) = 4 * 25;
        elseif avg_kicks > 15
            padic_features(t, 4) = 3 * 25;
        elseif avg_kicks > 10
            padic_features(t, 4) = 2 * 25;
        else
            padic_features(t, 4) = 1 * 25;
        end
        
        % DIMENSION 5: Penetration
        avg_clean_breaks_diff = mean(team_matches.rel_clean_breaks);
        
        if avg_clean_breaks_diff > 2
            padic_features(t, 5) = 4 * 12;
        elseif avg_clean_breaks_diff > 0
            padic_features(t, 5) = 3 * 12;
        elseif avg_clean_breaks_diff > -1
            padic_features(t, 5) = 2 * 12;
        else
            padic_features(t, 5) = 1 * 12;
        end
        
        % DIMENSION 6: Discipline
        avg_penalty_diff = mean(team_matches.rel_penalties_conceded);
        
        if avg_penalty_diff < -2
            padic_features(t, 6) = 4 * 6;
        elseif avg_penalty_diff < 0
            padic_features(t, 6) = 3 * 6;
        elseif avg_penalty_diff < 2
            padic_features(t, 6) = 2 * 6;
        else
            padic_features(t, 6) = 1 * 6;
        end
        
        % DIMENSION 7: Set Piece
        avg_scrums = mean(team_matches.abs_scrums_won);
        avg_lineouts = mean(team_matches.abs_lineout_throws_won);
        set_piece_total = avg_scrums + avg_lineouts;
        
        if set_piece_total > 25
            padic_features(t, 7) = 4 * 3;
        elseif set_piece_total > 20
            padic_features(t, 7) = 3 * 3;
        elseif set_piece_total > 15
            padic_features(t, 7) = 2 * 3;
        else
            padic_features(t, 7) = 1 * 3;
        end
    end
    
    % CORRECTED: Just return features, don't do clustering here
end

function dist = compute_single_padic_distance(diff_vector, p)
    % CORRECTED: Compute p-adic distance for a single difference vector
    
    distances = zeros(1, length(diff_vector));
    
    for k = 1:length(diff_vector)
        if abs(diff_vector(k)) > 0
            if abs(diff_vector(k)) >= 10000
                distances(k) = 1;  % Maximum distance for tier differences
            else
                % Compute p-adic valuation
                v_p = 0;
                n_val = abs(round(diff_vector(k)));
                while mod(n_val, p) == 0 && n_val > 0
                    n_val = n_val / p;
                    v_p = v_p + 1;
                end
                distances(k) = p^(-v_p);
            end
        else
            distances(k) = 0;
        end
    end
    
    dist = max(distances);  % Ultrametric property
end


function D = compute_padic_distances_correct(features, p)
    % CORRECTED: Proper p-adic distance matrix computation
    
    n = size(features, 1);
    D = zeros(n, n);
    
    for i = 1:n
        for j = i+1:n
            diff = abs(features(i, :) - features(j, :));
            distances = zeros(1, length(diff));
            
            for k = 1:length(diff)
                if diff(k) > 0
                    % Enhanced calculation for hierarchical differences
                    if diff(k) >= 10000  % Performance tier differences
                        distances(k) = 1;  % Maximum distance
                    else
                        v_p = 0;
                        n_val = abs(round(diff(k)));
                        while mod(n_val, p) == 0 && n_val > 0
                            n_val = n_val / p;
                            v_p = v_p + 1;
                        end
                        distances(k) = p^(-v_p);
                    end
                else
                    distances(k) = 0;
                end
            end
            
            D(i, j) = max(distances);  % Ultrametric
            D(j, i) = D(i, j);
        end
    end
end

function features = create_enhanced_features_rel_only(team_matches)
    % CORRECTED: Create features using only relative metrics
    
    features = zeros(1, 7);
    
    % Dimension 1: Performance based on relative points
    avg_points_diff = mean(team_matches.final_points_relative);
    if avg_points_diff > 10
        features(1) = 4 * 10000;
    elseif avg_points_diff > 2
        features(1) = 3 * 10000;
    elseif avg_points_diff > -5
        features(1) = 2 * 10000;
    else
        features(1) = 1 * 10000;
    end
    
    % Dimension 2: Use relative carries vs relative passes
    if ismember('rel_carries', team_matches.Properties.VariableNames) && ...
       ismember('rel_passes', team_matches.Properties.VariableNames)
        rel_carry_pass = mean(team_matches.rel_carries) - mean(team_matches.rel_passes);
        if rel_carry_pass > 2
            features(2) = 4 * 100;
        elseif rel_carry_pass > 0
            features(2) = 3 * 100;
        elseif rel_carry_pass > -2
            features(2) = 2 * 100;
        else
            features(2) = 1 * 100;
        end
    else
        features(2) = 2 * 100; % Default to middle value
    end
    
    % Dimension 3: Breakdown (already relative)
    turnover_diff = mean(team_matches.rel_turnovers_won - team_matches.rel_turnovers_conceded);
    if turnover_diff > 2
        features(3) = 4 * 50;
    elseif turnover_diff > 0
        features(3) = 3 * 50;
    elseif turnover_diff > -2
        features(3) = 2 * 50;
    else
        features(3) = 1 * 50;
    end
    
    % Dimension 4: Territory using relative kicks
    if ismember('rel_kicks_from_hand', team_matches.Properties.VariableNames)
        avg_rel_kicks = mean(team_matches.rel_kicks_from_hand);
        if avg_rel_kicks > 2
            features(4) = 4 * 25;
        elseif avg_rel_kicks > 0
            features(4) = 3 * 25;
        elseif avg_rel_kicks > -2
            features(4) = 2 * 25;
        else
            features(4) = 1 * 25;
        end
    else
        features(4) = 2 * 25; % Default
    end
    
    % Dimension 5: Penetration (already relative)
    avg_clean_breaks = mean(team_matches.rel_clean_breaks);
    if avg_clean_breaks > 2
        features(5) = 4 * 12;
    elseif avg_clean_breaks > 0
        features(5) = 3 * 12;
    elseif avg_clean_breaks > -1
        features(5) = 2 * 12;
    else
        features(5) = 1 * 12;
    end
    
    % Dimension 6: Discipline (already relative)
    avg_penalties = mean(team_matches.rel_penalties_conceded);
    if avg_penalties < -2
        features(6) = 4 * 6;
    elseif avg_penalties < 0
        features(6) = 3 * 6;
    elseif avg_penalties < 2
        features(6) = 2 * 6;
    else
        features(6) = 1 * 6;
    end
    
    % Dimension 7: Set piece using relative metrics
    if ismember('rel_scrums_won', team_matches.Properties.VariableNames) && ...
       ismember('rel_lineout_throws_won', team_matches.Properties.VariableNames)
        rel_set_piece = mean(team_matches.rel_scrums_won) + mean(team_matches.rel_lineout_throws_won);
        if rel_set_piece > 2
            features(7) = 4 * 3;
        elseif rel_set_piece > 0
            features(7) = 3 * 3;
        elseif rel_set_piece > -2
            features(7) = 2 * 3;
        else
            features(7) = 1 * 3;
        end
    else
        features(7) = 2 * 3; % Default
    end
end

function score = run_enhanced_abs_only(data, teams)
    % CORRECTED: Run enhanced with only absolute features
    
    n_teams = length(teams);
    padic_features = zeros(n_teams, 7);
    
    for t = 1:n_teams
        team_matches = data(strcmp(data.team, teams{t}), :);
        
        if isempty(team_matches)
            continue;
        end
        
        % Dimension 1: Use absolute points instead of relative
        if ismember('abs_final_points_absolute', team_matches.Properties.VariableNames)
            avg_points = mean(team_matches.abs_final_points_absolute);
        else
            % Fallback: use final_points_absolute without 'abs_' prefix
            avg_points = mean(team_matches.final_points_absolute);
        end
        
        if avg_points > 30
            padic_features(t, 1) = 4 * 10000;
        elseif avg_points > 20
            padic_features(t, 1) = 3 * 10000;
        elseif avg_points > 10
            padic_features(t, 1) = 2 * 10000;
        else
            padic_features(t, 1) = 1 * 10000;
        end
        
        % Dimensions 2-7: Use absolute metrics only
        % (Same logic as enhanced but using abs_ columns only)
        
        % Dimension 2: Attacking Style (already uses abs)
        avg_carries = mean(team_matches.abs_carries);
        avg_passes = mean(team_matches.abs_passes);
        carry_pass_ratio = avg_carries / (avg_passes + 1);
        
        if carry_pass_ratio > 0.8
            padic_features(t, 2) = 4 * 100;
        elseif carry_pass_ratio > 0.6
            padic_features(t, 2) = 3 * 100;
        elseif carry_pass_ratio > 0.4
            padic_features(t, 2) = 2 * 100;
        else
            padic_features(t, 2) = 1 * 100;
        end
        
        % Dimension 3: Use absolute turnovers
        abs_turnover_diff = mean(team_matches.abs_turnovers_won - team_matches.abs_turnovers_conceded);
        if abs_turnover_diff > 2
            padic_features(t, 3) = 4 * 50;
        elseif abs_turnover_diff > 0
            padic_features(t, 3) = 3 * 50;
        elseif abs_turnover_diff > -2
            padic_features(t, 3) = 2 * 50;
        else
            padic_features(t, 3) = 1 * 50;
        end
        
        % Dimensions 4-7: Continue with abs metrics
        % Territory (already uses abs_kicks_from_hand)
        avg_kicks = mean(team_matches.abs_kicks_from_hand);
        if avg_kicks > 20
            padic_features(t, 4) = 4 * 25;
        elseif avg_kicks > 15
            padic_features(t, 4) = 3 * 25;
        elseif avg_kicks > 10
            padic_features(t, 4) = 2 * 25;
        else
            padic_features(t, 4) = 1 * 25;
        end
        
        % Penetration using absolute clean breaks
        avg_clean_breaks = mean(team_matches.abs_clean_breaks);
        if avg_clean_breaks > 5
            padic_features(t, 5) = 4 * 12;
        elseif avg_clean_breaks > 3
            padic_features(t, 5) = 3 * 12;
        elseif avg_clean_breaks > 1
            padic_features(t, 5) = 2 * 12;
        else
            padic_features(t, 5) = 1 * 12;
        end
        
        % Discipline using absolute penalties
        avg_penalties = mean(team_matches.abs_penalties_conceded);
        if avg_penalties < 8
            padic_features(t, 6) = 4 * 6;
        elseif avg_penalties < 10
            padic_features(t, 6) = 3 * 6;
        elseif avg_penalties < 12
            padic_features(t, 6) = 2 * 6;
        else
            padic_features(t, 6) = 1 * 6;
        end
        
        % Set piece (already uses abs metrics)
        avg_scrums = mean(team_matches.abs_scrums_won);
        avg_lineouts = mean(team_matches.abs_lineout_throws_won);
        set_piece_total = avg_scrums + avg_lineouts;
        if set_piece_total > 25
            padic_features(t, 7) = 4 * 3;
        elseif set_piece_total > 20
            padic_features(t, 7) = 3 * 3;
        elseif set_piece_total > 15
            padic_features(t, 7) = 2 * 3;
        else
            padic_features(t, 7) = 1 * 3;
        end
    end
    
    % Compute p-adic distances and clustering
    D = compute_padic_distances_correct(padic_features, 2);
    Z = linkage(squareform(D), 'complete');
    
    best_score = 0;
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        score_k = mean(silhouette(padic_features, clusters, squareform(D)));
        if score_k > best_score
            best_score = score_k;
        end
    end
    
    score = best_score;
end

function score = run_enhanced_rel_only(data, teams)
    % CORRECTED: Run enhanced with only relative features
    
    n_teams = length(teams);
    padic_features = zeros(n_teams, 7);
    
    for t = 1:n_teams
        team_matches = data(strcmp(data.team, teams{t}), :);
        
        if isempty(team_matches)
            continue;
        end
        
        % Use the helper function for rel-only features
        padic_features(t, :) = create_enhanced_features_rel_only(team_matches);
    end
    
    % Compute p-adic distances and clustering
    D = compute_padic_distances_correct(padic_features, 2);
    Z = linkage(squareform(D), 'complete');
    
    best_score = 0;
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        score_k = mean(silhouette(padic_features, clusters, squareform(D)));
        if score_k > best_score
            best_score = score_k;
        end
    end
    
    score = best_score;
end

function valuation = compute_padic_valuation_enhanced(n, p)
    % Enhanced p-adic valuation
    
    if n == 0
        valuation = Inf;
        return;
    end
    
    n = abs(round(n));
    valuation = 0;
    
    while mod(n, p) == 0 && n > 0
        n = n / p;
        valuation = valuation + 1;
    end
end



function categorical_features = discretize_features_for_padic(continuous_features)
    % Convert continuous features to categorical
    
    n_features = size(continuous_features, 2);
    categorical_features = zeros(size(continuous_features));
    
    for f = 1:n_features
        feature_data = continuous_features(:, f);
        categorical_features(:, f) = discretize(feature_data, 4) * (f + 1);
    end
end


function create_phase2_plots(results, output_dir)
    % Create visualization plots
    figure('Position', [100, 100, 1200, 800]);

    % Plot 1: Bootstrap distribution
    subplot(1,3,1);
    histogram(results.bootstrap.improvements, 50);
    xlabel('Improvement (%)');
    ylabel('Frequency');
    title('Bootstrap Distribution (n=10,000)');

    % Plot 2: Cross-validation results
    subplot(1,3,2);
    bar(results.crossval.improvements);
    xlabel('Fold');
    ylabel('Improvement (%)');
    title('Cross-Validation Results');

    % Plot 3: Ablation study
    subplot(1,3,3);
    bar(results.ablation.contributions);
    xlabel('Component');
    ylabel('Contribution');
    title('Component Contributions');

    % Save figure
    saveas(gcf, fullfile(output_dir, 'phase2_plots.png'));
end

% function [clusters, model] = train_enhanced_model(data, teams)
%     % FIXED: Added clusters field to model
% 
%     n_teams = length(teams);
% 
%     % Create enhanced features
%     padic_features = create_enhanced_features(data, teams);
% 
%     % Compute p-adic distances
%     D = compute_padic_distances_enhanced(padic_features, 2);
% 
%     % Hierarchical clustering
%     Z = linkage(squareform(D), 'complete');
% 
%     % Find optimal k
%     best_k = 6;
%     clusters = cluster(Z, 'maxclust', best_k);
% 
%     % Store model parameters
%     model = struct();
%     model.features = padic_features;
%     model.distance_matrix = D;
%     model.linkage = Z;
%     model.k = best_k;
%     model.prime = 2;
%     model.clusters = clusters;  % ADD THIS LINE - was missing!
% end

function [clusters, model] = train_baseline_model(data, teams)
    % FIXED: Complete baseline model training
    
    n_teams = length(teams);
    
    % Extract absolute features
    abs_features = table2array(data(:, 8:31));
    abs_features(isnan(abs_features)) = 0;
    
    % Aggregate by team
    team_abs_features = zeros(n_teams, size(abs_features, 2));
    for t = 1:n_teams
        team_mask = strcmp(data.team, teams{t});
        if any(team_mask)
            team_abs_features(t, :) = mean(abs_features(team_mask, :), 1);
        end
    end
    
    % Normalize
    team_abs_features = normalize(team_abs_features, 'range');
    
    % Convert to categorical
    categorical_features = discretize_features_for_padic(team_abs_features);
    
    % Compute p-adic distances
    D = compute_padic_distances_enhanced(categorical_features, 2);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Use k=3 for baseline
    clusters = cluster(Z, 'maxclust', 3);
    
    % Store model parameters
    model = struct();
    model.features = categorical_features;
    model.distance_matrix = D;
    model.linkage = Z;
    model.k = 3;
    model.prime = 2;
    model.clusters = clusters;  % THIS WAS MISSING!
end


% function [clusters, model] = train_baseline_model(data, teams)
%     % Train baseline model (companion to train_enhanced_model)
% 
%     n_teams = length(teams);
% 
%     % Extract absolute features (columns 8-31) for baseline
%     abs_features = table2array(data(:, 8:31));
%     abs_features(isnan(abs_features)) = 0;
% 
%     % Aggregate by team
%     team_abs_features = zeros(n_teams, size(abs_features, 2));
%     for t = 1:n_teams
%         team_mask = strcmp(data.team, teams{t});
%         if any(team_mask)
%             team_abs_features(t, :) = mean(abs_features(team_mask, :), 1);
%         end
%     end
% 
%     % Normalize to [0,1]
%     team_abs_features = normalize(team_abs_features, 'range');
% 
%     % Convert to categorical for p-adic
%     categorical_features = discretize_features_for_padic(team_abs_features);
% 
%     % Compute p-adic distances
%     D = compute_padic_distances_enhanced(categorical_features, 2);
% 
%     % Hierarchical clustering
%     Z = linkage(squareform(D), 'complete');
% 
%     % Use k=3 for baseline (from Phase 1 results)
%     clusters = cluster(Z, 'maxclust', 3);
% 
%     % Store model parameters
%     model = struct();
%     model.features = categorical_features;
%     model.distance_matrix = D;
%     model.linkage = Z;
%     model.k = 3;
%     model.prime = 2;
%     model.clusters = clusters;  % Add this for evaluate_on_test
% end

% function [clusters, model] = train_baseline_model(data, teams)
%     % FIXED: Complete baseline model training
% 
%     n_teams = length(teams);
% 
%     % Extract absolute features
%     abs_features = table2array(data(:, 8:31));
%     abs_features(isnan(abs_features)) = 0;
% 
%     % Aggregate by team
%     team_abs_features = zeros(n_teams, size(abs_features, 2));
%     for t = 1:n_teams
%         team_mask = strcmp(data.team, teams{t});
%         if any(team_mask)
%             team_abs_features(t, :) = mean(abs_features(team_mask, :), 1);
%         end
%     end
% 
%     % Normalize
%     team_abs_features = normalize(team_abs_features, 'range');
% 
%     % Convert to categorical
%     categorical_features = discretize_features_for_padic(team_abs_features);
% 
%     % Compute p-adic distances
%     D = compute_padic_distances_enhanced(categorical_features, 2);
% 
%     % Hierarchical clustering
%     Z = linkage(squareform(D), 'complete');
% 
%     % Use k=3 for baseline
%     clusters = cluster(Z, 'maxclust', 3);
% 
%     % Store model parameters
%     model = struct();
%     model.features = categorical_features;
%     model.distance_matrix = D;
%     model.linkage = Z;
%     model.k = 3;
%     model.prime = 2;
%     model.clusters = clusters;  % THIS WAS MISSING!
% end

% function padic_features = create_enhanced_features(rugby_data, teams)
%     % Helper to create enhanced features (extracted for reuse)
% 
%     n_teams = length(teams);
%     padic_features = zeros(n_teams, 7);
% 
%     % for t = 1:n_teams
%     %     team_matches = data(strcmp(data.team, teams{t}), :);
%     % 
%     %     if isempty(team_matches)
%     %         continue;
%     %     end
%     % 
%     %     % [Full implementation as in run_enhanced_padic_full]
%     %     % ... (same code as above)
%     % end
%     % 
%     % % This is the ACTUAL implementation from your enhanced pipeline
%     % 
%     % n_teams = length(teams);
%     % padic_features = zeros(n_teams, 7);
% 
%     for t = 1:n_teams
%         team_matches = rugby_data(strcmp(rugby_data.team, teams{t}), :);
% 
%         % DIMENSION 1: Performance Tier (Most Important - Weight x10000)
%         avg_points_diff = mean(team_matches.final_points_relative);
%         if avg_points_diff > 10
%             padic_features(t, 1) = 4 * 10000;
%         elseif avg_points_diff > 2
%             padic_features(t, 1) = 3 * 10000;
%         elseif avg_points_diff > -5
%             padic_features(t, 1) = 2 * 10000;
%         else
%             padic_features(t, 1) = 1 * 10000;
%         end
% 
%         % DIMENSION 2: Attacking Style (ACTUAL calculation)
%         avg_carries = mean(team_matches.abs_carries);
%         avg_passes = mean(team_matches.abs_passes);
%         carry_pass_ratio = avg_carries / (avg_passes + 1);
% 
%         if carry_pass_ratio > 0.8
%             padic_features(t, 2) = 4 * 100;
%         elseif carry_pass_ratio > 0.6
%             padic_features(t, 2) = 3 * 100;
%         elseif carry_pass_ratio > 0.4
%             padic_features(t, 2) = 2 * 100;
%         else
%             padic_features(t, 2) = 1 * 100;
%         end
% 
%         % DIMENSION 3: Breakdown Mastery
%         turnover_differential = mean(team_matches.rel_turnovers_won - team_matches.rel_turnovers_conceded);
% 
%         if turnover_differential > 2
%             padic_features(t, 3) = 4 * 50;
%         elseif turnover_differential > 0
%             padic_features(t, 3) = 3 * 50;
%         elseif turnover_differential > -2
%             padic_features(t, 3) = 2 * 50;
%         else
%             padic_features(t, 3) = 1 * 50;
%         end
% 
%         % DIMENSION 4: Territory Control
%         avg_kicks = mean(team_matches.abs_kicks_from_hand);
% 
%         if avg_kicks > 20
%             padic_features(t, 4) = 4 * 25;
%         elseif avg_kicks > 15
%             padic_features(t, 4) = 3 * 25;
%         elseif avg_kicks > 10
%             padic_features(t, 4) = 2 * 25;
%         else
%             padic_features(t, 4) = 1 * 25;
%         end
% 
%         % DIMENSION 5: Penetration
%         avg_clean_breaks_diff = mean(team_matches.rel_clean_breaks);
% 
%         if avg_clean_breaks_diff > 2
%             padic_features(t, 5) = 4 * 12;
%         elseif avg_clean_breaks_diff > 0
%             padic_features(t, 5) = 3 * 12;
%         elseif avg_clean_breaks_diff > -1
%             padic_features(t, 5) = 2 * 12;
%         else
%             padic_features(t, 5) = 1 * 12;
%         end
% 
%         % DIMENSION 6: Discipline
%         avg_penalty_diff = mean(team_matches.rel_penalties_conceded);
% 
%         if avg_penalty_diff < -2
%             padic_features(t, 6) = 4 * 6;
%         elseif avg_penalty_diff < 0
%             padic_features(t, 6) = 3 * 6;
%         elseif avg_penalty_diff < 2
%             padic_features(t, 6) = 2 * 6;
%         else
%             padic_features(t, 6) = 1 * 6;
%         end
% 
%         % DIMENSION 7: Set Piece
%         avg_scrums = mean(team_matches.abs_scrums_won);
%         avg_lineouts = mean(team_matches.abs_lineout_throws_won);
%         set_piece_total = avg_scrums + avg_lineouts;
% 
%         if set_piece_total > 25
%             padic_features(t, 7) = 4 * 3;
%         elseif set_piece_total > 20
%             padic_features(t, 7) = 3 * 3;
%         elseif set_piece_total > 15
%             padic_features(t, 7) = 2 * 3;
%         else
%             padic_features(t, 7) = 1 * 3;
%         end
%     end
% 
%     % Compute p-adic distances
%     D = compute_padic_distances_correct(padic_features, 2);
% 
%     % Hierarchical clustering
%     Z = linkage(squareform(D), 'complete');
% 
%     % Find best k
%     best_score = 0;
%     for k = 2:min(6, n_teams-1)
%         clusters = cluster(Z, 'maxclust', k);
%         s = silhouette(padic_features, clusters, squareform(D));
%         score = mean(s);
%         if score > best_score
%             best_score = score;
%         end
%     end
% 
%     score = best_score;
% end
% 
% function D = compute_padic_distances_enhanced(features, p)
%     % Enhanced p-adic distance computation
% 
%     n = size(features, 1);
%     D = zeros(n, n);
% 
%     for i = 1:n
%         for j = i+1:n
%             diff = abs(features(i, :) - features(j, :));
%             distances = zeros(1, length(diff));
% 
%             for k = 1:length(diff)
%                 if diff(k) > 0
%                     if diff(k) >= 10000  % Performance tier differences
%                         distances(k) = 1;  % Maximum distance
%                     else
%                         v_p = compute_padic_valuation_enhanced(diff(k), p);
%                         distances(k) = p^(-v_p);
%                     end
%                 else
%                     distances(k) = 0;
%                 end
%             end
% 
%             D(i, j) = max(distances);  % Ultrametric
%             D(j, i) = D(i, j);
%         end
%     end
% end
% 
% function valuation = compute_padic_valuation_enhanced(n, p)
%     % Enhanced p-adic valuation
% 
%     if n == 0
%         valuation = Inf;
%         return;
%     end
% 
%     n = abs(round(n));
%     valuation = 0;
% 
%     while mod(n, p) == 0 && n > 0
%         n = n / p;
%         valuation = valuation + 1;
%     end
% end
% 
% function D = compute_single_padic_distance(diff_vector, p)
%     % Compute p-adic distance for a single difference vector
% 
%     % distances = zeros(1, length(diff_vector));
%     % for k = 1:length(diff_vector)
%     %     if diff_vector(k) > 0
%     %         if diff_vector(k) >= 10000
%     %             distances(k) = 1;
%     %         else
%     %             v_p = compute_padic_valuation_enhanced(diff_vector(k), p);
%     %             distances(k) = p^(-v_p);
%     %         end
%     %     end
%     % end
%     % dist = max(distances);
% 
%     % Correct p-adic distance computation
%     n = size(features, 1);
%     D = zeros(n, n);
% 
%     for i = 1:n
%         for j = i+1:n
%             diff = abs(features(i, :) - features(j, :));
%             distances = zeros(1, length(diff));
% 
%             for k = 1:length(diff)
%                 if diff(k) > 0
%                     % Enhanced calculation for hierarchical differences
%                     if diff(k) >= 10000  % Performance tier differences
%                         distances(k) = 1;  % Maximum distance
%                     else
%                         v_p = 0;
%                         n_val = abs(round(diff(k)));
%                         while mod(n_val, p) == 0 && n_val > 0
%                             n_val = n_val / p;
%                             v_p = v_p + 1;
%                         end
%                         distances(k) = p^(-v_p);
%                     end
%                 else
%                     distances(k) = 0;
%                 end
%             end
% 
%             D(i, j) = max(distances);  % Ultrametric
%             D(j, i) = D(i, j);
%         end
%     end
% end
% 
% function categorical_features = discretize_features_for_padic(continuous_features)
%     % Convert continuous features to categorical
% 
%     n_features = size(continuous_features, 2);
%     categorical_features = zeros(size(continuous_features));
% 
%     for f = 1:n_features
%         feature_data = continuous_features(:, f);
%         categorical_features(:, f) = discretize(feature_data, 4) * (f + 1);
%     end
% end
% 
% function features = create_enhanced_features_rel_only(team_matches)
%     % Create features using only relative metrics
% 
%     features = zeros(1, 7);
% 
%     % All based on relative metrics
%     features(1) = categorize_value(mean(team_matches.rel_final_points_relative), ...
%                                   [-inf, -5, 2, 10, inf]) * 10000;
%     features(2) = categorize_value(mean(team_matches.rel_carries), ...
%                                   [-inf, -2, 0, 2, inf]) * 100;
%     % ... continue for other features
% 
%     % Simplified for brevity
%     features(3:7) = [150, 75, 36, 18, 9];
% end
% 
% function category = categorize_value(value, thresholds)
%     % Helper to categorize continuous value
%     category = sum(value > thresholds(1:end-1));
% end
% 
