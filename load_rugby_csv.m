function dataset = load_rugby_csv(csv_path)
%LOAD_RUGBY_CSV  Load and validate rugby season data from CSV.
%
%   dataset = load_rugby_csv('data/examples/rugby_sample.csv')
%
%   Returns a struct with fields:
%     .sport       - 'rugby'
%     .table       - cleaned table sorted by team, season
%     .teams       - unique team names
%     .seasons     - unique seasons
%     .n_teams     - number of teams
%     .n_seasons   - number of seasons
%     .source_file - path loaded from

    if ~isfile(csv_path)
        error('load_rugby_csv:FileNotFound', 'CSV file not found: %s', csv_path);
    end

    required = {'team', 'season', 'points', 'tries_for', 'tries_against', 'possession_pct'};
    optional = {'wins', 'draws', 'losses', 'lineout_success_pct', 'scrums_won_pct'};

    raw = readtable(csv_path, 'VariableNamingRule', 'preserve');
    raw.Properties.VariableNames = lower(strrep(raw.Properties.VariableNames, ' ', '_'));

    missing = setdiff(required, raw.Properties.VariableNames);
    if ~isempty(missing)
        error('load_rugby_csv:MissingColumns', ...
            'Missing required columns: %s', strjoin(missing, ', '));
    end

    for i = 1:numel(required)
        col = required{i};
        if isnumeric(raw.(col))
            raw.(col)(ismissing(raw.(col))) = NaN;
        end
    end

    keep = true(height(raw), 1);
    for i = 1:numel(required)
        col = required{i};
        if strcmp(col, 'team')
            keep = keep & ~ismissing(raw.(col)) & strlength(string(raw.(col))) > 0;
        else
            keep = keep & ~ismissing(raw.(col));
        end
    end

    dropped = sum(~keep);
    if dropped > 0
        warning('load_rugby_csv:DroppedRows', 'Dropped %d rows with missing required values.', dropped);
    end
    raw = raw(keep, :);

    for i = 1:numel(optional)
        col = optional{i};
        if ~ismember(col, raw.Properties.VariableNames)
            switch col
                case 'wins'
                    raw.wins = max(1, round(raw.points / 4));
                case 'draws'
                    raw.draws = zeros(height(raw), 1);
                case 'losses'
                    raw.losses = max(0, 22 - raw.wins);
                case 'lineout_success_pct'
                    raw.lineout_success_pct = ones(height(raw), 1) * 82;
                case 'scrums_won_pct'
                    raw.scrums_won_pct = ones(height(raw), 1) * 92;
            end
        elseif isnumeric(raw.(col))
            raw.(col)(ismissing(raw.(col))) = NaN;
            fill_val = median(raw.(col), 'omitnan');
            if isnan(fill_val)
                fill_val = 0;
            end
            raw.(col)(ismissing(raw.(col))) = fill_val;
        end
    end

    raw.team = string(raw.team);

    raw = sortrows(raw, {'team', 'season'});

    dataset = struct();
    dataset.sport = 'rugby';
    dataset.table = raw;
    dataset.teams = unique(raw.team, 'stable');
    dataset.seasons = unique(raw.season);
    dataset.n_teams = numel(dataset.teams);
    dataset.n_seasons = numel(dataset.seasons);
    dataset.source_file = csv_path;

    fprintf('Loaded rugby data: %d teams, %d seasons, %d rows from %s\n', ...
        dataset.n_teams, dataset.n_seasons, height(raw), csv_path);
end
