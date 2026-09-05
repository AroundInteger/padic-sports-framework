% SETUP_PATH  Add MATLAB/ to the path; run from repository root.
%
%   cd('/path/to/p-adic-systems')
%   setup_path
%   run_framework

    repo_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repo_root, 'MATLAB'));
    fprintf('Added %s to path. Working directory should be:\n  %s\n', ...
        fullfile(repo_root, 'MATLAB'), repo_root);
