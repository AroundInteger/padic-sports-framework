% RUN_WITH_REAL_DATA  Run p-adic clustering on football and rugby example CSVs.
%
% Double-click this file in MATLAB, or run:
%   >> run_with_real_data
%
% Loads the bundled sample datasets, runs clustering, and saves plots to figures/.
% Replace paths below with your own files in data/raw/ when ready.

fprintf('=== P-adic Sports Framework — Real Data Pipeline ===\n\n');

football_results = run_real_data_analysis('football', 'data/examples/football_sample.csv');
rugby_results = run_real_data_analysis('rugby', 'data/examples/rugby_sample.csv');

fprintf('\n%s\n', repmat('=', 1, 60));
fprintf('SUMMARY\n');
fprintf('%s\n', repmat('=', 1, 60));
fprintf('  Football silhouette: %.4f (%s)\n', ...
    football_results.clustering.silhouette_score, ...
    pass_fail(football_results.passed_real_threshold));
fprintf('  Rugby silhouette:    %.4f (%s)\n', ...
    rugby_results.clustering.silhouette_score, ...
    pass_fail(rugby_results.passed_real_threshold));
fprintf('\nTo analyse your own data:\n');
fprintf('  run_real_data_analysis(''football'', ''data/raw/your_file.csv'')\n');
fprintf('  run_real_data_analysis(''rugby'',    ''data/raw/your_file.csv'')\n');

function s = pass_fail(passed)
    if passed
        s = 'PASS';
    else
        s = 'below 0.5 target';
    end
end
