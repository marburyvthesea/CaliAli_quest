function outMatPath = concat_ds_mat_files_matfile(paths, outMatPath, startIdx, endIdx)
% concat_ds_mat_files_matfile  Concatenate Y from *_ds.mat using matfile (RAM-safe).
%
% Usage:
%   [paths,names] = list_ds_mat_files(inDir);
%   out = concat_ds_mat_files_matfile(paths, fullfile(inDir,'combined_ds.mat'));
%
% Optional subset:
%   out = concat_ds_mat_files_matfile(paths, outPath, 5, 20);  % only files 5..20
%
% Inputs:
%   paths      - 1xN cell array of full file paths
%   outMatPath - output .mat path
%   startIdx   - optional start index into paths (default 1)
%   endIdx     - optional end index into paths   (default numel(paths))
%
% Output:
%   outMatPath - same as input, returned for convenience

assert(iscell(paths) && ~isempty(paths), 'paths must be a non-empty cell array of file paths.');

if nargin < 2 || isempty(outMatPath)
    outMatPath = fullfile(fileparts(paths{1}), 'combined_ds.mat');
end
if nargin < 3 || isempty(startIdx), startIdx = 1; end
if nargin < 4 || isempty(endIdx),   endIdx   = numel(paths); end

N = numel(paths);
assert(startIdx >= 1 && startIdx <= N, 'startIdx out of range.');
assert(endIdx   >= 1 && endIdx   <= N, 'endIdx out of range.');
assert(startIdx <= endIdx, 'startIdx must be <= endIdx.');

pathsUse = paths(startIdx:endIdx);
fprintf('Concatenating files %d..%d (total %d files)\n', startIdx, endIdx, numel(pathsUse));

% ---- Scan metadata ----
F = zeros(1, numel(pathsUse));
for k = 1:numel(pathsUse)
    s = whos('-file', pathsUse{k}, 'Y');
    assert(~isempty(s), 'No variable Y in %s', pathsUse{k});
    if k == 1
        H = s.size(1); W = s.size(2); cls = s.class;
    else
        assert(s.size(1)==H && s.size(2)==W, 'Size mismatch in %s', pathsUse{k});
        assert(strcmp(s.class, cls), 'Class mismatch in %s', pathsUse{k});
    end
    F(k) = s.size(3);
end
Ftot = sum(F);
fprintf('Output Y will be %dx%dx%d (%s)\n', H, W, Ftot, cls);

% ---- Create output + preallocate ----
mout = matfile(outMatPath, 'Writable', true);
mout.Y = zeros(H, W, Ftot, cls);

% Save options from first selected file (not necessarily global-first)
tmp = load(pathsUse{1}, 'CaliAli_options');
if isfield(tmp, 'CaliAli_options')
    mout.CaliAli_options = tmp.CaliAli_options;
else
    warning('CaliAli_options not found in %s (skipping saving options).', pathsUse{1});
end

% ---- Append each chunk ----
idx = 1;
for k = 1:numel(pathsUse)
    minp = matfile(pathsUse{k});
    nk = size(minp, 'Y', 3);
    mout.Y(:,:,idx:idx+nk-1) = minp.Y(:,:,1:nk);
    fprintf('Wrote %d/%d: %s (%d frames) -> [%d..%d]\n', ...
        k, numel(pathsUse), pathsUse{k}, nk, idx, idx+nk-1);
    idx = idx + nk;
end

fprintf('Saved combined file: %s\n', outMatPath);
end

