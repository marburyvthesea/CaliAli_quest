function runCaliAli_dsMCAlignmentFNfromTiffsorMat(multiTiffInput, dsInput, BVsize_str, gSig_str)
% runCaliAli_MCAlignmentFNfromTiffs
%
% multiTiffInput can be:
%   (A) cell array of directories containing denoised*_converted.tif*
%   (B) a directory containing *_denoised_converted_concat.mat files
%   (C) cell array of *_denoised_converted_concat.mat file paths
%
% dsInput optional numeric downsample factor (spatial_ds). Use [] or "" to keep default.
% BVsize_str optional: "[1.6, 1.75]" or "1.6,1.75" or "1.6 1.75"
% gSig_str   optional: "4"

CaliAli_options = CaliAli_demo_parameters();
disp('loaded default parameters')

% ---- parse overrides (empty => use defaults) ----
BVsize = parseBVsize2(BVsize_str);   % [] or 1x2
gSig   = parseScalarPos(gSig_str);   % [] or scalar
dsVal  = parseScalarPosAllowEmpty(dsInput); % [] or scalar

% ---- BEFORE motion correction: optionally update BVsize ----
if ~isempty(BVsize)
    CaliAli_options.motion_correction.BVsize = BVsize;
    fprintf("Set BVsize (pre-MC) = [%g %g]\n", BVsize(1), BVsize(2));
else
    disp("BVsize not provided: using defaults from CaliAli_demo_parameters()");
end

% ------------------------------------------------------------
% 1) Build input_files as *_denoised_converted_concat.mat paths
% ------------------------------------------------------------
input_files = resolve_concat_mat_inputs(multiTiffInput);

disp('Using concat mat inputs:');
disp(input_files(:));

% ------------------------------------------------------------
% 2) Downsample BEFORE motion correction (skip if dsVal==1)
% ------------------------------------------------------------

if isempty(dsVal) || dsVal == 1
    % No downsampling (or dsInput=1): use the concat .mat inputs directly
    disp("Skipping downsampling (dsInput empty or == 1).");
    CaliAli_options.motion_correction.input_files = input_files;

else
    % Downsample
    CaliAli_options.downsampling.input_files = input_files;
    CaliAli_options.downsampling.spatial_ds  = dsVal;
    fprintf("Set downsampling spatial_ds = %g\n", dsVal);

    CaliAli_options = CaliAli_downsample_batch(CaliAli_options);

    disp('downsampling finished, saved files:');
    disp(CaliAli_options.downsampling.output_files(:));

    % Pipe downsample output into motion correction
    CaliAli_options.motion_correction.input_files = CaliAli_options.downsampling.output_files;
end

% ------------------------------------------------------------
% 3) Run motion correction
% ------------------------------------------------------------
CaliAli_options = CaliAli_motion_correction_quest(CaliAli_options);

% ------------------------------------------------------------
% 4) Pipe MC output into intersession alignment
% ------------------------------------------------------------
CaliAli_options.inter_session_alignment.input_files = CaliAli_options.motion_correction.output_files;

% ---- BEFORE alignment: optionally update BVsize and gSig ----
if ~isempty(BVsize)
    CaliAli_options.inter_session_alignment.BVsize = BVsize;
    fprintf("Set BVsize (pre-align) = [%g %g]\n", BVsize(1), BVsize(2));
end
if ~isempty(gSig)
    CaliAli_options.inter_session_alignment.gSig = gSig;
    fprintf("Set gSig (pre-align) = %g\n", gSig);
else
    disp("gSig not provided: using defaults from CaliAli_demo_parameters()");
end

% ------------------------------------------------------------
% 5) Run alignment
% ------------------------------------------------------------
CaliAli_options = CaliAli_align_sessions_quest(CaliAli_options);

fprintf('BV Score: %.4f\n', CaliAli_options.inter_session_alignment.BV_score);
disp('saved intersession alignment file');
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions);

end

% ========================= helpers =========================

function input_files = resolve_concat_mat_inputs(multiTiffInput)
% Returns a row cell array of full paths to *_denoised_converted_concat.mat

% Case 1: user passed a single string/char (maybe a directory, maybe a file)
if ischar(multiTiffInput) || (isstring(multiTiffInput) && isscalar(multiTiffInput))
    p = char(multiTiffInput);
    if isfolder(p)
        d = dir(fullfile(p, '*_denoised_converted_concat.mat'));
        assert(~isempty(d), 'No *_denoised_converted_concat.mat found in: %s', p);
        names = sort({d.name});
        input_files = fullfile(p, names);
        input_files = reshape(input_files, 1, []);
        return;
    elseif isfile(p)
        input_files = {p};
        return;
    else
        error('multiTiffInput not found as folder or file: %s', p);
    end
end

% Case 2: user passed a cell array
assert(iscell(multiTiffInput) && ~isempty(multiTiffInput), ...
    'multiTiffInput must be a folder path, file path, or cell array.');

% If it's a cell array of MAT files already, just use them
allAreMat = all(cellfun(@(x) ischar(x)||isstring(x), multiTiffInput)) && ...
           all(cellfun(@(x) endsWith(string(x), ".mat", "IgnoreCase", true), multiTiffInput));

if allAreMat
    input_files = cellfun(@char, multiTiffInput, 'UniformOutput', false);
    % sanity check existence
    for i = 1:numel(input_files)
        assert(isfile(input_files{i}), 'MAT file not found: %s', input_files{i});
    end
    input_files = reshape(input_files, 1, []);
    return;
end

% ---- NEW: cell array of folder(s) that already contain *_denoised_converted_concat.mat ----
allAreDirs = all(cellfun(@(x) (ischar(x)||isstring(x)) && isfolder(char(x)), multiTiffInput));

if allAreDirs
    % If every folder contains concat mats, use those and skip TIFF concatenation
    allHaveConcat = true;
    perDirFiles = cell(1,numel(multiTiffInput));
    for ii = 1:numel(multiTiffInput)
        p = char(multiTiffInput{ii});
        d = dir(fullfile(p, '*_denoised_converted_concat.mat'));
        if isempty(d)
            allHaveConcat = false;
            break;
        end
        perDirFiles{ii} = fullfile(p, sort({d.name}));
    end

    if allHaveConcat
        input_files = [perDirFiles{:}];
        input_files = reshape(input_files, 1, []);
        return;
    end
    % else: fall through to TIFF-concat behavior (treat each dir as TIFF dir)
end

% Otherwise treat as list of directories containing TIFFs
input_files = cell(1, numel(multiTiffInput));
for i = 1:numel(multiTiffInput)
    inDir = char(multiTiffInput{i});
    assert(isfolder(inDir), 'Expected folder, got: %s', inDir);

    outMat = strcat(inDir, '_denoised_converted_concat.mat');

    if isfile(outMat)
        fprintf("Found existing concat mat (skipping TIFF concat): %s\n", outMat);
    else
        fprintf("Concatenating TIFFs in %s -> %s\n", inDir, outMat);
        concat_tiffs_to_mat_chunksFN(inDir, outMat, ...
            'Pattern', 'denoised*_converted.tif*', ...
            'VarName', 'Y');
    end

    input_files{i} = outMat;
end
input_files = reshape(input_files, 1, []);
end

function v = parseBVsize2(s)
v = [];
if nargin < 1 || isempty(s), return; end
s = string(s); s = strtrim(s);
if s == "", return; end
s = erase(s, "["); s = erase(s, "]");
s = strrep(s, ";", " "); s = strrep(s, ",", " ");
nums = sscanf(s, "%f");
if numel(nums) ~= 2 || any(isnan(nums)) || any(nums <= 0)
    warning("BVsize invalid (need 2 positive numbers): %s (ignoring)", s);
    return;
end
v = nums(:).';
end

function x = parseScalarPos(s)
x = [];
if nargin < 1 || isempty(s), return; end
s = strtrim(string(s));
if s == "", return; end
tmp = str2double(s);
if isnan(tmp) || ~isfinite(tmp) || tmp <= 0
    warning("Scalar invalid (need positive): %s (ignoring)", s);
    return;
end
x = tmp;
end

function x = parseScalarPosAllowEmpty(s)
% Accepts numeric dsInput too
x = [];
if nargin < 1 || isempty(s), return; end
if isnumeric(s)
    if isscalar(s) && isfinite(s) && s > 0, x = s; end
    return
end
x = parseScalarPos(s);
end