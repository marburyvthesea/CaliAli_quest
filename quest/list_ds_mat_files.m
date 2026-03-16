function [paths, names] = list_ds_mat_files(inDir, pattern)
% list_ds_mat_files  Return sorted list of *_ds.mat files in a directory.
%
% Usage:
%   [paths,names] = list_ds_mat_files(inDir)
%   [paths,names] = list_ds_mat_files(inDir, '*_ds.mat')
%
% Outputs:
%   paths  - full paths (1xN cell)
%   names  - basenames  (1xN cell)

if nargin < 2 || isempty(pattern)
    pattern = '*_ds.mat';
end

d = dir(fullfile(inDir, pattern));
assert(~isempty(d), 'No files matching %s found in: %s', pattern, inDir);

names = {d.name};

% Prefer natural sort if available
if exist('natsortfiles', 'file') == 2
    names = natsortfiles(names);
else
    names = sort(names);
end

paths = fullfile(inDir, names);
paths = reshape(paths, 1, []);
names = reshape(names, 1, []);

% quick print
fprintf('Found %d files in %s\n', numel(paths), inDir);
disp(names(1:min(10,numel(names))));
end

