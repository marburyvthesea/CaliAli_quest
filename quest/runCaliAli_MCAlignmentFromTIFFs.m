%% modification of "Demo_pipeline.mlx" to run on quest 
% JJM 1/2026


%multiTiffInput = {'/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m326_Yiwen/day_001_04012025_13_54_32', ...
%                    '/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m326_Yiwen/day_002_04022025_15_27_34'} ; 
% dsPath required
% BVsize_str optional: "[1.6, 1.75]" or "1.6,1.75" or "1.6 1.75"
% gSig_str optional: "4"

%% concat folder with multiple grayscale tiffs into a large matlab file 

input_files={};
for i = 1:length(multiTiffInput)
    inDir = multiTiffInput{i};
    outMat = strcat(inDir,'_denoised_converted_concat.mat');
    concat_tiffs_to_mat_chunksFN(inDir, outMat, 'Pattern', 'denoised*_converted.tif*', 'VarName', 'Y');
    input_files{i}=outMat; 
end

%%
CaliAli_options = CaliAli_demo_parameters();
disp('loaded default parameters')

% ---- parse overrides (empty => use defaults) ----
BVsize = parseBVsize2(BVsize_str);   % [] or 1x2
gSig   = parseScalarPos(gSig_str);   % [] or scalar

% ---- BEFORE motion correction: optionally update BVsize ----
if ~isempty(BVsize)
    CaliAli_options.motion_correction.BVsize = BVsize;
    fprintf("Set BVsize (pre-MC) = [%g %g]\n", BVsize(1), BVsize(2));
else
    disp("BVsize not provided: using defaults from CaliAli_demo_parameters()");
end

%% pipe output of downsampling into motion correction and run 

CaliAli_options.motion_correction.input_files = input_files ;

CaliAli_options = CaliAli_motion_correction_quest(CaliAli_options);

%% pipe output of motion correction into intersesion alignment 

CaliAli_options.inter_session_alignment.input_files = CaliAli_options.motion_correction.output_files;

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


%% saved intersession alignemnt file
disp('saved intersession alignemnt file')
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions)


%% 
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

