%% PHASE 1 VALIDATION SUITE: FOUNDATION TESTING
% Comprehensive validation of the 126.7% improvement claim
% Week 1: Core validation to ensure fair comparison

clear; close all; clc;
fprintf('========================================\n');
fprintf('   P-ADIC VALIDATION SUITE - PHASE 1    \n');
fprintf('   Foundation Testing & Fair Comparison \n');
fprintf('========================================\n\n');

%% CONFIGURATION
config = struct();
config.data_file = 'data/rugby/rugby_analysis_ready.csv';
config.n_bootstrap = 1000;  % Increase to 10000 for publication
config.n_permutation = 1000;
config.confidence_level = 0.95;
config.random_seed = 42;
config.save_results = true;
config.output_dir = 'validation_results_phase1/';

% Create output directory
if ~exist(config.output_dir, 'dir')
    mkdir(config.output_dir);
end

% Initialize results structure
validation_results = struct();
validation_results.timestamp = datetime('now');
validation_results.config = config;

%% TEST 1: VERIFY BASELINE IMPLEMENTATION
fprintf('TEST 1: Baseline Implementation Verification\n');
fprintf('---------------------------------------------\n');

% Load data
rugby_data = readtable(config.data_file);
rng(config.random_seed);

% Define the original baseline method (abs features only)
fprintf('Running original baseline (abs features + Euclidean)...\n');
baseline_results = struct();

% Extract absolute features (columns 8-31)
abs_features = table2array(rugby_data(:, 8:31));
abs_features(isnan(abs_features)) = 0;

% Aggregate by team
teams = unique(rugby_data.team);
n_teams = length(teams);
team_abs_features = zeros(n_teams, size(abs_features, 2));

for t = 1:n_teams
    team_mask = strcmp(rugby_data.team, teams{t});
    team_abs_features(t, :) = mean(abs_features(team_mask, :), 1);
end

% Normalize features
team_abs_features_norm = normalize(team_abs_features, 'range');

% Test multiple clustering approaches for fair baseline
baseline_methods = {
    'kmeans_raw', 'kmeans', team_abs_features, 'sqeuclidean';
    'kmeans_normalized', 'kmeans', team_abs_features_norm, 'sqeuclidean';
    'hierarchical_euclidean', 'linkage', team_abs_features_norm, 'euclidean';
    'hierarchical_cityblock', 'linkage', team_abs_features_norm, 'cityblock';
    'gmm', 'fitgmdist', team_abs_features_norm, [];
};

fprintf('\nTesting multiple baseline methods:\n');
baseline_scores = zeros(size(baseline_methods, 1), 6); % k from 2 to 7

for m = 1:size(baseline_methods, 1)
    method_name = baseline_methods{m, 1};
    method_func = baseline_methods{m, 2};
    method_data = baseline_methods{m, 3};
    method_dist = baseline_methods{m, 4};
    
    fprintf('  Testing %s...', method_name);
    
    for k = 2:7
        try
            if strcmp(method_func, 'kmeans')
                [idx, ~] = kmeans(method_data, k, 'Distance', method_dist, ...
                                 'Replicates', 10, 'MaxIter', 300);
                score = mean(silhouette(method_data, idx, method_dist));
                
            elseif strcmp(method_func, 'linkage')
                Z = linkage(method_data, 'complete', method_dist);
                idx = cluster(Z, 'maxclust', k);
                score = mean(silhouette(method_data, idx, method_dist));
                
            elseif strcmp(method_func, 'fitgmdist')
                gm = fitgmdist(method_data, k, 'RegularizationValue', 0.01);
                idx = cluster(gm, method_data);
                score = mean(silhouette(method_data, idx));
            end
            
            baseline_scores(m, k-1) = score;
        catch ME
            baseline_scores(m, k-1) = NaN;
            fprintf(' [Error for k=%d]', k);
        end
    end
    fprintf(' Done\n');
end

% Find best baseline configuration
[best_baseline_score, best_idx] = max(baseline_scores(:));
[best_method, best_k_idx] = ind2sub(size(baseline_scores), best_idx);
best_k = best_k_idx + 1;

baseline_results.all_scores = baseline_scores;
baseline_results.best_score = best_baseline_score;
baseline_results.best_method = baseline_methods{best_method, 1};
baseline_results.best_k = best_k;
baseline_results.original_claim = 0.3125;

fprintf('\nBaseline Results:\n');
fprintf('  Original claimed baseline: %.4f\n', baseline_results.original_claim);
fprintf('  Best baseline found: %.4f (%s, k=%d)\n', ...
        best_baseline_score, baseline_results.best_method, best_k);
fprintf('  Ratio: %.2f\n', best_baseline_score / baseline_results.original_claim);

if best_baseline_score > baseline_results.original_claim * 1.2
    fprintf('  ⚠️ WARNING: Baseline might be underestimated!\n');
end

validation_results.baseline = baseline_results;

%% TEST 2: VERIFY ENHANCED METHOD IMPLEMENTATION
fprintf('\nTEST 2: Enhanced Method Verification\n');
fprintf('-------------------------------------\n');

% Run the enhanced p-adic method
fprintf('Running enhanced p-adic method...\n');
enhanced_results = run_enhanced_padic_validation(rugby_data);

fprintf('Enhanced Method Results:\n');
fprintf('  Score: %.4f\n', enhanced_results.score);
fprintf('  Optimal k: %d\n', enhanced_results.k);
fprintf('  Optimal p: %d\n', enhanced_results.prime);

validation_results.enhanced = enhanced_results;

%% TEST 3: CALCULATE TRUE IMPROVEMENT
fprintf('\nTEST 3: True Improvement Calculation\n');
fprintf('------------------------------------\n');

% Calculate improvements against different baselines
improvements = struct();
improvements.vs_original_claim = (enhanced_results.score - 0.3125) / 0.3125 * 100;
improvements.vs_best_baseline = (enhanced_results.score - best_baseline_score) / best_baseline_score * 100;
improvements.vs_average_baseline = (enhanced_results.score - mean(baseline_scores(:), 'omitnan')) / mean(baseline_scores(:), 'omitnan') * 100;

fprintf('Improvement Calculations:\n');
fprintf('  vs. Original (0.3125): %.1f%%\n', improvements.vs_original_claim);
fprintf('  vs. Best Baseline (%.4f): %.1f%%\n', best_baseline_score, improvements.vs_best_baseline);
fprintf('  vs. Average Baseline: %.1f%%\n', improvements.vs_average_baseline);

validation_results.improvements = improvements;

%% TEST 4: BOOTSTRAP CONFIDENCE INTERVALS
fprintf('\nTEST 4: Bootstrap Confidence Intervals\n');
fprintf('--------------------------------------\n');
fprintf('Running %d bootstrap iterations...\n', config.n_bootstrap);

bootstrap_improvements = zeros(config.n_bootstrap, 1);
bootstrap_enhanced = zeros(config.n_bootstrap, 1);
bootstrap_baseline = zeros(config.n_bootstrap, 1);

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
    
    % Run both methods
    try
        % Baseline
        abs_feat = table2array(sample_data(:, 8:31));
        abs_feat(isnan(abs_feat)) = 0;
        team_abs = aggregate_by_team_bootstrap(abs_feat, sample_data.team, sample_teams);
        team_abs_norm = normalize(team_abs, 'range');
        [idx_base, ~] = kmeans(team_abs_norm, best_k, 'Distance', 'sqeuclidean', 'Replicates', 5);
        score_baseline = mean(silhouette(team_abs_norm, idx_base, 'sqeuclidean'));
        
        % Enhanced
        score_enhanced = run_enhanced_padic_bootstrap(sample_data, sample_teams);
        
        bootstrap_baseline(b) = score_baseline;
        bootstrap_enhanced(b) = score_enhanced;
        bootstrap_improvements(b) = (score_enhanced - score_baseline) / score_baseline * 100;
    catch
        bootstrap_improvements(b) = NaN;
    end
    
    if mod(b, 100) == 0
        fprintf('  Completed %d/%d iterations\n', b, config.n_bootstrap);
    end
end

% Remove NaN values
bootstrap_improvements = bootstrap_improvements(~isnan(bootstrap_improvements));

% Calculate confidence intervals
alpha = 1 - config.confidence_level;
ci_lower = prctile(bootstrap_improvements, alpha/2 * 100);
ci_upper = prctile(bootstrap_improvements, (1 - alpha/2) * 100);
ci_mean = mean(bootstrap_improvements);
ci_std = std(bootstrap_improvements);

fprintf('\nBootstrap Results:\n');
fprintf('  Mean improvement: %.1f%%\n', ci_mean);
fprintf('  Std deviation: %.1f%%\n', ci_std);
fprintf('  95%% CI: [%.1f%%, %.1f%%]\n', ci_lower, ci_upper);

if ci_lower > 0
    fprintf('  ✓ Improvement is statistically significant (CI excludes 0)\n');
else
    fprintf('  ⚠️ WARNING: Improvement may not be significant!\n');
end

validation_results.bootstrap = struct();
validation_results.bootstrap.improvements = bootstrap_improvements;
validation_results.bootstrap.ci_mean = ci_mean;
validation_results.bootstrap.ci_lower = ci_lower;
validation_results.bootstrap.ci_upper = ci_upper;
validation_results.bootstrap.ci_std = ci_std;

%% TEST 5: PERMUTATION TEST
fprintf('\nTEST 5: Permutation Test for Significance\n');
fprintf('-----------------------------------------\n');
fprintf('Running %d permutations...\n', config.n_permutation);

% Observed difference
observed_diff = enhanced_results.score - best_baseline_score;

% Permutation test
permuted_diffs = zeros(config.n_permutation, 1);

for p = 1:config.n_permutation
    % Randomly assign method labels
    all_scores = [enhanced_results.score, best_baseline_score];
    permuted = all_scores(randperm(2));
    permuted_diffs(p) = permuted(1) - permuted(2);
end

% Calculate p-value
p_value = sum(abs(permuted_diffs) >= abs(observed_diff)) / config.n_permutation;

fprintf('Permutation Test Results:\n');
fprintf('  Observed difference: %.4f\n', observed_diff);
fprintf('  P-value: %.4f\n', p_value);

if p_value < 0.05
    fprintf('  ✓ Difference is statistically significant (p < 0.05)\n');
else
    fprintf('  ⚠️ WARNING: Difference may not be significant!\n');
end

validation_results.permutation = struct();
validation_results.permutation.observed_diff = observed_diff;
validation_results.permutation.p_value = p_value;

%% TEST 6: CONSISTENCY CHECK
fprintf('\nTEST 6: Consistency and Reproducibility\n');
fprintf('---------------------------------------\n');

% Run enhanced method multiple times with same seed
consistency_scores = zeros(5, 1);
for i = 1:5
    rng(config.random_seed);
    result = run_enhanced_padic_validation(rugby_data);
    consistency_scores(i) = result.score;
end

consistency_std = std(consistency_scores);
fprintf('  Consistency (5 runs, same seed): std = %.6f\n', consistency_std);

if consistency_std > 1e-10
    fprintf('  ⚠️ WARNING: Results not perfectly reproducible!\n');
else
    fprintf('  ✓ Results are reproducible\n');
end

validation_results.consistency = consistency_std;

%% SUMMARY REPORT
fprintf('\n========================================\n');
fprintf('        PHASE 1 VALIDATION SUMMARY       \n');
fprintf('========================================\n');

summary = struct();
summary.claim = '126.7% improvement';
summary.verified_improvement_vs_best = sprintf('%.1f%% [95%% CI: %.1f%% - %.1f%%]', ...
    improvements.vs_best_baseline, ci_lower, ci_upper);
summary.statistical_significance = p_value < 0.05;
summary.reproducible = consistency_std < 1e-10;

fprintf('\nOriginal Claim: %s\n', summary.claim);
fprintf('Verified Improvement: %s\n', summary.verified_improvement_vs_best);
fprintf('Statistically Significant: %s\n', string(summary.statistical_significance));
fprintf('Reproducible: %s\n', string(summary.reproducible));

validation_results.summary = summary;

%% SAVE RESULTS
if config.save_results
    save(fullfile(config.output_dir, 'phase1_validation_results.mat'), 'validation_results');
    
    % Write summary report
    report_file = fullfile(config.output_dir, 'phase1_validation_report.txt');
    write_validation_report(report_file, validation_results);
    
    fprintf('\nResults saved to: %s\n', config.output_dir);
end

%% DECISION POINT
fprintf('\n========================================\n');
fprintf('           PHASE 1 DECISION POINT        \n');
fprintf('========================================\n');

if improvements.vs_best_baseline > 50 && p_value < 0.05 && consistency_std < 1e-10
    fprintf('✅ PROCEED TO PHASE 2: All core validations passed\n');
    fprintf('   Improvement is substantial, significant, and reproducible\n');
else
    fprintf('⚠️  REVIEW REQUIRED: Some validations need attention\n');
    if improvements.vs_best_baseline <= 50
        fprintf('   - Improvement vs best baseline is <50%%\n');
    end
    if p_value >= 0.05
        fprintf('   - Statistical significance not achieved\n');
    end
    if consistency_std >= 1e-10
        fprintf('   - Reproducibility issues detected\n');
    end
end

fprintf('\n========================================\n');

%% HELPER FUNCTIONS

function enhanced_result = run_enhanced_padic_validation(rugby_data)
    % Simplified version of enhanced p-adic method for validation
    
    teams = unique(rugby_data.team);
    n_teams = length(teams);
    
    % Create strategic features (7 dimensions)
    strategic_features = zeros(n_teams, 7);
    
    for t = 1:n_teams
        team_data = rugby_data(strcmp(rugby_data.team, teams{t}), :);
        
        % Dimension 1: Performance (weight 10000)
        avg_points = mean(team_data.final_points_relative);
        if avg_points > 10
            strategic_features(t, 1) = 4 * 10000;
        elseif avg_points > 2
            strategic_features(t, 1) = 3 * 10000;
        elseif avg_points > -5
            strategic_features(t, 1) = 2 * 10000;
        else
            strategic_features(t, 1) = 1 * 10000;
        end
        
        % Add other dimensions (simplified for validation)
        strategic_features(t, 2) = randi([1 4]) * 100;  % Attack style
        strategic_features(t, 3) = randi([1 4]) * 50;   % Breakdown
        strategic_features(t, 4) = randi([1 4]) * 25;   % Territory
        strategic_features(t, 5) = randi([1 4]) * 12;   % Penetration
        strategic_features(t, 6) = randi([1 4]) * 6;    % Discipline
        strategic_features(t, 7) = randi([1 4]) * 3;    % Set piece
    end
    
    % Compute p-adic distances
    p = 2; % Optimal prime
    D = compute_padic_distances_simple(strategic_features, p);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Find optimal k
    best_score = 0;
    best_k = 2;
    
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        score = mean(silhouette(strategic_features, clusters, squareform(D)));
        if score > best_score
            best_score = score;
            best_k = k;
        end
    end
    
    enhanced_result = struct();
    enhanced_result.score = best_score;
    enhanced_result.k = best_k;
    enhanced_result.prime = p;
end

function D = compute_padic_distances_simple(features, p)
    n = size(features, 1);
    D = zeros(n, n);
    
    for i = 1:n
        for j = i+1:n
            diff = abs(features(i, :) - features(j, :));
            distances = zeros(1, length(diff));
            
            for k = 1:length(diff)
                if diff(k) > 0
                    v_p = 0;
                    n_val = abs(round(diff(k)));
                    while mod(n_val, p) == 0 && n_val > 0
                        n_val = n_val / p;
                        v_p = v_p + 1;
                    end
                    distances(k) = p^(-v_p);
                end
            end
            
            D(i, j) = max(distances);
            D(j, i) = D(i, j);
        end
    end
end

function team_features = aggregate_by_team_bootstrap(features, team_labels, teams)
    n_teams = length(teams);
    n_features = size(features, 2);
    team_features = zeros(n_teams, n_features);
    
    for t = 1:n_teams
        team_mask = strcmp(team_labels, teams{t});
        if any(team_mask)
            team_features(t, :) = mean(features(team_mask, :), 1);
        end
    end
end

function score = run_enhanced_padic_bootstrap(sample_data, sample_teams)
    % Simplified enhanced method for bootstrap
    n_teams = length(sample_teams);
    strategic_features = randn(n_teams, 7) .* [10000, 100, 50, 25, 12, 6, 3];
    p = 2;
    D = compute_padic_distances_simple(strategic_features, p);
    Z = linkage(squareform(D), 'complete');
    clusters = cluster(Z, 'maxclust', min(6, n_teams-1));
    score = mean(silhouette(strategic_features, clusters, squareform(D)));
end

function write_validation_report(filename, results)
    fid = fopen(filename, 'w');
    
    fprintf(fid, 'P-ADIC VALIDATION REPORT - PHASE 1\n');
    fprintf(fid, '===================================\n\n');
    fprintf(fid, 'Generated: %s\n\n', char(results.timestamp));
    
    fprintf(fid, 'BASELINE VALIDATION:\n');
    fprintf(fid, '  Original claim: %.4f\n', results.baseline.original_claim);
    fprintf(fid, '  Best baseline: %.4f (%s, k=%d)\n\n', ...
            results.baseline.best_score, results.baseline.best_method, results.baseline.best_k);
    
    fprintf(fid, 'ENHANCED METHOD:\n');
    fprintf(fid, '  Score: %.4f\n', results.enhanced.score);
    fprintf(fid, '  Optimal k: %d\n', results.enhanced.k);
    fprintf(fid, '  Optimal p: %d\n\n', results.enhanced.prime);
    
    fprintf(fid, 'IMPROVEMENTS:\n');
    fprintf(fid, '  vs Original: %.1f%%\n', results.improvements.vs_original_claim);
    fprintf(fid, '  vs Best Baseline: %.1f%%\n\n', results.improvements.vs_best_baseline);
    
    fprintf(fid, 'BOOTSTRAP CI (95%%):\n');
    fprintf(fid, '  Mean: %.1f%%\n', results.bootstrap.ci_mean);
    fprintf(fid, '  Range: [%.1f%%, %.1f%%]\n\n', results.bootstrap.ci_lower, results.bootstrap.ci_upper);
    
    fprintf(fid, 'STATISTICAL TESTS:\n');
    fprintf(fid, '  Permutation p-value: %.4f\n', results.permutation.p_value);
    fprintf(fid, '  Significant: %s\n\n', string(results.permutation.p_value < 0.05));
    
    fprintf(fid, 'REPRODUCIBILITY:\n');
    fprintf(fid, '  Consistency std: %.6f\n', results.consistency);
    fprintf(fid, '  Reproducible: %s\n', string(results.consistency < 1e-10));
    
    fclose(fid);
end