# padic-sports-framework

Mathematical adventures in p-adic systems — a MATLAB framework for hierarchical sports analytics using p-adic distance metrics and ultrametric clustering.

Build the perfect theoretical system first, validate clustering on ideal data, then progressively bridge toward real football/rugby datasets.

## Requirements

- **MATLAB** R2019b or later (R2020a+ recommended)
- **Statistics and Machine Learning Toolbox** (for `linkage`, `cluster`, `silhouette`, `discretize`)

Check toolboxes in MATLAB:

```matlab
>> ver
```

## Quick start

```bash
git clone https://github.com/AroundInteger/padic-sports-framework.git
cd padic-sports-framework
```

### Baseline (synthetic perfect system)

```matlab
cd('/path/to/padic-sports-framework')
run_framework
```

### Real data (football & rugby CSVs)

```matlab
run_with_real_data
```

Or load a specific file:

```matlab
run_real_data_analysis('football', 'data/examples/football_sample.csv')
run_real_data_analysis('rugby',    'data/raw/my_premiership.csv')
```

No Git at work? Download ZIP from GitHub (**Code → Download ZIP**), unzip, and open the folder in MATLAB.

## What runs

### `run_framework` — seven-step synthetic pipeline

1. Create the perfect hierarchical sport ("Hierarchical Dominion")
2. Generate perfect p-adic-aligned data (5 seasons)
3. Run p-adic clustering and verify silhouette > 0.9
4. Progressive degradation test (0–50% noise)
5. Build football bridge transformations
6. Synthetic Premier League clustering test
7. Validation framework and summary

Output: console report + `figures/degradation_curve.png`

### `run_with_real_data` — CSV pipeline

1. Load football and rugby example CSVs from `data/examples/`
2. Extract strategic features via sport-specific bridges
3. Run p-adic clustering with prime search
4. Compare silhouette against the real-data threshold (> 0.5)
5. Save cluster plots to `figures/`

## Project structure

```
padic-sports-framework/
├── run_framework.m                  # Synthetic baseline entry point
├── run_with_real_data.m             # Real CSV entry point
├── run_real_data_analysis.m         # Analyse one CSV file
├── load_football_csv.m              # Football loader
├── load_rugby_csv.m                 # Rugby loader
├── build_football_bridge.m          # Football feature bridge
├── build_rugby_bridge.m             # Rugby feature bridge
├── prepare_real_data_features.m     # CSV → feature matrix
├── cluster_feature_matrix.m         # P-adic clustering engine
├── perfect_padic_sports_framework.m # Full synthetic implementation
├── data/
│   ├── raw/                         # Drop your CSVs here
│   ├── examples/
│   │   ├── football_sample.csv
│   │   └── rugby_sample.csv
│   └── README.md                    # CSV column schemas
└── figures/                         # Created on first run
```

## Adding your own data

1. Copy the relevant example CSV from `data/examples/` into `data/raw/`
2. Replace rows with your league data (keep column headers)
3. Run:

```matlab
run_real_data_analysis('football', 'data/raw/my_league.csv')
```

See `data/README.md` for required and optional columns.

## Validation thresholds

| Dataset type | Target silhouette |
|---|---|
| Perfect synthetic | > 0.90 |
| Semi-synthetic | > 0.60 |
| Real CSV data | > 0.50 |

## Troubleshooting

**"Undefined function 'linkage'"**  
Install Statistics and Machine Learning Toolbox.

**"Missing required columns"**  
Check column names against `data/README.md` (headers are case-insensitive).

**"CSV file not found"**  
Run `cd` to the project root before calling analysis functions.

**"Perfect system must achieve >0.9 silhouette score"**  
Re-run once — degradation steps use random noise. If it persists, check toolbox versions.

## Populate repo (if empty)

If the dedicated repo only has a placeholder README, run once from a machine with push access:

```bash
git clone https://github.com/AroundInteger/padic-sports-framework.git
cd padic-sports-framework
git clone -b cursor/padic-sports-framework-1f1f --depth 1 \
  https://github.com/AroundInteger/intelligent-paper-pipeline.git /tmp/padic-source
cp -r /tmp/padic-source/padic-sports-framework/* .
rm -rf /tmp/padic-source
git add -A && git commit -m "Add full MATLAB framework with data loaders" && git push
```
