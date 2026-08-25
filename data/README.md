# Sports data directory

Place your CSV files here, or use the worked examples in `examples/`.

## Layout

```
data/
├── raw/                  # Your real datasets (not committed by default)
├── examples/
│   ├── football_sample.csv
│   └── rugby_sample.csv
└── README.md
```

Copy an example into `raw/` as a starting template:

```bash
cp data/examples/football_sample.csv data/raw/my_league.csv
```

## Football CSV schema

Required columns (header names are case-insensitive):

| Column | Type | Description |
|---|---|---|
| `team` | string | Team name (consistent across seasons) |
| `season` | integer | Season year (e.g. 2023) |
| `points` | numeric | League points total |
| `goals_for` | numeric | Goals scored |
| `goals_against` | numeric | Goals conceded |
| `possession_pct` | numeric | Average possession percentage (0–100) |

Optional columns (improve bridge feature extraction):

| Column | Type | Description |
|---|---|---|
| `wins` | numeric | Wins in season |
| `draws` | numeric | Draws in season |
| `losses` | numeric | Losses in season |
| `formation_changes` | numeric | Formation changes per season |

## Rugby CSV schema

Required columns:

| Column | Type | Description |
|---|---|---|
| `team` | string | Team name |
| `season` | integer | Season year |
| `points` | numeric | League points |
| `tries_for` | numeric | Tries scored |
| `tries_against` | numeric | Tries conceded |
| `possession_pct` | numeric | Average possession (0–100) |

Optional columns:

| Column | Type | Description |
|---|---|---|
| `wins`, `draws`, `losses` | numeric | Match results |
| `lineout_success_pct` | numeric | Lineout success rate |
| `scrums_won_pct` | numeric | Scrums won percentage |

## Loading in MATLAB

```matlab
% Football
results = run_real_data_analysis('football', 'data/examples/football_sample.csv');

% Rugby
results = run_real_data_analysis('rugby', 'data/examples/rugby_sample.csv');

% Your own file
results = run_real_data_analysis('football', 'data/raw/my_league.csv');
```

## Success criteria (from validation framework)

| Dataset type | Target silhouette |
|---|---|
| Perfect synthetic | > 0.90 |
| Semi-synthetic | > 0.60 |
| Real CSV data | > 0.50 |

Scores above 0.5 on real data indicate the p-adic approach is capturing meaningful structure.

## Tips for real data

- Include at least **2 seasons** per team for temporal strategic features
- Keep **team names consistent** across rows ( spelling matters )
- Missing optional columns are filled with sensible defaults
- Rows with missing required values are dropped with a warning
