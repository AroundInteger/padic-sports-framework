function results = run_real_data_analysis(sport, csv_path)
%RUN_REAL_DATA_ANALYSIS  Load CSV data and run p-adic clustering.
%
%   results = run_real_data_analysis('football', 'data/examples/football_sample.csv')
%   results = run_real_data_analysis('rugby', 'data/raw/my_premiership.csv')
%
%   Optional name-value pairs:
%     'SavePlot'  - save cluster summary plot (default true)
%     'KRange'    - cluster counts to try (default 2:6)
%     'Primes'    - primes to search (default [2 3 5 7])

    arguments
        sport {mustBeMember(sport, {'football', 'rugby'})}
        csv_path (1, :) char
    end

    sep = repmat('=', 1, 60);
    fprintf('\n%s\n', sep);
    fprintf('REAL DATA ANALYSIS — %s\n', upper(sport));
    fprintf('%s\n\n', sep);

    switch sport
        case 'football'
            dataset = load_football_csv(csv_path);
            bridge = build_football_bridge();
        case 'rugby'
            dataset = load_rugby_csv(csv_path);
            bridge = build_rugby_bridge();
    end

    prepared = prepare_real_data_features(dataset, bridge);
    clustering = cluster_feature_matrix(prepared.feature_matrix);

    tier_labels = prepared.performance.inferred_tier;
    tier_accuracy = evaluate_tier_alignment(clustering.labels, tier_labels);

    real_threshold = 0.5;
    passed = clustering.silhouette_score >= real_threshold;

    fprintf('\nCLUSTERING RESULTS\n');
    fprintf('  Source file:       %s\n', csv_path);
    fprintf('  Teams:             %d\n', prepared.n_teams);
    fprintf('  Seasons:           %d\n', prepared.n_seasons);
    fprintf('  Best prime:        p = %d\n', clustering.prime);
    fprintf('  Clusters (k):      %d\n', clustering.k);
    fprintf('  Silhouette score:  %.4f\n', clustering.silhouette_score);
    fprintf('  Tier alignment:    %.1f%% (inferred from points)\n', tier_accuracy * 100);
    fprintf('  Real-data target:  > %.2f — %s\n', real_threshold, pass_label(passed));

    display_cluster_composition(clustering.labels, prepared.teams);

    results = struct();
    results.sport = sport;
    results.dataset = dataset;
    results.prepared = prepared;
    results.clustering = clustering;
    results.tier_accuracy = tier_accuracy;
    results.passed_real_threshold = passed;
    results.real_threshold = real_threshold;

    if ~exist('figures', 'dir')
        mkdir('figures');
    end
    plot_path = fullfile('figures', sprintf('%s_real_data_clusters.png', sport));
    save_cluster_plot(prepared, clustering, sport, plot_path);
    results.plot_path = plot_path;
    fprintf('\nSaved cluster plot to %s\n', plot_path);
end

function label = pass_label(passed)
    if passed
        label = 'PASS';
    else
        label = 'below target (still informative)';
    end
end

function accuracy = evaluate_tier_alignment(cluster_labels, tier_labels)
    unique_clusters = unique(cluster_labels);
    unique_tiers = unique(tier_labels);
    n = numel(cluster_labels);
    best_accuracy = 0;

    if numel(unique_clusters) == numel(unique_tiers)
        cluster_perms = perms(unique_clusters);
        for idx = 1:size(cluster_perms, 1)
            mapping = cluster_perms(idx, :);
            mapped = cluster_labels;
            for i = 1:numel(unique_clusters)
                mapped(cluster_labels == unique_clusters(i)) = unique_tiers(mapping(i));
            end
            accuracy = sum(mapped == tier_labels) / n;
            best_accuracy = max(best_accuracy, accuracy);
        end
    else
        best_accuracy = sum(cluster_labels == tier_labels) / n;
    end
    accuracy = best_accuracy;
end

function display_cluster_composition(labels, teams)
    fprintf('\n  Cluster composition:\n');
    for c = unique(labels)'
        idx = find(labels == c);
        team_list = strjoin(cellstr(teams(idx)), ', ');
        if strlength(team_list) > 80
            team_list = extractBefore(team_list, 77) + "...";
        end
        fprintf('    Cluster %d (%d teams): %s\n', c, numel(idx), team_list);
    end
end

function save_cluster_plot(prepared, clustering, sport, plot_path)
    fig = figure('Name', sprintf('%s real data clusters', sport), ...
        'Position', [100, 100, 900, 420], 'Visible', 'off');

    subplot(1, 2, 1);
    scatter(prepared.performance.points, prepared.performance.goal_difference, ...
        80, clustering.labels, 'filled');
    xlabel('Average points');
    ylabel('Goal / try difference');
    title('Teams coloured by p-adic cluster');
    colorbar;
    grid on;

    subplot(1, 2, 2);
    imagesc(clustering.distance_matrix);
    axis square;
    title(sprintf('P-adic distance matrix (p=%d)', clustering.prime));
    colorbar;

    sgtitle(sprintf('%s — silhouette %.3f', upper(sport), clustering.silhouette_score));
    saveas(fig, plot_path);
    close(fig);
end
