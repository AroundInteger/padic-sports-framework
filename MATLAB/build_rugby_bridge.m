function bridge = build_rugby_bridge()
%BUILD_RUGBY_BRIDGE  Strategy extraction rules for rugby CSV data.
%
%   Maps rugby metrics to the four p-adic strategic dimensions:
%     philosophy (p=2), formation/style (p=3), resources (p=5), adaptability (p=7)

    bridge = struct();
    bridge.sport = 'rugby';

    bridge.tier_mapping = struct();
    bridge.tier_mapping.rules = {
        'Points > 60 -> Elite (Title contenders)'
        'Points 48-60 -> Strong (Play-off hunt)'
        'Points 35-48 -> Average (Mid-table)'
        'Points < 35 -> Developing (Relegation zone)'
        };

    bridge.strategy_extraction = struct();
    bridge.strategy_extraction.philosophy = @(row) double(row.tries_for / max(row.tries_against, 1) > 1.15);
    bridge.strategy_extraction.formation = @(row) discretize(row.possession_pct, [0, 46, 52, 100]) - 1;
    bridge.strategy_extraction.resources = @(row) [
        row.lineout_success_pct / 20
        row.scrums_won_pct / 20
        row.tries_for / 15
        row.points / 20
        min(row.tries_against, 60) / 15
        ];
    bridge.strategy_extraction.adaptability = @(rows) std(rows.possession_pct, 'omitnan');

    bridge.infer_tier = @(points) discretize(points, [-Inf, 35, 48, 60, Inf]);
end
