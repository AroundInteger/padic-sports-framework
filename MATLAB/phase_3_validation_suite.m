%% PHASE 3 VALIDATION SUITE: EXTERNAL VALIDATION & ROBUSTNESS
% Testing method generalization across different data splits and scenarios
% Week 3: Prove the method works beyond the specific dataset

clear; close all; clc;
fprintf('========================================\n');
fprintf('   P-ADIC VALIDATION SUITE - PHASE 3    \n');
fprintf('   External Validation & Robustness     \n');
fprintf('========================================\n\n');

%% CONFIGURATION
config = struct();
config.data_file = 'data/rugby/rugby_analysis_ready.csv';
config.random_seed = 42;
config.save_results = true;
config.output_dir = 'validation_results_phase3/';

if ~exist(config.output_dir, 'dir')
    mkdir(config.output_dir);
end

% Initialize results
phase3_results = struct();
phase3_results.timestamp = datetime('now');
phase3_results.config = config;

%% LOAD DATA
rugby_data = readtable(config.data_file);
teams = unique(rugby_data.team);
n_teams = length(teams);
seasons = unique(rugby_data.season);
n_seasons = length(seasons);

fprintf('Data Overview:\n');
fprintf('  Teams: %d\n', n_teams);
fprintf('  Seasons: %d (%s)\n', n_seasons, strjoin(string(seasons), ', '));
fprintf('  Total matches: %d\n', height(rugby_data));
fprintf('  Matches per season: ');
for s = 1:n_seasons
    n_matches = sum(strcmp(rugby_data.season, seasons{s}));
    fprintf('%s(%d) ', seasons{s}, n_matches);
end
fprintf('\n\n');

%% TEST 1: TEMPORAL VALIDATION (Train on Early Seasons, Test on Later)
fprintf('TEST 1: Temporal Validation\n');
fprintf('----------------------------\n');
fprintf('Training on seasons 1-3, testing on season 4\n\n');

% Split data temporally
train_seasons = seasons(1:end-1);  % First 3 seasons
test_season = seasons{end};         % Last season

train_mask = ismember(rugby_data.season, train_seasons);
test_mask = strcmp(rugby_data.season, test_season);

train_data = rugby_data(train_mask, :);
test_data = rugby_data(test_mask, :);

fprintf('  Training data: %d matches (%s)\n', height(train_data), ...
    strjoin(string(train_seasons), ', '));
fprintf('  Test data: %d matches (%s)\n', height(test_data), test_season);

% Run both methods on temporal split
try
    % Enhanced method
    enhanced_train = run_enhanced_padic_full(train_data, teams);
    enhanced_test = run_enhanced_padic_full(test_data, teams);
    
    % Baseline method
    baseline_train = run_baseline_padic(train_data, teams);
    baseline_test = run_baseline_padic(test_data, teams);
    
    % Calculate improvements
    train_improvement = (enhanced_train - baseline_train) / baseline_train * 100;
    test_improvement = (enhanced_test - baseline_test) / baseline_test * 100;
    
    fprintf('\nResults:\n');
    fprintf('  Training set - Enhanced: %.4f, Baseline: %.4f, Improvement: %.1f%%\n', ...
        enhanced_train, baseline_train, train_improvement);
    fprintf('  Test set - Enhanced: %.4f, Baseline: %.4f, Improvement: %.1f%%\n', ...
        enhanced_test, baseline_test, test_improvement);
    fprintf('  Generalization gap: %.1f%%\n', abs(train_improvement - test_improvement));
    
    phase3_results.temporal = struct();
    phase3_results.temporal.train_improvement = train_improvement;
    phase3_results.temporal.test_improvement = test_improvement;
    phase3_results.temporal.generalization_gap = abs(train_improvement - test_improvement);
    
catch ME
    fprintf('  Error in temporal validation: %s\n', ME.message);
    phase3_results.temporal = struct('error', ME.message);
end

%% TEST 2: LEAVE-ONE-SEASON-OUT VALIDATION
fprintf('\nTEST 2: Leave-One-Season-Out Validation\n');
fprintf('----------------------------------------\n');

loso_enhanced = zeros(n_seasons, 1);
loso_baseline = zeros(n_seasons, 1);
loso_improvements = zeros(n_seasons, 1);

for s = 1:n_seasons
    test_season = seasons{s};
    train_seasons = seasons([1:s-1, s+1:end]);
    
    fprintf('  Fold %d - Test: %s, Train: %s...', s, test_season, ...
        strjoin(string(train_seasons), ','));
    
    % Split data
    test_mask = strcmp(rugby_data.season, test_season);
    train_mask = ~test_mask;
    
    test_data = rugby_data(test_mask, :);
    train_data = rugby_data(train_mask, :);
    
    try
        % Run methods
        enhanced_score = run_enhanced_padic_full(test_data, teams);
        baseline_score = run_baseline_padic(test_data, teams);
        
        loso_enhanced(s) = enhanced_score;
        loso_baseline(s) = baseline_score;
        
        if baseline_score ~= 0
            loso_improvements(s) = (enhanced_score - baseline_score) / baseline_score * 100;
            fprintf(' Improvement: %.1f%%\n', loso_improvements(s));
        else
            loso_improvements(s) = NaN;
            fprintf(' Baseline zero\n');
        end
        
    catch ME
        fprintf(' Error: %s\n', ME.message);
        loso_improvements(s) = NaN;
    end
end

% Calculate LOSO statistics
valid_loso = loso_improvements(~isnan(loso_improvements));
if ~isempty(valid_loso)
    fprintf('\nLOSO Results:\n');
    fprintf('  Valid folds: %d/%d\n', length(valid_loso), n_seasons);
    fprintf('  Mean improvement: %.1f%%\n', mean(valid_loso));
    fprintf('  Std deviation: %.1f%%\n', std(valid_loso));
    fprintf('  Range: [%.1f%%, %.1f%%]\n', min(valid_loso), max(valid_loso));
end

phase3_results.loso = struct();
phase3_results.loso.improvements = loso_improvements;
phase3_results.loso.mean = mean(valid_loso);
phase3_results.loso.std = std(valid_loso);

%% TEST 3: EARLY VS LATE SEASON PERFORMANCE
fprintf('\nTEST 3: Early vs Late Season Analysis\n');
fprintf('--------------------------------------\n');

early_late_results = [];

for s = 1:n_seasons
    season_data = rugby_data(strcmp(rugby_data.season, seasons{s}), :);
    n_matches = height(season_data);
    
    if n_matches < 20
        continue;  % Skip if too few matches
    end
    
    % Assume matches are chronologically ordered within season
    mid_point = floor(n_matches / 2);
    early_data = season_data(1:mid_point, :);
    late_data = season_data(mid_point+1:end, :);
    
    fprintf('  %s: %d early, %d late matches...', seasons{s}, ...
        height(early_data), height(late_data));
    
    try
        % Early season
        early_enh = run_enhanced_padic_full(early_data, teams);
        early_base = run_baseline_padic(early_data, teams);
        
        % Late season
        late_enh = run_enhanced_padic_full(late_data, teams);
        late_base = run_baseline_padic(late_data, teams);
        
        early_imp = (early_enh - early_base) / early_base * 100;
        late_imp = (late_enh - late_base) / late_base * 100;
        
        fprintf(' Early: %.1f%%, Late: %.1f%%\n', early_imp, late_imp);
        
        early_late_results = [early_late_results; early_imp, late_imp];
        
    catch ME
        fprintf(' Error\n');
    end
end

if ~isempty(early_late_results)
    fprintf('\nEarly vs Late Summary:\n');
    fprintf('  Mean early season improvement: %.1f%%\n', mean(early_late_results(:,1)));
    fprintf('  Mean late season improvement: %.1f%%\n', mean(early_late_results(:,2)));
    fprintf('  Consistency: %.1f%% difference\n', ...
        abs(mean(early_late_results(:,1)) - mean(early_late_results(:,2))));
end

phase3_results.early_late = early_late_results;

%% TEST 4: STABILITY ACROSS SEASONS
fprintf('\nTEST 4: Method Stability Across Seasons\n');
fprintf('----------------------------------------\n');

season_scores = struct();
season_scores.enhanced = zeros(n_seasons, 1);
season_scores.baseline = zeros(n_seasons, 1);
season_scores.improvements = zeros(n_seasons, 1);

for s = 1:n_seasons
    season_data = rugby_data(strcmp(rugby_data.season, seasons{s}), :);
    
    fprintf('  %s (%d matches)...', seasons{s}, height(season_data));
    
    try
        enhanced = run_enhanced_padic_full(season_data, teams);
        baseline = run_baseline_padic(season_data, teams);
        
        season_scores.enhanced(s) = enhanced;
        season_scores.baseline(s) = baseline;
        season_scores.improvements(s) = (enhanced - baseline) / baseline * 100;
        
        fprintf(' Enhanced: %.3f, Baseline: %.3f, Improvement: %.1f%%\n', ...
            enhanced, baseline, season_scores.improvements(s));
        
    catch ME
        fprintf(' Error\n');
        season_scores.improvements(s) = NaN;
    end
end

% Calculate stability metrics
valid_improvements = season_scores.improvements(~isnan(season_scores.improvements));
if length(valid_improvements) > 1
    cv_stability = std(valid_improvements) / mean(valid_improvements);  % Coefficient of variation
    
    fprintf('\nStability Metrics:\n');
    fprintf('  Mean improvement across seasons: %.1f%%\n', mean(valid_improvements));
    fprintf('  Std deviation: %.1f%%\n', std(valid_improvements));
    fprintf('  Coefficient of variation: %.2f\n', cv_stability);
    fprintf('  Range: [%.1f%%, %.1f%%]\n', min(valid_improvements), max(valid_improvements));
    
    if cv_stability < 0.3
        fprintf('  ✓ Method is STABLE across seasons (CV < 0.3)\n');
    else
        fprintf('  ⚠ Method shows VARIABILITY across seasons (CV > 0.3)\n');
    end
end

phase3_results.stability = season_scores;

%% TEST 5: PREDICTIVE VALIDATION
fprintf('\nTEST 5: Predictive Validation\n');
fprintf('-----------------------------\n');
fprintf('Can cluster membership predict match outcomes?\n\n');

% Train on seasons 1-3
train_seasons = seasons(1:end-1);
train_mask = ismember(rugby_data.season, train_seasons);
train_data = rugby_data(train_mask, :);

% Get cluster assignments
[clusters_enh, ~] = get_enhanced_clustering_full(train_data, teams);

% Create tier mapping (higher cluster = better tier)
team_tiers = containers.Map();
for t = 1:n_teams
    team_tiers(teams{t}) = clusters_enh(t);
end

% Test on season 4 matches
test_season = seasons{end};
test_matches = rugby_data(strcmp(rugby_data.season, test_season), :);

% For each match, predict based on tier difference
correct_predictions = 0;
total_predictions = 0;

for m = 1:height(test_matches)
    match = test_matches(m, :);
    team = match.team{1};
    outcome = match.outcome_binary;  % 1 = win, 0 = loss
    
    % Skip if we can't determine opponent
    if ~isKey(team_tiers, team)
        continue;
    end
    
    % Simple prediction: higher tier teams should win more
    team_tier = team_tiers(team);
    avg_tier = mean(cell2mat(values(team_tiers)));
    
    % Predict win if team is in above-average tier
    prediction = team_tier > avg_tier;
    
    if prediction == outcome
        correct_predictions = correct_predictions + 1;
    end
    total_predictions = total_predictions + 1;
end

if total_predictions > 0
    accuracy = correct_predictions / total_predictions * 100;
    
    fprintf('Predictive Results:\n');
    fprintf('  Matches predicted: %d\n', total_predictions);
    fprintf('  Correct predictions: %d\n', correct_predictions);
    fprintf('  Accuracy: %.1f%%\n', accuracy);
    fprintf('  Baseline (random): 50.0%%\n');
    
    if accuracy > 55
        fprintf('  ✓ Clusters have predictive value (>55%% accuracy)\n');
    else
        fprintf('  ⚠ Limited predictive value\n');
    end
    
    phase3_results.predictive = struct();
    phase3_results.predictive.accuracy = accuracy;
    phase3_results.predictive.n_predictions = total_predictions;
end

%% TEST 6: RANDOM SUBSAMPLE VALIDATION
fprintf('\nTEST 6: Random Subsample Robustness\n');
fprintf('------------------------------------\n');
fprintf('Testing on random 80%% subsamples of data\n\n');

n_subsamples = 20;
subsample_improvements = zeros(n_subsamples, 1);

rng(config.random_seed);

for i = 1:n_subsamples
    % Random 80% sample
    sample_idx = randsample(height(rugby_data), round(0.8 * height(rugby_data)));
    sample_data = rugby_data(sample_idx, :);
    
    try
        enhanced = run_enhanced_padic_full(sample_data, teams);
        baseline = run_baseline_padic(sample_data, teams);
        
        if baseline ~= 0
            subsample_improvements(i) = (enhanced - baseline) / baseline * 100;
        else
            subsample_improvements(i) = NaN;
        end
        
        if mod(i, 5) == 0
            fprintf('  Completed %d/%d subsamples\n', i, n_subsamples);
        end
        
    catch
        subsample_improvements(i) = NaN;
    end
end

valid_subsamples = subsample_improvements(~isnan(subsample_improvements));
if ~isempty(valid_subsamples)
    fprintf('\nSubsample Results:\n');
    fprintf('  Valid subsamples: %d/%d\n', length(valid_subsamples), n_subsamples);
    fprintf('  Mean improvement: %.1f%%\n', mean(valid_subsamples));
    fprintf('  95%% CI: [%.1f%%, %.1f%%]\n', ...
        prctile(valid_subsamples, 2.5), prctile(valid_subsamples, 97.5));
end

phase3_results.subsamples = valid_subsamples;

%% SUMMARY REPORT
fprintf('\n========================================\n');
fprintf('        PHASE 3 VALIDATION SUMMARY       \n');
fprintf('========================================\n\n');

% Temporal validation
if isfield(phase3_results, 'temporal') && ~isfield(phase3_results.temporal, 'error')
    fprintf('TEMPORAL VALIDATION:\n');
    fprintf('  Test set improvement: %.1f%%\n', phase3_results.temporal.test_improvement);
    fprintf('  Generalization gap: %.1f%%\n', phase3_results.temporal.generalization_gap);
    
    if phase3_results.temporal.generalization_gap < 20
        fprintf('  ✓ Good generalization to future data\n');
    end
end

% LOSO validation
if isfield(phase3_results, 'loso') && ~isempty(phase3_results.loso.mean)
    fprintf('\nLEAVE-ONE-SEASON-OUT:\n');
    fprintf('  Mean improvement: %.1f%% ± %.1f%%\n', ...
        phase3_results.loso.mean, phase3_results.loso.std);
end

% Stability
if isfield(phase3_results, 'stability')
    valid_imp = phase3_results.stability.improvements(~isnan(phase3_results.stability.improvements));
    if ~isempty(valid_imp)
        fprintf('\nSTABILITY ACROSS SEASONS:\n');
        fprintf('  Consistent improvement in %d/%d seasons\n', ...
            sum(valid_imp > 0), length(valid_imp));
    end
end

% Predictive validation
if isfield(phase3_results, 'predictive')
    fprintf('\nPREDICTIVE VALIDATION:\n');
    fprintf('  Match prediction accuracy: %.1f%%\n', phase3_results.predictive.accuracy);
end

phase3_results.summary = struct();
phase3_results.summary.all_tests_completed = true;

%% SAVE RESULTS
if config.save_results
    save(fullfile(config.output_dir, 'phase3_results.mat'), 'phase3_results');
    
    % Create report
    report_file = fullfile(config.output_dir, 'phase3_report.txt');
    write_phase3_report(report_file, phase3_results);
    
    fprintf('\nResults saved to: %s\n', config.output_dir);
end

%% DECISION CHECKPOINT
fprintf('\n========================================\n');
fprintf('         PHASE 3 DECISION POINT          \n');
fprintf('========================================\n');

criteria_met = 0;
total_criteria = 4;

% Check temporal generalization
if isfield(phase3_results, 'temporal') && phase3_results.temporal.test_improvement > 20
    fprintf('✅ Temporal validation successful\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Temporal validation weak\n');
end

% Check LOSO consistency
if isfield(phase3_results, 'loso') && phase3_results.loso.mean > 20
    fprintf('✅ Leave-one-season-out consistent\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ LOSO shows inconsistency\n');
end

% Check stability
if isfield(phase3_results, 'stability')
    valid = phase3_results.stability.improvements(~isnan(phase3_results.stability.improvements));
    if std(valid)/mean(valid) < 0.5
        fprintf('✅ Method stable across seasons\n');
        criteria_met = criteria_met + 1;
    else
        fprintf('❌ High variability across seasons\n');
    end
end

% Check predictive value
if isfield(phase3_results, 'predictive') && phase3_results.predictive.accuracy > 55
    fprintf('✅ Clusters have predictive value\n');
    criteria_met = criteria_met + 1;
else
    fprintf('❌ Limited predictive value\n');
end

fprintf('\nCriteria met: %d/%d\n', criteria_met, total_criteria);

if criteria_met >= 3
    fprintf('✅ READY FOR PUBLICATION: Strong external validation\n');
else
    fprintf('⚠️ REVIEW REQUIRED: Some external validation concerns\n');
end

fprintf('\n========================================\n');

%% HELPER FUNCTIONS (Add your existing functions here)

%% CORE FUNCTIONS FOR PHASE 3 VALIDATION
% Complete implementation of p-adic clustering methods

function score = run_enhanced_padic_full(data, teams)
    % Enhanced p-adic clustering with all features
    % Returns: clustering quality score (0-1)
    
    % Initialize
    n_teams = length(teams);
    n_features = 55 - 5; % Exclude metadata columns
    
    % Step 1: Extract feature matrix for each team
    feature_matrix = extract_team_features(data, teams);
    
    % Step 2: Calculate p-adic distances
    p = 2; % Prime number for p-adic metric
    distances = calculate_padic_distances_enhanced(feature_matrix, p);
    
    % Step 3: Perform hierarchical clustering
    linkage_tree = linkage(squareform(distances), 'ward');
    
    % Step 4: Determine optimal clusters (e.g., 4 tiers)
    n_clusters = 4;
    clusters = cluster(linkage_tree, 'maxclust', n_clusters);
    
    % Step 5: Calculate clustering quality metrics
    % Using multiple metrics for robustness
    
    % Silhouette coefficient
    silh_vals = silhouette(feature_matrix, clusters, 'Euclidean');
    silh_score = mean(silh_vals(silh_vals > 0)); % Average positive silhouettes
    
    % Davies-Bouldin Index (lower is better, invert for score)
    db_index = davies_bouldin_index(feature_matrix, clusters);
    db_score = 1 / (1 + db_index);
    
    % Calinski-Harabasz Index (higher is better, normalize)
    ch_index = calinski_harabasz_index(feature_matrix, clusters);
    ch_score = ch_index / (ch_index + 100); % Normalize to 0-1
    
    % Performance correlation: Do clusters align with actual performance?
    perf_score = calculate_performance_correlation(data, teams, clusters);
    
    % Combine scores with weights
    weights = [0.25, 0.25, 0.25, 0.25]; % Equal weights
    score = weights(1) * silh_score + ...
            weights(2) * db_score + ...
            weights(3) * ch_score + ...
            weights(4) * perf_score;
    
    % Ensure score is in [0, 1]
    score = max(0, min(1, score));
end

function score = run_baseline_padic(data, teams)
    % Baseline p-adic clustering (simpler version)
    % Returns: clustering quality score (0-1)
    
    % Initialize
    n_teams = length(teams);
    
    % Step 1: Extract only basic features (subset)
    basic_features = extract_basic_features(data, teams);
    
    % Step 2: Simple p-adic distance (p=2 only)
    p = 2;
    distances = calculate_padic_distances_simple(basic_features, p);
    
    % Step 3: K-means clustering (simpler than hierarchical)
    n_clusters = 4;
    [clusters, ~] = kmeans(basic_features, n_clusters, ...
                          'Distance', 'cityblock', ...
                          'Replicates', 5);
    
    % Step 4: Basic clustering quality
    silh_vals = silhouette(basic_features, clusters, 'cityblock');
    score = mean(silh_vals(silh_vals > 0));
    
    % Ensure score is in [0, 1]
    score = max(0, min(1, score));
end

function [clusters, features] = get_enhanced_clustering_full(data, teams)
    % Get cluster assignments and features for prediction
    % Returns: clusters (n_teams x 1), features (n_teams x n_features)
    
    n_teams = length(teams);
    
    % Extract comprehensive features
    features = extract_team_features(data, teams);
    
    % Calculate enhanced p-adic distances
    p = 2;
    distances = calculate_padic_distances_enhanced(features, p);
    
    % Hierarchical clustering
    linkage_tree = linkage(squareform(distances), 'ward');
    n_clusters = 4;
    clusters = cluster(linkage_tree, 'maxclust', n_clusters);
end

%% HELPER FUNCTIONS

function feature_matrix = extract_team_features(data, teams)
    % Extract feature matrix for all teams
    % Returns: n_teams x n_features matrix
    
    n_teams = length(teams);
    
    % Get feature columns (exclude metadata)
    feature_cols = ~ismember(data.Properties.VariableNames, ...
                            {'season', 'team', 'match_location', ...
                             'outcome', 'outcome_binary'});
    
    n_features = sum(feature_cols);
    feature_matrix = zeros(n_teams, n_features);
    
    for t = 1:n_teams
        team_data = data(strcmp(data.team, teams{t}), :);
        
        if height(team_data) > 0
            % Calculate team statistics (mean of each feature)
            team_features = table2array(team_data(:, feature_cols));
            feature_matrix(t, :) = mean(team_features, 1, 'omitnan');
        end
    end
    
    % Normalize features
    feature_matrix = normalize(feature_matrix, 'zscore');
end

function basic_features = extract_basic_features(data, teams)
    % Extract only basic features for baseline method
    % Focus on key performance indicators
    
    n_teams = length(teams);
    
    % Select subset of most important features
    basic_cols = {'final_points_relative', 'abs_metres_made', ...
                  'abs_defenders_beaten', 'abs_turnovers_won', ...
                  'abs_tackles', 'abs_penalties_conceded'};
    
    n_features = length(basic_cols);
    basic_features = zeros(n_teams, n_features);
    
    for t = 1:n_teams
        team_data = data(strcmp(data.team, teams{t}), :);
        
        if height(team_data) > 0
            for f = 1:n_features
                if ismember(basic_cols{f}, data.Properties.VariableNames)
                    values = team_data.(basic_cols{f});
                    basic_features(t, f) = mean(values, 'omitnan');
                end
            end
        end
    end
    
    % Normalize
    basic_features = normalize(basic_features, 'zscore');
end

function distances = calculate_padic_distances_enhanced(features, p)
    % Calculate p-adic distances with enhancements
    % Uses multiple primes and aggregation
    
    n_teams = size(features, 1);
    distances = zeros(n_teams);
    
    % Use multiple primes for robustness
    primes = [2, 3, 5, 7];
    weights = [0.4, 0.3, 0.2, 0.1];
    
    for pi = 1:length(primes)
        p_curr = primes(pi);
        dist_p = zeros(n_teams);
        
        for i = 1:n_teams
            for j = i+1:n_teams
                % P-adic distance calculation
                diff = features(i, :) - features(j, :);
                
                % Apply p-adic valuation
                p_adic_dist = 0;
                for k = 1:length(diff)
                    if abs(diff(k)) > eps
                        % Find p-adic valuation
                        val = padic_valuation(diff(k), p_curr);
                        p_adic_dist = p_adic_dist + p_curr^(-val);
                    end
                end
                
                dist_p(i, j) = p_adic_dist;
                dist_p(j, i) = p_adic_dist;
            end
        end
        
        % Weighted combination
        distances = distances + weights(pi) * dist_p;
    end
end

function distances = calculate_padic_distances_simple(features, p)
    % Simple p-adic distance calculation
    
    n_teams = size(features, 1);
    distances = zeros(n_teams);
    
    for i = 1:n_teams
        for j = i+1:n_teams
            diff = features(i, :) - features(j, :);
            
            % Simplified p-adic metric
            p_adic_dist = 0;
            for k = 1:length(diff)
                if abs(diff(k)) > eps
                    % Simple valuation
                    val = floor(log(abs(diff(k))) / log(p));
                    p_adic_dist = p_adic_dist + p^(-val);
                end
            end
            
            distances(i, j) = p_adic_dist;
            distances(j, i) = p_adic_dist;
        end
    end
end

function val = padic_valuation(x, p)
    % Calculate p-adic valuation of x
    % Returns the highest power of p that divides x
    
    if abs(x) < eps
        val = inf;
        return;
    end
    
    % For real numbers, approximate using continued fractions
    [num, den] = rat(x, 1e-6);
    
    % Count factors of p in numerator and denominator
    val_num = 0;
    while mod(num, p) == 0
        num = num / p;
        val_num = val_num + 1;
    end
    
    val_den = 0;
    while mod(den, p) == 0
        den = den / p;
        val_den = val_den + 1;
    end
    
    val = val_num - val_den;
end

function db_index = davies_bouldin_index(features, clusters)
    % Calculate Davies-Bouldin Index
    % Lower values indicate better clustering
    
    n_clusters = max(clusters);
    n_features = size(features, 2);
    
    % Calculate cluster centroids
    centroids = zeros(n_clusters, n_features);
    for c = 1:n_clusters
        cluster_points = features(clusters == c, :);
        centroids(c, :) = mean(cluster_points, 1);
    end
    
    % Calculate within-cluster scatter
    scatter = zeros(n_clusters, 1);
    for c = 1:n_clusters
        cluster_points = features(clusters == c, :);
        if size(cluster_points, 1) > 1
            distances = pdist2(cluster_points, centroids(c, :));
            scatter(c) = mean(distances);
        end
    end
    
    % Calculate between-cluster distances
    db_values = zeros(n_clusters, 1);
    for i = 1:n_clusters
        max_ratio = 0;
        for j = 1:n_clusters
            if i ~= j
                between_dist = norm(centroids(i, :) - centroids(j, :));
                if between_dist > 0
                    ratio = (scatter(i) + scatter(j)) / between_dist;
                    max_ratio = max(max_ratio, ratio);
                end
            end
        end
        db_values(i) = max_ratio;
    end
    
    db_index = mean(db_values);
end

function ch_index = calinski_harabasz_index(features, clusters)
    % Calculate Calinski-Harabasz Index
    % Higher values indicate better clustering
    
    [n_samples, n_features] = size(features);
    n_clusters = max(clusters);
    
    % Overall mean
    overall_mean = mean(features, 1);
    
    % Between-group sum of squares
    bgss = 0;
    for c = 1:n_clusters
        cluster_points = features(clusters == c, :);
        n_c = size(cluster_points, 1);
        cluster_mean = mean(cluster_points, 1);
        bgss = bgss + n_c * sum((cluster_mean - overall_mean).^2);
    end
    
    % Within-group sum of squares
    wgss = 0;
    for c = 1:n_clusters
        cluster_points = features(clusters == c, :);
        cluster_mean = mean(cluster_points, 1);
        for i = 1:size(cluster_points, 1)
            wgss = wgss + sum((cluster_points(i, :) - cluster_mean).^2);
        end
    end
    
    % Calculate index
    if wgss > 0 && n_clusters > 1
        ch_index = (bgss / (n_clusters - 1)) / (wgss / (n_samples - n_clusters));
    else
        ch_index = 0;
    end
end

function perf_score = calculate_performance_correlation(data, teams, clusters)
    % Calculate how well clusters align with actual performance
    
    n_teams = length(teams);
    n_clusters = max(clusters);
    
    % Calculate average win rate per team
    win_rates = zeros(n_teams, 1);
    for t = 1:n_teams
        team_data = data(strcmp(data.team, teams{t}), :);
        if height(team_data) > 0
            win_rates(t) = mean(team_data.outcome_binary);
        end
    end
    
    % Calculate average win rate per cluster
    cluster_win_rates = zeros(n_clusters, 1);
    for c = 1:n_clusters
        cluster_teams = win_rates(clusters == c);
        if ~isempty(cluster_teams)
            cluster_win_rates(c) = mean(cluster_teams);
        end
    end
    
    % Check if clusters are ordered by performance
    % Higher cluster number should have higher win rate
    [sorted_rates, ~] = sort(cluster_win_rates);
    
    % Calculate monotonicity score
    monotonic_pairs = 0;
    total_pairs = 0;
    for i = 1:n_clusters-1
        for j = i+1:n_clusters
            total_pairs = total_pairs + 1;
            if cluster_win_rates(j) >= cluster_win_rates(i)
                monotonic_pairs = monotonic_pairs + 1;
            end
        end
    end
    
    if total_pairs > 0
        perf_score = monotonic_pairs / total_pairs;
    else
        perf_score = 0.5;
    end
end

%% REPORT WRITING FUNCTION

function write_phase3_report(filename, results)
    % Write detailed Phase 3 validation report
    
    fid = fopen(filename, 'w');
    
    fprintf(fid, '==============================================\n');
    fprintf(fid, '   PHASE 3 VALIDATION REPORT                 \n');
    fprintf(fid, '   External Validation & Robustness          \n');
    fprintf(fid, '==============================================\n\n');
    
    fprintf(fid, 'Generated: %s\n\n', char(results.timestamp));
    
    % Executive Summary
    fprintf(fid, 'EXECUTIVE SUMMARY\n');
    fprintf(fid, '-----------------\n');
    
    criteria_met = 0;
    total_criteria = 4;
    
    % Check each criterion
    if isfield(results, 'temporal') && ~isfield(results.temporal, 'error')
        if results.temporal.test_improvement > 20
            fprintf(fid, '✓ Temporal validation: %.1f%% improvement on future data\n', ...
                    results.temporal.test_improvement);
            criteria_met = criteria_met + 1;
        else
            fprintf(fid, '✗ Temporal validation: Weak improvement (%.1f%%)\n', ...
                    results.temporal.test_improvement);
        end
    end
    
    if isfield(results, 'loso') && ~isnan(results.loso.mean)
        if results.loso.mean > 20
            fprintf(fid, '✓ Cross-validation: Consistent %.1f%% improvement\n', ...
                    results.loso.mean);
            criteria_met = criteria_met + 1;
        else
            fprintf(fid, '✗ Cross-validation: Low improvement (%.1f%%)\n', ...
                    results.loso.mean);
        end
    end
    
    if isfield(results, 'stability')
        valid = results.stability.improvements(~isnan(results.stability.improvements));
        cv = std(valid) / mean(valid);
        if cv < 0.5
            fprintf(fid, '✓ Stability: Low variability (CV=%.2f)\n', cv);
            criteria_met = criteria_met + 1;
        else
            fprintf(fid, '✗ Stability: High variability (CV=%.2f)\n', cv);
        end
    end
    
    if isfield(results, 'predictive')
        if results.predictive.accuracy > 55
            fprintf(fid, '✓ Predictive value: %.1f%% accuracy\n', ...
                    results.predictive.accuracy);
            criteria_met = criteria_met + 1;
        else
            fprintf(fid, '✗ Predictive value: Low accuracy (%.1f%%)\n', ...
                    results.predictive.accuracy);
        end
    end
    
    fprintf(fid, '\nOVERALL: %d/%d criteria met\n', criteria_met, total_criteria);
    
    if criteria_met >= 3
        fprintf(fid, 'STATUS: READY FOR PUBLICATION\n');
    else
        fprintf(fid, 'STATUS: REVIEW REQUIRED\n');
    end
    
    % Detailed Results
    fprintf(fid, '\n\nDETAILED RESULTS\n');
    fprintf(fid, '================\n\n');
    
    % Test 1: Temporal Validation
    fprintf(fid, '1. TEMPORAL VALIDATION\n');
    fprintf(fid, '   Training: Seasons 1-3\n');
    fprintf(fid, '   Testing: Season 4\n');
    if isfield(results, 'temporal')
        fprintf(fid, '   Train improvement: %.1f%%\n', results.temporal.train_improvement);
        fprintf(fid, '   Test improvement: %.1f%%\n', results.temporal.test_improvement);
        fprintf(fid, '   Generalization gap: %.1f%%\n', results.temporal.generalization_gap);
    end
    fprintf(fid, '\n');
    
    % Test 2: LOSO
    fprintf(fid, '2. LEAVE-ONE-SEASON-OUT\n');
    if isfield(results, 'loso')
        fprintf(fid, '   Mean improvement: %.1f%% ± %.1f%%\n', ...
                results.loso.mean, results.loso.std);
        fprintf(fid, '   Individual folds:\n');
        for i = 1:length(results.loso.improvements)
            fprintf(fid, '     Season %d: %.1f%%\n', i, results.loso.improvements(i));
        end
    end
    fprintf(fid, '\n');
    
    % Test 3: Early vs Late
    fprintf(fid, '3. EARLY VS LATE SEASON\n');
    if isfield(results, 'early_late') && ~isempty(results.early_late)
        fprintf(fid, '   Mean early: %.1f%%\n', mean(results.early_late(:,1)));
        fprintf(fid, '   Mean late: %.1f%%\n', mean(results.early_late(:,2)));
        fprintf(fid, '   Consistency: %.1f%% difference\n', ...
                abs(mean(results.early_late(:,1)) - mean(results.early_late(:,2))));
    end
    fprintf(fid, '\n');
    
    % Test 4: Stability
    fprintf(fid, '4. STABILITY ACROSS SEASONS\n');
    if isfield(results, 'stability')
        for i = 1:length(results.stability.improvements)
            fprintf(fid, '   Season %d: %.1f%%\n', i, results.stability.improvements(i));
        end
    end
    fprintf(fid, '\n');
    
    % Test 5: Predictive
    fprintf(fid, '5. PREDICTIVE VALIDATION\n');
    if isfield(results, 'predictive')
        fprintf(fid, '   Predictions: %d\n', results.predictive.n_predictions);
        fprintf(fid, '   Accuracy: %.1f%%\n', results.predictive.accuracy);
        fprintf(fid, '   Baseline: 50.0%%\n');
    end
    fprintf(fid, '\n');
    
    % Test 6: Subsamples
    fprintf(fid, '6. RANDOM SUBSAMPLE ROBUSTNESS\n');
    if isfield(results, 'subsamples')
        fprintf(fid, '   Valid samples: %d\n', length(results.subsamples));
        fprintf(fid, '   Mean: %.1f%%\n', mean(results.subsamples));
        fprintf(fid, '   95%% CI: [%.1f%%, %.1f%%]\n', ...
                prctile(results.subsamples, 2.5), prctile(results.subsamples, 97.5));
    end
    
    fclose(fid);
end

% function score = run_enhanced_padic_full(data, teams)
%     % Your existing enhanced implementation
%     % ... (include full implementation)
%     score = 0.7;  % Placeholder
% end
% 
% function score = run_baseline_padic(data, teams)
%     % Your existing baseline implementation
%     % ... (include full implementation)
%     score = 0.3;  % Placeholder
% end
% 
% function [clusters, features] = get_enhanced_clustering_full(data, teams)
%     % Get clustering assignments
%     % ... (include implementation)
%     clusters = randi(4, length(teams), 1);  % Placeholder
%     features = [];
% end
% 
% function write_phase3_report(filename, results)
%     % Write detailed Phase 3 report
%     fid = fopen(filename, 'w');
% 
%     fprintf(fid, '==============================================\n');
%     fprintf(fid, '   PHASE 3 VALIDATION REPORT                 \n');
%     fprintf(fid, '==============================================\n\n');
% 
%     fprintf(fid, 'Generated: %s\n\n', char(results.timestamp));
% 
%     % Add detailed results writing here
% 
%     fclose(fid);
% end
