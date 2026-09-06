function results = enhanced_padic_rugby_pipeline(rugby_csv_file)
%% ENHANCED P-ADIC RUGBY ANALYSIS WITH ABS/REL OPTIMIZATION
% Integrates your existing p-adic framework with abs/rel categorical encoding
% 
% Builds on your compute_padic_distances function but creates better
% categorical inputs using the abs/rel structure
%
% Input: rugby_csv_file - path to your rugby_analysis_ready.csv
% Output: Enhanced p-adic clustering results
clear; close all; clc;
fprintf('╔══════════════════════════════════════════════════════════╗\n');
fprintf('║   P-ADIC RUGBY ENHANCED: ABS/REL → CATEGORICAL → P-ADIC   ║\n');
fprintf('╚══════════════════════════════════════════════════════════╝\n\n');

%% STEP 1: LOAD AND STRUCTURE DATA
fprintf('【1】 ANALYZING ABS/REL STRUCTURE FOR P-ADIC ENCODING\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

if nargin < 1
    rugby_csv_file = 'data/rugby/rugby_analysis_ready.csv';
end

rugby_data = readtable(rugby_csv_file);
teams = unique(rugby_data.team);
n_teams = length(teams);

fprintf('✓ Data loaded: %d matches, %d teams\n', height(rugby_data), n_teams);

%% STEP 2: CREATE P-ADIC OPTIMAL CATEGORICAL FEATURES
fprintf('\n【2】 CREATING P-ADIC OPTIMAL CATEGORIES\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% Your p-adic approach works best with discrete categories
% We'll create these from abs/rel combinations
padic_features = zeros(n_teams, 7); % 7 strategic dimensions

for t = 1:n_teams
    team_matches = rugby_data(strcmp(rugby_data.team, teams{t}), :);
    
    fprintf('  Processing %s (%d matches)...\n', teams{t}, height(team_matches));
    
    %% DIMENSION 1: PERFORMANCE TIER (Most Important - Weight x10000)
    % Use relative points to determine tier
    avg_points_diff = mean(team_matches.final_points_relative);
    if avg_points_diff > 10
        padic_features(t, 1) = 4 * 10000; % Elite
    elseif avg_points_diff > 2
        padic_features(t, 1) = 3 * 10000; % Strong
    elseif avg_points_diff > -5
        padic_features(t, 1) = 2 * 10000; % Competitive
    else
        padic_features(t, 1) = 1 * 10000; % Developing
    end
    
    %% DIMENSION 2: ATTACKING STYLE (Abs metrics for capability)
    % Use absolute carries vs passes to determine style
    avg_carries = mean(team_matches.abs_carries);
    avg_passes = mean(team_matches.abs_passes);
    carry_pass_ratio = avg_carries / (avg_passes + 1);
    
    if carry_pass_ratio > 0.8
        padic_features(t, 2) = 4 * 100; % Forward-dominant
    elseif carry_pass_ratio > 0.6
        padic_features(t, 2) = 3 * 100; % Balanced forward
    elseif carry_pass_ratio > 0.4
        padic_features(t, 2) = 2 * 100; % Balanced back
    else
        padic_features(t, 2) = 1 * 100; % Back-dominant
    end
    
    %% DIMENSION 3: BREAKDOWN MASTERY (Rel metrics for dominance)
    % Use relative turnovers to show competitive edge
    turnover_differential = mean(team_matches.rel_turnovers_won - team_matches.rel_turnovers_conceded);
    
    if turnover_differential > 2
        padic_features(t, 3) = 4 * 50; % Dominant
    elseif turnover_differential > 0
        padic_features(t, 3) = 3 * 50; % Strong
    elseif turnover_differential > -2
        padic_features(t, 3) = 2 * 50; % Competitive
    else
        padic_features(t, 3) = 1 * 50; % Struggling
    end
    
    %% DIMENSION 4: TERRITORY CONTROL (Abs kicking strategy)
    avg_kicks = mean(team_matches.abs_kicks_from_hand);
    
    if avg_kicks > 20
        padic_features(t, 4) = 4 * 25; % High kicking
    elseif avg_kicks > 15
        padic_features(t, 4) = 3 * 25; % Moderate kicking
    elseif avg_kicks > 10
        padic_features(t, 4) = 2 * 25; % Low kicking
    else
        padic_features(t, 4) = 1 * 25; % Minimal kicking
    end
    
    %% DIMENSION 5: PENETRATION ABILITY (Rel clean breaks)
    avg_clean_breaks_diff = mean(team_matches.rel_clean_breaks);
    
    if avg_clean_breaks_diff > 2
        padic_features(t, 5) = 4 * 12; % Elite penetration
    elseif avg_clean_breaks_diff > 0
        padic_features(t, 5) = 3 * 12; % Good penetration
    elseif avg_clean_breaks_diff > -1
        padic_features(t, 5) = 2 * 12; % Average penetration
    else
        padic_features(t, 5) = 1 * 12; % Poor penetration
    end
    
    %% DIMENSION 6: DISCIPLINE (Rel penalties)
    avg_penalty_diff = mean(team_matches.rel_penalties_conceded);
    
    if avg_penalty_diff < -2
        padic_features(t, 6) = 4 * 6; % Very disciplined
    elseif avg_penalty_diff < 0
        padic_features(t, 6) = 3 * 6; % Disciplined
    elseif avg_penalty_diff < 2
        padic_features(t, 6) = 2 * 6; % Average discipline
    else
        padic_features(t, 6) = 1 * 6; % Undisciplined
    end
    
    %% DIMENSION 7: SET PIECE PLATFORM (Abs scrums + lineouts)
    avg_scrums = mean(team_matches.abs_scrums_won);
    avg_lineouts = mean(team_matches.abs_lineout_throws_won);
    set_piece_total = avg_scrums + avg_lineouts;
    
    if set_piece_total > 25
        padic_features(t, 7) = 4 * 3; % Strong platform
    elseif set_piece_total > 20
        padic_features(t, 7) = 3 * 3; % Good platform
    elseif set_piece_total > 15
        padic_features(t, 7) = 2 * 3; % Average platform
    else
        padic_features(t, 7) = 1 * 3; % Weak platform
    end
end

%% STEP 3: ENHANCED P-ADIC DISTANCE CALCULATION
fprintf('\n【3】 COMPUTING ENHANCED P-ADIC DISTANCES\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% Test multiple primes for optimal results
primes_to_test = [2, 3, 5, 7];
best_score = 0;
best_prime = 2;
best_clusters = [];

for p = primes_to_test
    fprintf('  Testing p = %d...\n', p);
    
    % Use your existing p-adic distance function
    D = compute_padic_distances_enhanced(padic_features, p);
    
    % Hierarchical clustering
    Z = linkage(squareform(D), 'complete');
    
    % Test optimal k
    silhouette_scores = [];
    for k = 2:min(6, n_teams-1)
        clusters = cluster(Z, 'maxclust', k);
        %score = mean(silhouette(padic_features, clusters, D));
        condensed_D = squareform(D);  % Convert to condensed form
        score = mean(silhouette(padic_features, clusters, condensed_D));

        silhouette_scores(end+1) = score;
        
        if score > best_score
            best_score = score;
            best_prime = p;
            best_clusters = clusters;
            best_k = k;
        end
    end
    
    max_score_for_p = max(silhouette_scores);
    fprintf('    Best silhouette for p=%d: %.4f\n', p, max_score_for_p);
end

fprintf('\n🏆 OPTIMAL P-ADIC CONFIGURATION:\n');
fprintf('   Prime p = %d\n', best_prime);
fprintf('   Clusters k = %d\n', best_k);
fprintf('   Silhouette = %.4f\n', best_score);

%% STEP 4: ANALYZE CLUSTERS BY STRATEGIC DIMENSIONS
fprintf('\n【4】 STRATEGIC CLUSTER ANALYSIS\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

dimension_names = {'Performance_Tier', 'Attacking_Style', 'Breakdown_Mastery', ...
                   'Territory_Control', 'Penetration_Ability', 'Discipline', 'Set_Piece_Platform'};

for cluster_id = 1:best_k
    cluster_teams = teams(best_clusters == cluster_id);
    cluster_features = padic_features(best_clusters == cluster_id, :);
    
    fprintf('\n► CLUSTER %d (%d teams):\n', cluster_id, length(cluster_teams));
    fprintf('  Teams: %s\n', strjoin(cluster_teams, ', '));
    
    % Decode strategic characteristics
    avg_features = mean(cluster_features, 1);
    for dim = 1:7
        fprintf('  %s: %s\n', dimension_names{dim}, decode_strategic_value(avg_features(dim), dim));
    end
end

%% STEP 5: COMPARISON WITH YOUR EXISTING APPROACH
fprintf('\n【5】 PERFORMANCE COMPARISON\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% Test your original approach (abs features only)
abs_features = table2array(rugby_data(:, 8:31)); % Your original columns
abs_features(isnan(abs_features)) = 0;
team_abs_features = aggregate_by_team(abs_features, rugby_data.team, teams);
team_abs_features = normalize(team_abs_features, 'range');

% Convert to categories for fair comparison
categorical_abs = discretize_features_for_padic(team_abs_features);
D_original = compute_padic_distances_enhanced(categorical_abs, best_prime);
Z_original = linkage(squareform(D_original), 'complete');
clusters_original = cluster(Z_original, 'maxclust', best_k);

%score_original = mean(silhouette(categorical_abs, clusters_original, D_original));
% Convert to full distance matrix if needed
condensed_D = squareform(D_original);  % Convert to full form
% Calculate silhouette scores
score_original = mean(silhouette(categorical_abs, clusters_original, condensed_D));


fprintf('📊 RESULTS COMPARISON:\n');
fprintf('   Enhanced abs/rel approach: %.4f\n', best_score);
fprintf('   Original abs-only approach: %.4f\n', score_original);
fprintf('   Improvement: %.1f%%\n', 100 * (best_score - score_original) / score_original);

%% STEP 6: SAVE ENHANCED RESULTS
results = struct();
results.best_score = best_score;
results.best_prime = best_prime;
results.best_k = best_k;
results.clusters = best_clusters;
results.teams = teams;
results.padic_features = padic_features;
results.dimension_names = dimension_names;
results.improvement_over_original = 100 * (best_score - score_original) / score_original;

save('enhanced_padic_rugby_results.mat', 'results');

fprintf('\n✓ Enhanced results saved to enhanced_padic_rugby_results.mat\n');

end

%% ENHANCED P-ADIC DISTANCE FUNCTION (Building on your implementation)
function D = compute_padic_distances_enhanced(features, p)
    % Enhanced version of your compute_padic_distances function
    % Optimized for hierarchical categorical features
    
    n = size(features, 1);
    D = zeros(n, n);
    
    for i = 1:n
        for j = i+1:n
            % Compute differences
            diff = abs(features(i, :) - features(j, :));
            
            % P-adic distance calculation (enhanced for hierarchy)
            distances = zeros(1, length(diff));
            for k = 1:length(diff)
                if diff(k) > 0
                    % Enhanced calculation prioritizing hierarchical differences
                    v_p = compute_padic_valuation_enhanced(diff(k), p);
                    distances(k) = p^(-v_p);
                else
                    distances(k) = 0;
                end
            end
            
            % Ultrametric: maximum distance (your existing approach)
            D(i, j) = max(distances);
            D(j, i) = D(i, j);
        end
    end
end

function valuation = compute_padic_valuation_enhanced(n, p)
    % Enhanced p-adic valuation for strategic hierarchies
    
    if n == 0
        valuation = Inf;
        return;
    end
    
    n = abs(round(n));
    valuation = 0;
    
    % Special handling for large hierarchical differences
    if n >= 10000 % Performance tier differences
        valuation = 0; % Maximum distance for tier differences
        return;
    end
    
    while mod(n, p) == 0 && n > 0
        n = n / p;
        valuation = valuation + 1;
    end
end

%% HELPER FUNCTIONS
function team_features = aggregate_by_team(features, team_labels, teams)
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

function categorical_features = discretize_features_for_padic(continuous_features)
    % Convert continuous features to categorical for p-adic
    n_features = size(continuous_features, 2);
    categorical_features = zeros(size(continuous_features));
    
    for f = 1:n_features
        feature_data = continuous_features(:, f);
        categorical_features(:, f) = discretize(feature_data, 4) * (f + 1); % Weighted by position
    end
end

function description = decode_strategic_value(value, dimension)
    % Decode categorical values back to strategic descriptions
    
    switch dimension
        case 1 % Performance Tier
            if value > 35000, description = 'Elite (Tier 4)';
            elseif value > 25000, description = 'Strong (Tier 3)';
            elseif value > 15000, description = 'Competitive (Tier 2)';
            else, description = 'Developing (Tier 1)'; end
            
        case 2 % Attacking Style
            if value > 350, description = 'Forward-Dominant';
            elseif value > 250, description = 'Balanced Forward';
            elseif value > 150, description = 'Balanced Back';
            else, description = 'Back-Dominant'; end
            
        case 3 % Breakdown Mastery
            if value > 175, description = 'Breakdown Dominant';
            elseif value > 125, description = 'Breakdown Strong';
            elseif value > 75, description = 'Breakdown Competitive';
            else, description = 'Breakdown Struggling'; end
            
        case 4 % Territory Control
            if value > 87, description = 'High Kicking Game';
            elseif value > 62, description = 'Moderate Kicking';
            elseif value > 37, description = 'Low Kicking';
            else, description = 'Minimal Kicking'; end
            
        case 5 % Penetration
            if value > 42, description = 'Elite Penetration';
            elseif value > 30, description = 'Good Penetration';
            elseif value > 18, description = 'Average Penetration';
            else, description = 'Poor Penetration'; end
            
        case 6 % Discipline
            if value > 21, description = 'Very Disciplined';
            elseif value > 15, description = 'Disciplined';
            elseif value > 9, description = 'Average Discipline';
            else, description = 'Undisciplined'; end
            
        case 7 % Set Piece
            if value > 10.5, description = 'Strong Platform';
            elseif value > 7.5, description = 'Good Platform';
            elseif value > 4.5, description = 'Average Platform';
            else, description = 'Weak Platform'; end
            
        otherwise
            description = 'Unknown';
    end
end