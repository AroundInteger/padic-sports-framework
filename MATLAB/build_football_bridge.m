function bridge = build_football_bridge()
%BUILD_FOOTBALL_BRIDGE  Strategy extraction rules for football CSV data.

    bridge = struct();
    bridge.sport = 'football';

    bridge.tier_mapping = struct();
    bridge.tier_mapping.rules = {
        'Points > 75 -> Elite (Champions League)'
        'Points 60-75 -> Strong (Europa League)'
        'Points 45-60 -> Average (Mid-table)'
        'Points < 45 -> Developing (Relegation battle)'
        };

    bridge.strategy_extraction = struct();
    bridge.strategy_extraction.philosophy = @(row) double(row.goals_for / max(row.goals_against, 1) > 1.2);
    bridge.strategy_extraction.formation = @(row) discretize(row.possession_pct, [0, 45, 55, 100]) - 1;
    bridge.strategy_extraction.resources = @(row) [
        row.goals_against / 20
        row.goals_for / 20
        row.points / 25
        row.wins / 10
        row.possession_pct / 20
        ];
    bridge.strategy_extraction.adaptability = @(rows) std(rows.formation_changes, 'omitnan');

    bridge.infer_tier = @(points) discretize(points, [-Inf, 45, 60, 75, Inf]);
end
