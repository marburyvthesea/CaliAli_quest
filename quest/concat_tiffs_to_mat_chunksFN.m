function outMatPath = concat_tiffs_to_mat_chunksFN(inDir, outMatPath, varargin)
% concat_tiffs_to_mat_chunks  Concatenate multiple TIFF stacks into one Y in a MAT-file (chunked).
%
% Writes Y as [H x W x totalFrames] using matfile (-v7.3).
% Reads one TIFF at a time, writes it, clears RAM.
%
% Optional name/value:
%   'Pattern'   (default '*_converted.tif*')
%   'VarName'   (default 'Y')
%   'SaveOpts'  (default true)  -> saves a small struct with source file list
%
% Example:
%   concat_tiffs_to_mat_chunksFN('/path/day_001', '/path/day_001/combined.mat');

p = inputParser;
p.addParameter('Pattern', '*_converted.tif*', @(s)ischar(s)||isstring(s));
p.addParameter('VarName', 'Y', @(s)ischar(s)||isstring(s));
p.addParameter('SaveOpts', true, @(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
pat = char(p.Results.Pattern);
varName = char(p.Results.VarName);

if nargin < 2 || isempty(outMatPath)
    outMatPath = fullfile(inDir, 'combined_converted.mat');
end

[paths, names] = list_tiffs_naturalFN(inDir, pat);
fprintf('Found %d TIFF(s):\n', numel(paths));
disp(names(:));

% --- Probe first TIFF to get H/W and class ---
Y0 = tiff_reader_fast(paths{1});     % your function
[H, W, F0] = size(Y0);
cls = class(Y0);
fprintf('First TIFF: %s -> %dx%dx%d (%s)\n', names{1}, H, W, F0, cls);
clear Y0

% --- Compute total frames without loading full image data ---
% Use imfinfo (fast metadata) per file
F = zeros(1, numel(paths));
for k = 1:numel(paths)
    info = imfinfo(paths{k});
    F(k) = numel(info);
end
Ftot = sum(F);
fprintf('Total frames across all TIFFs: %d\n', Ftot);

% --- Create output MAT (must be -v7.3 for matfile partial writes) ---
if exist(outMatPath, 'file')
    warning('Output exists; overwriting: %s', outMatPath);
    delete(outMatPath);
end

mout = matfile(outMatPath, 'Writable', true);

% Preallocate on disk WITHOUT allocating huge RAM:
% (This grows the variable on disk; MATLAB doesn't have to build a full zeros array in memory.)
mout.(varName)(H, W, Ftot) = cast(0, cls);

% Optional: store provenance
if p.Results.SaveOpts
    meta = struct();
    meta.source_dir = inDir;
    meta.source_files = names;
    meta.source_paths = paths;
    meta.frames_per_file = F;
    meta.created = char(datetime('now'));
    mout.concat_meta = meta;
end

% --- Stream: read each TIFF, write its frames, clear it ---
idx = 1;
for k = 1:numel(paths)
    fprintf('Reading %d/%d: %s\n', k, numel(paths), names{k});
    Yk = tiff_reader_fast(paths{k});      % loads only this TIFF stack
    [h2,w2,fk] = size(Yk);
    assert(h2==H && w2==W, 'Size mismatch in %s: got %dx%d, expected %dx%d', names{k}, h2,w2,H,W);

    mout.(varName)(:,:,idx:idx+fk-1) = Yk;   % write chunk
    fprintf('  wrote frames [%d..%d]\n', idx, idx+fk-1);

    idx = idx + fk;
    clear Yk
end

fprintf('Saved: %s\n', outMatPath);
end