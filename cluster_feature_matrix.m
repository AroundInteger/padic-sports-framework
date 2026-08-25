function results = cluster_feature_matrix(feature_matrix, varargin)
%CLUSTER_FEATURE_MATRIX  P-adic hierarchical clustering with prime search.
%
%   results = cluster_feature_matrix(feature_matrix)
%   results = cluster_feature_matrix(feature_matrix, 'Primes', [2 3 5 7], 'KRange', 2:6)

    p = inputParser;
    addParameter(p, 'Primes', [2, 3, 5, 7], @isnumeric);
    addParameter(p, 'KRange', 2:6, @isnumeric);
    parse(p, varargin{:});

    primes = p.Results.Primes;
    k_range = p.Results.KRange;

    best_score = -Inf;
    best_results = struct('prime', [], 'k', [], 'labels', [], ...
        'silhouette_scores', [], 'linkage', [], 'distance_matrix', []);

    for prime = primes
        dist_matrix = calculate_padic_distances(feature_matrix, prime);

        if ~any(dist_matrix(:) > 0)
            continue;
        end

        linkage_matrix = linkage(squareform(dist_matrix), 'complete');

        for k = k_range
            try
                cluster_labels = cluster(linkage_matrix, 'MaxClust', k);
                if numel(unique(cluster_labels)) <= 1
                    continue;
                end
                sil_scores = silhouette(cluster_labels, squareform(dist_matrix));
                avg_silhouette = mean(sil_scores);

                if avg_silhouette > best_score
                    best_score = avg_silhouette;
                    best_results.prime = prime;
                    best_results.k = k;
                    best_results.labels = cluster_labels;
                    best_results.silhouette_scores = sil_scores;
                    best_results.linkage = linkage_matrix;
                    best_results.distance_matrix = dist_matrix;
                end
            catch
            end
        end
    end

    results = best_results;
    results.silhouette_score = best_score;
    results.feature_matrix = feature_matrix;
end

function dist_matrix = calculate_padic_distances(features, prime)
    n_teams = size(features, 1);
    dist_matrix = zeros(n_teams, n_teams);

    for i = 1:n_teams
        for j = i+1:n_teams
            diff_vector = features(i, :) - features(j, :);
            component_distances = zeros(size(diff_vector));
            for k = 1:numel(diff_vector)
                if diff_vector(k) ~= 0
                    component_distances(k) = prime^(-padic_valuation(diff_vector(k), prime));
                end
            end
            dist_matrix(i, j) = max(component_distances);
            dist_matrix(j, i) = dist_matrix(i, j);
        end
    end
end

function val = padic_valuation(n, p)
    if abs(n) < 1e-10
        val = Inf;
        return;
    end
    [num, den] = rat(n, 1e-6);
    val_num = 0;
    while mod(abs(num), p) == 0 && num ~= 0
        num = num / p;
        val_num = val_num + 1;
    end
    val_den = 0;
    while mod(abs(den), p) == 0 && den ~= 0
        den = den / p;
        val_den = val_den + 1;
    end
    val = val_num - val_den;
end
