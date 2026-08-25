function prepared = prepare_real_data_features(dataset, bridge)
%PREPARE_REAL_DATA_FEATURES  Convert loaded CSV dataset to clustering features.
%
%   prepared = prepare_real_data_features(dataset, build_football_bridge())

    teams = dataset.teams;
    seasons = dataset.seasons;
    n_teams = dataset.n_teams;
    n_seasons = dataset.n_seasons;
    tbl = dataset.table;

    strategic_choices = zeros(n_teams, 4, n_seasons);
    performance = struct();

    performance.points = zeros(n_teams, 1);
    performance.goals_for = zeros(n_teams, 1);
    performance.goals_against = zeros(n_teams, 1);
    performance.goal_difference = zeros(n_teams, 1);
    performance.win_percentage = zeros(n_teams, 1);
    performance.inferred_tier = zeros(n_teams, 1);

    for t = 1:n_teams
        team_name = string(teams(t));
        team_rows = tbl(string(tbl.team) == team_name, :);

        for s = 1:n_seasons
            season_val = seasons(s);
            row_mask = team_rows.season == season_val;
            if ~any(row_mask)
                continue;
            end
            row = team_rows(row_mask, :);
            row = row(1, :);

            strategic_choices(t, 1, s) = bridge.strategy_extraction.philosophy(row);
            strategic_choices(t, 2, s) = bridge.strategy_extraction.formation(row);
            resources = bridge.strategy_extraction.resources(row);
            strategic_choices(t, 3, s) = mod(round(mean(resources)), 5);
            strategic_choices(t, 4, s) = min(6, max(0, round(std(resources) * 3)));
        end

        adaptability = bridge.strategy_extraction.adaptability(team_rows);
        if isnan(adaptability)
            adaptability = 0;
        end
        for s = 1:n_seasons
            strategic_choices(t, 4, s) = min(6, strategic_choices(t, 4, s) + round(adaptability));
        end

        performance.points(t) = mean(team_rows.points);
        if ismember('goals_for', team_rows.Properties.VariableNames)
            performance.goals_for(t) = mean(team_rows.goals_for);
            performance.goals_against(t) = mean(team_rows.goals_against);
        elseif ismember('tries_for', team_rows.Properties.VariableNames)
            performance.goals_for(t) = mean(team_rows.tries_for);
            performance.goals_against(t) = mean(team_rows.tries_against);
        end
        performance.goal_difference(t) = performance.goals_for(t) - performance.goals_against(t);

        if all(ismember({'wins', 'draws', 'losses'}, team_rows.Properties.VariableNames))
            total_matches = sum(team_rows.wins + team_rows.draws + team_rows.losses);
            performance.win_percentage(t) = sum(team_rows.wins) / max(total_matches, 1);
        else
            performance.win_percentage(t) = performance.points(t) / max(38 * 3, 1);
        end

        performance.inferred_tier(t) = bridge.infer_tier(performance.points(t));
    end

    performance.avg_win_pct = performance.win_percentage;
    performance.avg_goal_diff = performance.goal_difference;

    feature_matrix = [];
    for s = 1:n_seasons
        season_features = squeeze(strategic_choices(:, :, s));
        feature_matrix = [feature_matrix, season_features]; %#ok<AGROW>
    end
    feature_matrix = [feature_matrix, ...
        performance.avg_win_pct, ...
        performance.avg_goal_diff / 100];

    prepared = struct();
    prepared.sport = dataset.sport;
    prepared.teams = teams;
    prepared.seasons = seasons;
    prepared.n_teams = n_teams;
    prepared.n_seasons = n_seasons;
    prepared.strategic_choices = strategic_choices;
    prepared.performance = performance;
    prepared.feature_matrix = feature_matrix;
    prepared.source_file = dataset.source_file;
end
