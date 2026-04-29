% JJM 2/2026

% ---- user inputs passed from SLURM ----
disp('combinedDir:'); disp(combinedDir);
if ~exist('BVsize_str', 'var')
    BVsize_str = '';
end
if ~exist('gSig_str', 'var')
    gSig_str = '';
end


% ---------------------------------------
% Alignment-only: find existing MC outputs
% ---------------------------------------
CaliAli_options = CaliAli_demo_parameters();
BVsize = parseBVsize2(BVsize_str);
gSig   = parseScalarPos(gSig_str);

detList = dir(fullfile(combinedDir, '*_ds_mc_det.mat'));
mcList = dir(fullfile(combinedDir, '*_ds_mc.mat'));

if ~isempty(detList)
    useList = detList;
    fprintf("Found %d *_ds_mc_det.mat files (using these)\n", numel(detList));
elseif ~isempty(mcList)
    useList = mcList;
    fprintf("Found %d *_ds_mc.mat files (no det files found)\n", numel(mcList));
else
    error("No *_ds_mc_det.mat or *_ds_mc.mat files found in: %s", combinedDir);
end

% sort by name for stable order
[~,ix] = sort({useList.name});
useList = useList(ix);

% Build full paths and sort (so sessions are stable order)
mcPaths = fullfile({useList.folder}, {useList.name});
mcPaths = reshape(mcPaths, 1, []);   % row cell array like CaliAli expects

disp("First few MC inputs:");
disp(mcPaths(1:min(5,numel(mcPaths))));

% ---------------------------------------
% Run ONLY inter-session alignment
% ---------------------------------------
CaliAli_options.inter_session_alignment.input_files = mcPaths;
if ~isempty(BVsize)
    CaliAli_options.inter_session_alignment.BVsize = BVsize;
    fprintf("Set BVsize (pre-align) = [%g %g]\n", BVsize(1), BVsize(2));
else
    disp("BVsize not provided: using defaults from CaliAli_demo_parameters()");
end
if ~isempty(gSig)
    CaliAli_options.inter_session_alignment.gSig = gSig;
    fprintf("Set gSig (pre-align) = %g\n", gSig);
else
    disp("gSig not provided: using defaults from CaliAli_demo_parameters()");
end

% (optional) checkpoint before expensive step
save(fullfile(combinedDir,"CaliAli_checkpoint_beforeAlign.mat"), ...
     "CaliAli_options","-v7.3");

CaliAli_options = CaliAli_align_sessions_quest(CaliAli_options);

fprintf('BV Score: %.4f\n', CaliAli_options.inter_session_alignment.BV_score);

disp('saved intersession alignment file:');
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions);

% (optional) checkpoint after
save(fullfile(combinedDir,"CaliAli_checkpoint_afterAlign.mat"), ...
     "CaliAli_options","-v7.3");

function v = parseBVsize2(s)
v = [];
if nargin < 1 || isempty(s), return; end
s = string(s);
s = strtrim(s);
if s == "", return; end

s = erase(s, "[");
s = erase(s, "]");
s = strrep(s, ";", " ");
s = strrep(s, ",", " ");

nums = sscanf(s, "%f");
if numel(nums) ~= 2 || any(isnan(nums)) || any(nums <= 0)
    warning("BVsize provided but not valid (need 2 positive numbers): %s (ignoring)", s);
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
    warning("gSig provided but not valid (need positive scalar): %s (ignoring)", s);
    return;
end
x = tmp;
end
