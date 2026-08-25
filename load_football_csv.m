function dataset = load_football_csv(csv_path)
%LOAD_FOOTBALL_CSV  Load and validate football season data from CSV.
%
%   dataset = load_football_csv('data/examples/football_sample.csv')
%
%   Returns a struct with fields:
%     .sport       - 'football'
%     .table       - cleaned table sorted by team, season
%     .teams       - unique team names
%     .seasons     - unique seasons
%     .n_teams     - number of teams
%     .n_seasons   - number of seasons
%     .source_file - path loaded from

    required = {'team', 'season', 'points', 'goals_for', 'goals_against', 'possession_pct'};
    optional = {'wins', 'draws', 'losses', 'formation_changes'};

    dataset = load_sports_csv(csv_path, 'football', required, optional);
end

function dataset = load_sports_csv(csv_path, sport, required, optional)
    if ~isfile(csv_path)
        error('load_football_csv:FileNotFound', 'CSV file not found: %s', csv_path);
    end

    raw = readtable(csv_path, 'VariableNamingRule', 'preserve');
    raw.Properties.VariableNames = lower(strrep(raw.Properties.VariableNames, ' ', '_'));

    missing = setdiff(required, raw.Properties.VariableNames);
    if ~isempty(missing)
        error('load_football_csv:MissingColumns', ...
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
        warning('load_football_csv:DroppedRows', 'Dropped %d rows with missing required values.', dropped);
    end
    raw = raw(keep, :);

    for i = 1:numel(optional)
        col = optional{i};
        if ~ismember(col, raw.Properties.VariableNames)
            switch col
                case 'wins'
                    raw.wins = round(raw.points / 3);
                case 'draws'
                    raw.draws = mod(raw.points, 3);
                case 'losses'
                    raw.losses = max(0, 38 - raw.wins - raw.draws);
                case 'formation_changes'
                    raw.formation_changes = ones(height(raw), 1) * 5;
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

    if ~iscell(raw.team) && ~isstring(raw.team)
        raw.team = string(raw.team);
    else
        raw.team = string(raw.team);
    end

    raw = sortrows(raw, {'team', 'season'});

    dataset = struct();
    dataset.sport = sport;
    dataset.table = raw;
    dataset.teams = unique(raw.team, 'stable');
    dataset.seasons = unique(raw.season);
    dataset.n_teams = numel(dataset.teams);
    dataset.n_seasons = numel(dataset.seasons);
    dataset.source_file = csv_path;

    fprintf('Loaded %s data: %d teams, %d seasons, %d rows from %s\n', ...
        sport, dataset.n_teams, dataset.n_seasons, height(raw), csv_path);
end
