
% mcPath required
% BVsize_str optional: "[1.6, 1.75]" or "1.6,1.75" or "1.6 1.75"
% gSig_str optional: "4"

CaliAli_options = CaliAli_demo_parameters();
disp('loaded default parameters')

% ---- parse overrides (empty => use defaults) ----
BVsize = parseBVsize2(BVsize_str);   % [] or 1x2
gSig   = parseScalarPos(gSig_str);   % [] or scalar

% ---- build ds file list ----
mcList = dir(fullfile(mcPath, '*mc.mat'));
disp('looking for files here:');
disp(mcPath);

assert(~isempty(mcList), 'No *ds.mat files found in: %s', mcPath);

mcNames = sort({mcList.name});
disp('found files');
disp(mcNames);

mcPaths = fullfile(mcPath, mcNames);

%% pipe output of motion correction into intersession alignment
CaliAli_options.inter_session_alignment.input_files = reshape(mcPaths, 1, []);
%%
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

%% run alignment
CaliAli_options = CaliAli_align_sessions_quest(CaliAli_options);

fprintf('BV Score: %.4f\n', CaliAli_options.inter_session_alignment.BV_score);

disp('saved intersession alignment file')
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions)



% -------- helpers --------

function v = parseBVsize2(s)
% returns [] if empty/invalid, else 1x2 double
v = [];
if nargin < 1 || isempty(s), return; end
s = string(s);
s = strtrim(s);
if s == "", return; end

% strip brackets if provided
s = erase(s, "[");
s = erase(s, "]");
s = strrep(s, ";", " ");
s = strrep(s, ",", " ");

nums = sscanf(s, "%f");
if numel(nums) ~= 2 || any(isnan(nums)) || any(nums <= 0)
    warning("BVsize provided but not valid (need 2 positive numbers): %s (ignoring)", s);
    return;
end
v = nums(:).'; % 1x2 row
end

function x = parseScalarPos(s)
% returns [] if empty/invalid, else positive scalar double
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