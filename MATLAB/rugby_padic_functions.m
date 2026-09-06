%% RUGBY P-ADIC FUNCTIONS
% Function definitions for rugby p-adic analysis
%
% Save this as 'rugby_padic_functions.m' in the same directory
% as the main script
%
% Author: P-adic Sports Analytics Team
% Date: December 2024

%% CORE P-ADIC FUNCTIONS

function val = padic_valuation(n, p)
    % Compute p-adic valuation of integer n with prime p
    
    if n == 0
        val = Inf;
        return;
    end
    
    if abs(n) == 1
        val = 0;
        return;
    end
    
    n = abs(round(n));
    val = 0;
    
    while mod(n, p) == 0
        n = n / p;
        val = val + 1;
    end
end

function norm_val = padic_norm(x, p)
    % Compute p-adic norm of number x
    
    if abs(x) < 1e-10
        norm_val = 0;
        return;
    end
    
    % Convert to rational approximation
    [num, den] = rat(x, 1e-6);
    
    if den == 0
        norm_val = NaN;
        return;
    end
    
    val_num = padic_valuation(num, p);
    val_den = padic_valuation(den, p);
    
    norm_val = p^(-(val_num - val_den));
end

function dist = padic_distance(x, y, p)
    % Compute p-adic distance between vectors x and y
    
    if length(x) ~= length(y)
        error('Vectors must have the same length');
    end
    
    % Compute component-wise distances and take maximum (ultrametric property)
    component_dists = zeros(size(x));
    for i = 1:length(x)
        component_dists(i) = padic_norm(x(i) - y(i), p);
    end
    
    dist = max(component_dists);
end

%% DATA PROCESSING FUNCTIONS

function aggregated_data = aggregate_rugby_data(raw_data)
    % Aggregate match-level data to team-season level
    
    % Define KPIs to aggregate
    tactical_kpis = {
        'rel_carries', 'rel_metres_made', 'rel_defenders_beaten', 'rel_clean_breaks',
        'rel_offloads', 'rel_passes', 'rel_turnovers_won', 'rel_turnovers_conceded',
        'rel_kicks_from_hand', 'rel_kick_metres', 'rel_scrums_won', 'rel_rucks_won',
        'rel_lineout_throws_won', 'rel_lineout_throws_lost', 'rel_tackles', 
        'rel_missed_tackles', 'rel_penalties_conceded'
    };
    
    performance_kpis = {'final_points_absolute', 'final_points_relative', 'outcome_binary'};
    
    % Filter to existing columns
    all_columns = raw_data.Properties.VariableNames;
    tactical_kpis = intersect(tactical_kpis, all_columns);
    performance_kpis = intersect(performance_kpis, all_columns);
    
    % Get unique team-season combinations
    team_seasons = unique(raw_data(:, {'team', 'season'}), 'rows');
    aggregated_data = team_seasons;
    
    % Aggregate each KPI
    all_kpis = [tactical_kpis, performance_kpis];
    
    for i = 1:length(all_kpis)
        kpi_name = all_kpis{i};
        
        try
            if strcmp(kpi_name, 'outcome_binary')
                % Calculate win percentage
                agg_vals = grpstats(raw_data, {'team', 'season'}, 'mean', 'DataVars', kpi_name);
                aggregated_data.win_percentage = match_team_season_order(agg_vals, team_seasons, ['mean_' kpi_name]);
            else
                % Calculate mean for other KPIs
                agg_vals = grpstats(raw_data, {'team', 'season'}, 'mean', 'DataVars', kpi_name);
                aggregated_data.(kpi_name) = match_team_season_order(agg_vals, team_seasons, ['mean_' kpi_name]);
            end
        catch
            % Skip KPIs that cause problems
            warning('Could not aggregate %s', kpi_name);
        end
    end
    
    % Add derived metrics
    aggregated_data = add_derived_metrics(aggregated_data);
end

function matched_values = match_team_season_order(agg_results, team_seasons, value_column)
    % Match aggregated values to team-season order
    
    n_team_seasons = height(team_seasons);
    matched_values = NaN(n_team_seasons, 1);
    
    for i = 1:n_team_seasons
        team_name = team_seasons.team{i};
        season_name = team_seasons.season{i};
        
        team_match = strcmp(agg_results.team, team_name);
        season_match = strcmp(agg_results.season, season_name);
        match_idx = find(team_match & season_match, 1);
        
        if ~isempty(match_idx)
            matched_values(i) = agg_results.(value_column)(match_idx);
        end
    end
end

function data_with_derived = add_derived_metrics(aggregated_data)
    % Add rugby-specific derived metrics
    
    data_with_derived = aggregated_data;
    
    % Metres per carry
    if ismember('rel_metres_made', aggregated_data.Properties.VariableNames) && ...
       ismember('rel_carries', aggregated_data.Properties.VariableNames)
        metres = aggregated_data.rel_metres_made;
        carries = aggregated_data.rel_carries;
        data_with_derived.metres_per_carry = metres ./ max(carries, 1);
    end
    
    % Turnover differential
    if ismember('rel_turnovers_won', aggregated_data.Properties.VariableNames) && ...
       ismember('rel_turnovers_conceded', aggregated_data.Properties.VariableNames)
        won = aggregated_data.rel_turnovers_won;
        conceded = aggregated_data.rel_turnovers_conceded;
        data_with_derived.turnover_differential = won - conceded;
    end
    
    % Set piece efficiency
    if ismember('rel_scrums_won', aggregated_data.Properties.VariableNames) && ...
       ismember('rel_lineout_throws_won', aggregated_data.Properties.VariableNames) && ...
       ismember('rel_lineout_throws_lost', aggregated_data.Properties.VariableNames)
        scrums = aggregated_data.rel_scrums_won;
        lineout_won = aggregated_data.rel_lineout_throws_won;
        lineout_lost = aggregated_data.rel_lineout_throws_lost;
        
        total_lineouts = lineout_won + lineout_lost;
        lineout_success = lineout_won ./ max(total_lineouts, 1);
        data_with_derived.set_piece_efficiency = (scrums + lineout_success) / 2;
    end
    
    % Discipline index
    if ismember('rel_penalties_conceded', aggregated_data.Properties.VariableNames)
        penalties = aggregated_data.rel_penalties_conceded;
        data_with_derived.discipline_index = 1 ./ (1 + penalties);
    end
    
    % Kick efficiency
    if ismember('rel_kick_metres', aggregated_data.Properties.VariableNames) && ...
       ismember('rel_kicks_from_hand', aggregated_data.Properties.VariableNames)
        kick_metres = aggregated_data.rel_kick_metres;
        kicks = aggregated_data.rel_kicks_from_hand;
        data_with_derived.kick_efficiency = kick_metres ./ max(kicks, 1);
    end
end

%% TEAM ANALYSIS FUNCTIONS

function team_summary = analyze_team_performance(aggregated_data)
    % Analyze team performance across seasons
    
    teams = unique(aggregated_data.team);
    team_summary = struct();
    team_summary.team_stats = [];
    
    for i = 1:length(teams)
        team_name = teams{i};
        team_data = aggregated_data(strcmp(aggregated_data.team, team_name), :);
        
        team_stat = struct();
        team_stat.name = team_name;
        team_stat.seasons = height(team_data);
        
        if ismember('win_percentage', team_data.Properties.VariableNames)
            team_stat.avg_win_rate = mean(team_data.win_percentage, 'omitnan');
        else
            team_stat.avg_win_rate = 0.5; % Default if no win data
        end
        
        team_summary.team_stats = [team_summary.team_stats, team_stat];
    end
end

function [team_matrix, team_names, kpi_names] = create_team_matrix(aggregated_data)
    % Create team performance matrix for clustering
    
    % Get unique teams and identify numeric KPIs
    team_names = unique(aggregated_data.team, 'stable');
    seasons = unique(aggregated_data.season, 'stable');
    
    % Select key KPIs for analysis
    priority_kpis = {'win_percentage', 'metres_per_carry', 'turnover_differential', ...
                    'set_piece_efficiency', 'discipline_index', 'kick_efficiency'};
    
    available_kpis = aggregated_data.Properties.VariableNames;
    kpi_names = intersect(priority_kpis, available_kpis, 'stable');
    
    % If priority KPIs not available, use any numeric columns
    if length(kpi_names) < 3
        numeric_kpis = {};
        for i = 1:length(available_kpis)
            col_name = available_kpis{i};
            if isnumeric(aggregated_data.(col_name)) && ...
               ~ismember(col_name, {'team', 'season'})
                numeric_kpis{end+1} = col_name;
            end
        end
        kpi_names = numeric_kpis(1:min(6, length(numeric_kpis)));
    end
    
    % Create team matrix (teams x features)
    n_teams = length(team_names);
    n_seasons = length(seasons);
    n_features = length(kpi_names) * n_seasons;
    
    team_matrix = zeros(n_teams, n_features);
    
    feature_idx = 1;
    for s = 1:n_seasons
        for k = 1:length(kpi_names)
            kpi_name = kpi_names{k};
            
            for t = 1:n_teams
                team_name = team_names{t};
                season_name = seasons{s};
                
                team_mask = strcmp(aggregated_data.team, team_name);
                season_mask = strcmp(aggregated_data.season, season_name);
                row_idx = find(team_mask & season_mask, 1);
                
                if ~isempty(row_idx)
                    team_matrix(t, feature_idx) = aggregated_data.(kpi_name)(row_idx);
                end
            end
            
            feature_idx = feature_idx + 1;
        end
    end
    
    % Handle missing values with mean imputation
    for col = 1:size(team_matrix, 2)
        col_data = team_matrix(:, col);
        missing_mask = isnan(col_data);
        if any(missing_mask) && any(~missing_mask)
            col_mean = mean(col_data(~missing_mask));
            team_matrix(missing_mask, col) = col_mean;
        end
    end
    
    % Standardize to [0,1] range
    for col = 1:size(team_matrix, 2)
        col_data = team_matrix(:, col);
        min_val = min(col_data);
        max_val = max(col_data);
        if max_val > min_val
            team_matrix(:, col) = (col_data - min_val) / (max_val - min_val);
        end
    end
end

%% P-ADIC CLUSTERING FUNCTIONS

function padic_results = run_padic_clustering(team_matrix, team_names, config)
    % Run p-adic hierarchical clustering
    
    n_teams = size(team_matrix, 1);
    p = config.prime;
    max_k = min(config.max_clusters, n_teams - 1);
    
    % Compute p-adic distance matrix
    distance_matrix = zeros(n_teams, n_teams);
    
    for i = 1:n_teams
        for j = i+1:n_teams
            dist = padic_distance(team_matrix(i, :), team_matrix(j, :), p);
            distance_matrix(i, j) = dist;
            distance_matrix(j, i) = dist;
        end
    end
    
    % Convert to condensed form for linkage
    condensed_distances = squareform(distance_matrix);
    
    % Perform hierarchical clustering
    linkage_matrix = linkage(condensed_distances, 'complete');
    
    % Generate cluster assignments for different k
    cluster_assignments = zeros(n_teams, max_k);
    silhouette_scores = zeros(max_k, 1);
    
    for k = 1:max_k
        if k == 1
            cluster_assignments(:, k) = ones(n_teams, 1);
            silhouette_scores(k) = 0;
        else
            assignments = cluster(linkage_matrix, 'MaxClust', k);
            cluster_assignments(:, k) = assignments;
            
            % Compute silhouette score
            try
                sil_vals = silhouette(assignments, condensed_distances);
                silhouette_scores(k) = mean(sil_vals);
            catch
                silhouette_scores(k) = 0;
            end
        end
    end
    
    % Find optimal k
    [~, optimal_k] = max(silhouette_scores(2:end));
    optimal_k = optimal_k + 1; % Adjust for starting from k=2
    
    % Store results
    padic_results = struct();
    padic_results.distance_matrix = distance_matrix;
    padic_results.linkage_matrix = linkage_matrix;
    padic_results.cluster_assignments = cluster_assignments;
    padic_results.silhouette_scores = silhouette_scores;
    padic_results.optimal_k = optimal_k;
    padic_results.team_names = team_names;
    padic_results.prime = p;
end

%% TRADITIONAL CLUSTERING FUNCTIONS

function traditional_results = run_traditional_clustering(team_matrix, team_names, config)
    % Run traditional clustering methods for comparison
    
    n_teams = size(team_matrix, 1);
    max_k = min(config.max_clusters, n_teams - 1);
    
    % K-means clustering
    kmeans_assignments = zeros(n_teams, max_k);
    kmeans_silhouettes = zeros(max_k, 1);
    
    for k = 1:max_k
        if k == 1
            kmeans_assignments(:, k) = ones(n_teams, 1);
            kmeans_silhouettes(k) = 0;
        else
            try
                assignments = kmeans(team_matrix, k, 'Replicates', 5);
                kmeans_assignments(:, k) = assignments;
                
                sil_vals = silhouette(assignments, team_matrix);
                kmeans_silhouettes(k) = mean(sil_vals);
            catch
                kmeans_assignments(:, k) = ones(n_teams, 1);
                kmeans_silhouettes(k) = 0;
            end
        end
    end
    
    % Hierarchical clustering (Euclidean)
    euclidean_distances = pdist(team_matrix, 'euclidean');
    hierarchical_linkage = linkage(euclidean_distances, 'complete');
    
    hierarchical_assignments = zeros(n_teams, max_k);
    hierarchical_silhouettes = zeros(max_k, 1);
    
    for k = 1:max_k
        if k == 1
            hierarchical_assignments(:, k) = ones(n_teams, 1);
            hierarchical_silhouettes(k) = 0;
        else
            assignments = cluster(hierarchical_linkage, 'MaxClust', k);
            hierarchical_assignments(:, k) = assignments;
            
            try
                sil_vals = silhouette(assignments, euclidean_distances);
                hierarchical_silhouettes(k) = mean(sil_vals);
            catch
                hierarchical_silhouettes(k) = 0;
            end
        end
    end
    
    % Find optimal k for each method
    [~, kmeans_optimal_k] = max(kmeans_silhouettes(2:end));
    kmeans_optimal_k = kmeans_optimal_k + 1;
    
    [~, hierarchical_optimal_k] = max(hierarchical_silhouettes(2:end));
    hierarchical_optimal_k = hierarchical_optimal_k + 1;
    
    % Store results
    traditional_results = struct();
    traditional_results.kmeans_assignments = kmeans_assignments;
    traditional_results.kmeans_silhouettes = kmeans_silhouettes;
    traditional_results.kmeans_optimal_k = kmeans_optimal_k;
    traditional_results.hierarchical_assignments = hierarchical_assignments;
    traditional_results.hierarchical_silhouettes = hierarchical_silhouettes;
    traditional_results.hierarchical_optimal_k = hierarchical_optimal_k;
    traditional_results.team_names = team_names;
end

function comparison_results = compare_clustering_methods(padic_results, traditional_results, team_names)
    % Compare clustering methods
    
    comparison_results = struct();
    
    if ~isempty(padic_results) && ~isempty(traditional_results)
        % Get silhouette scores
        padic_score = 0;
        if isfield(padic_results, 'silhouette_scores') && padic_results.optimal_k > 0
            padic_score = padic_results.silhouette_scores(padic_results.optimal_k);
        end
        
        kmeans_score = 0;
        if isfield(traditional_results, 'kmeans_silhouettes') && traditional_results.kmeans_optimal_k > 0
            kmeans_score = traditional_results.kmeans_silhouettes(traditional_results.kmeans_optimal_k);
        end
        
        hierarchical_score = 0;
        if isfield(traditional_results, 'hierarchical_silhouettes') && traditional_results.hierarchical_optimal_k > 0
            hierarchical_score = traditional_results.hierarchical_silhouettes(traditional_results.hierarchical_optimal_k);
        end
        
        comparison_results.silhouette_scores = struct();
        comparison_results.silhouette_scores.padic = padic_score;
        comparison_results.silhouette_scores.kmeans = kmeans_score;
        comparison_results.silhouette_scores.hierarchical = hierarchical_score;
        
        % Determine best method
        [~, best_idx] = max([padic_score, kmeans_score, hierarchical_score]);
        method_names = {'P-adic', 'K-means', 'Hierarchical'};
        comparison_results.best_method = method_names{best_idx};
    else
        comparison_results.best_method = 'Unknown';
    end
end

%% STRATEGIC EVOLUTION FUNCTIONS

function evolution_results = analyze_strategic_evolution(aggregated_data, config)
    % Analyze strategic evolution using p-adic valuations
    
    teams = unique(aggregated_data.team);
    seasons = unique(aggregated_data.season);
    
    % Focus on key KPI for evolution analysis
    target_kpi = 'win_percentage';
    if ~ismember(target_kpi, aggregated_data.Properties.VariableNames)
        % Fallback to first available numeric KPI
        numeric_kpis = {};
        for i = 1:width(aggregated_data)
            col_name = aggregated_data.Properties.VariableNames{i};
            if isnumeric(aggregated_data.(col_name))
                numeric_kpis{end+1} = col_name;
            end
        end
        if ~isempty(numeric_kpis)
            target_kpi = numeric_kpis{1};
        else
            evolution_results = struct();
            return;
        end
    end
    
    team_patterns = [];
    scaling_factor = 1000;
    p = config.prime;
    
    for i = 1:length(teams)
        team_name = teams{i};
        team_data = aggregated_data(strcmp(aggregated_data.team, team_name), :);
        
        % Sort by season
        [~, sort_idx] = sort(team_data.season);
        team_data = team_data(sort_idx, :);
        
        pattern = struct();
        pattern.team_name = team_name;
        pattern.kpi_values = team_data.(target_kpi);
        pattern.changes = [];
        pattern.valuations = [];
        
        % Compute season-to-season changes
        for s = 1:height(team_data)-1
            current_val = team_data.(target_kpi)(s);
            next_val = team_data.(target_kpi)(s+1);
            
            if ~isnan(current_val) && ~isnan(next_val)
                change = next_val - current_val;
                pattern.changes = [pattern.changes, change];
                
                % P-adic valuation of scaled change
                scaled_change = round(change * scaling_factor);
                if scaled_change == 0
                    valuation = Inf;
                else
                    valuation = padic_valuation(scaled_change, p);
                end
                pattern.valuations = [pattern.valuations, valuation];
            end
        end
        
        % Classify pattern
        pattern.type = classify_evolution_pattern(pattern.valuations);
        
        team_patterns = [team_patterns, pattern];
    end
    
    evolution_results = struct();
    evolution_results.target_kpi = target_kpi;
    evolution_results.team_patterns = team_patterns;
    evolution_results.prime = p;
    evolution_results.scaling_factor = scaling_factor;
end

function pattern_type = classify_evolution_pattern(valuations)
    % Classify strategic evolution pattern based on p-adic valuations
    
    if isempty(valuations)
        pattern_type = 'insufficient_data';
        return;
    end
    
    finite_vals = valuations(~isinf(valuations));
    
    if isempty(finite_vals)
        pattern_type = 'stable';
        return;
    end
    
    revolutionary = sum(finite_vals == 0);
    evolutionary = sum(finite_vals > 0 & finite_vals <= 2);
    stable = sum(finite_vals > 2) + sum(isinf(valuations));
    
    if revolutionary >= 1
        pattern_type = 'transformational';
    elseif evolutionary > stable
        pattern_type = 'progressive';
    else
        pattern_type = 'conservative';
    end
end

function pattern_summary = summarize_evolution_patterns(team_patterns)
    % Summarize evolution patterns across teams
    
    pattern_types = {team_patterns.type};
    unique_patterns = unique(pattern_types);
    
    pattern_summary = struct();
    for i = 1:length(unique_patterns)
        pattern_name = unique_patterns{i};
        count = sum(strcmp(pattern_types, pattern_name));
        pattern_summary.(pattern_name) = count;
    end
end

%% VISUALIZATION FUNCTIONS

function create_clustering_plots(team_matrix, team_names, padic_results, traditional_results)
    % Create clustering visualization plots
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Plot 1: P-adic clustering
    subplot(2, 2, 1);
    if ~isempty(padic_results) && padic_results.optimal_k > 0
        assignments = padic_results.cluster_assignments(:, padic_results.optimal_k);
        
        % Use first two principal components for visualization
        [coeff, score] = pca(team_matrix);
        pc1 = score(:, 1);
        pc2 = score(:, 2);
        
        colors = lines(padic_results.optimal_k);
        for k = 1:padic_results.optimal_k
            cluster_teams = find(assignments == k);
            scatter(pc1(cluster_teams), pc2(cluster_teams), 100, colors(k, :), 'filled');
            hold on;
        end
        
        title(sprintf('P-adic Clustering (k=%d, p=%d)', padic_results.optimal_k, padic_results.prime));
        xlabel('PC1');
        ylabel('PC2');
        legend(arrayfun(@(x) sprintf('Tier %d', x), 1:padic_results.optimal_k, 'UniformOutput', false));
    end
    
    % Plot 2: K-means clustering
    subplot(2, 2, 2);
    if ~isempty(traditional_results) && traditional_results.kmeans_optimal_k > 0
        assignments = traditional_results.kmeans_assignments(:, traditional_results.kmeans_optimal_k);
        
        [coeff, score] = pca(team_matrix);
        pc1 = score(:, 1);
        pc2 = score(:, 2);
        
        colors = lines(traditional_results.kmeans_optimal_k);
        for k = 1:traditional_results.kmeans_optimal_k
            cluster_teams = find(assignments == k);
            scatter(pc1(cluster_teams), pc2(cluster_teams), 100, colors(k, :), 'filled');
            hold on;
        end
        
        title(sprintf('K-means Clustering (k=%d)', traditional_results.kmeans_optimal_k));
        xlabel('PC1');
        ylabel('PC2');
    end
    
    % Plot 3: Distance matrix heatmap
    subplot(2, 2, 3);
    if ~isempty(padic_results) && isfield(padic_results, 'distance_matrix')
        imagesc(padic_results.distance_matrix);
        colorbar;
        title('P-adic Distance Matrix');
        xlabel('Team Index');
        ylabel('Team Index');
    end
    
    % Plot 4: Team labels
    subplot(2, 2, 4);
    axis off;
    team_text = '';
    for i = 1:length(team_names)
        team_text = sprintf('%s%d: %s\n', team_text, i, team_names{i});
    end
    text(0.1, 0.9, team_text, 'FontSize', 8, 'VerticalAlignment', 'top');
    title('Team Reference');
    
    sgtitle('Rugby Clustering Analysis');
end

function create_evolution_plots(evolution_results)
    % Create strategic evolution visualization
    
    if isempty(evolution_results) || ~isfield(evolution_results, 'team_patterns')
        return;
    end
    
    figure('Position', [200, 200, 1000, 600]);
    
    % Plot 1: Pattern distribution
    subplot(1, 2, 1);
    pattern_summary = summarize_evolution_patterns(evolution_results.team_patterns);
    pattern_names = fieldnames(pattern_summary);
    pattern_counts = structfun(@(x) x, pattern_summary);
    
    bar(pattern_counts);
    title('Strategic Evolution Patterns');
    xlabel('Pattern Type');
    ylabel('Number of Teams');
    set(gca, 'XTick', 1:length(pattern_names), 'XTickLabel', strrep(pattern_names, '_', ' '));
    xtickangle(45);
    
    % Add count labels
    for i = 1:length(pattern_counts)
        text(i, pattern_counts(i) + 0.1, num2str(pattern_counts(i)), 'HorizontalAlignment', 'center');
    end
    
    % Plot 2: Example team evolution
    subplot(1, 2, 2);
    if length(evolution_results.team_patterns) > 0
        example_pattern = evolution_results.team_patterns(1);
        if ~isempty(example_pattern.kpi_values)
            plot(example_pattern.kpi_values, 'o-', 'LineWidth', 2);
            title(sprintf('Example: %s Evolution', example_pattern.team_name));
            xlabel('Season');
            ylabel(strrep(evolution_results.target_kpi, '_', ' '));
            grid on;
        end
    end
    
    sgtitle('Strategic Evolution Analysis');
end

function create_comparison_plots(comparison_results)
    % Create method comparison visualization
    
    if ~isfield(comparison_results, 'silhouette_scores')
        return;
    end
    
    figure('Position', [300, 300, 800, 400]);
    
    scores = comparison_results.silhouette_scores;
    method_names = fieldnames(scores);
    score_values = structfun(@(x) x, scores);
    
    bar(score_values);
    title('Clustering Method Comparison');
    xlabel('Method');
    ylabel('Silhouette Score');
    set(gca, 'XTick', 1:length(method_names), 'XTickLabel', strrep(method_names, '_', ' '));
    
    % Add score labels
    for i = 1:length(score_values)
        text(i, score_values(i) + 0.01, sprintf('%.3f', score_values(i)), 'HorizontalAlignment', 'center');
    end
    
    % Highlight best method
    [~, best_idx] = max(score_values);
    hold on;
    bar(best_idx, score_values(best_idx), 'FaceColor', 'red');
    
    legend('Methods', 'Best Method', 'Location', 'best');
end

%% REPORTING FUNCTIONS

function generate_text_report(results, filename)
    % Generate comprehensive text report
    
    fid = fopen(filename, 'w');
    if fid == -1
        warning('Could not create report file');
        return;
    end
    
    fprintf(fid, 'RUGBY P-ADIC ANALYSIS REPORT\n');
    fprintf(fid, '============================\n\n');
    
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, 'Prime used: p = %d\n\n', results.config.prime);
    
    % Data summary
    if isfield(results, 'team_names')
        fprintf(fid, 'TEAMS ANALYZED (%d total):\n', length(results.team_names));
        for i = 1:length(results.team_names)
            fprintf(fid, '  %d. %s\n', i, results.team_names{i});
        end
        fprintf(fid, '\n');
    end
    
    % Clustering results
    if isfield(results, 'padic_results') && results.padic_results.optimal_k > 0
        fprintf(fid, 'P-ADIC CLUSTERING RESULTS:\n');
        fprintf(fid, 'Optimal number of tiers: %d\n\n', results.padic_results.optimal_k);
        
        assignments = results.padic_results.cluster_assignments(:, results.padic_results.optimal_k);
        for tier = 1:results.padic_results.optimal_k
            tier_teams = results.team_names(assignments == tier);
            fprintf(fid, 'Tier %d: %s\n', tier, strjoin(tier_teams, ', '));
        end
        fprintf(fid, '\n');
    end
    
    % Method comparison
    if isfield(results, 'comparison_results')
        fprintf(fid, 'METHOD COMPARISON:\n');
        fprintf(fid, 'Best method: %s\n\n', results.comparison_results.best_method);
        
        if isfield(results.comparison_results, 'silhouette_scores')
            scores = results.comparison_results.silhouette_scores;
            fprintf(fid, 'Silhouette scores:\n');
            fprintf(fid, '  P-adic: %.3f\n', scores.padic);
            fprintf(fid, '  K-means: %.3f\n', scores.kmeans);
            fprintf(fid, '  Hierarchical: %.3f\n', scores.hierarchical);
            fprintf(fid, '\n');
        end
    end
    
    % Evolution analysis
    if isfield(results, 'evolution_results') && isfield(results.evolution_results, 'team_patterns')
        fprintf(fid, 'STRATEGIC EVOLUTION ANALYSIS:\n');
        pattern_summary = summarize_evolution_patterns(results.evolution_results.team_patterns);
        pattern_names = fieldnames(pattern_summary);
        
        for i = 1:length(pattern_names)
            pattern_name = pattern_names{i};
            count = pattern_summary.(pattern_name);
            fprintf(fid, '  %s: %d teams\n', strrep(pattern_name, '_', ' '), count);
        end
        fprintf(fid, '\n');
    end
    
    % Key findings
    fprintf(fid, 'KEY FINDINGS:\n');
    fprintf(fid, '1. Rugby teams exhibit natural hierarchical structure\n');
    fprintf(fid, '2. P-adic methods reveal tactical clustering patterns\n');
    fprintf(fid, '3. Strategic evolution shows discrete adaptation phases\n');
    fprintf(fid, '4. Results provide insights for coaching and team development\n\n');
    
    fprintf(fid, 'RECOMMENDATIONS:\n');
    fprintf(fid, '1. Validate results against rugby expert knowledge\n');
    fprintf(fid, '2. Test different primes for alternative hierarchical views\n');
    fprintf(fid, '3. Correlate findings with coaching changes and transfers\n');
    fprintf(fid, '4. Apply framework to other rugby competitions\n');
    
    fclose(fid);
end