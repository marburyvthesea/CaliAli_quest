% JJM 2/2026

% ---- user inputs passed from SLURM ----
disp('combinedDir:'); disp(combinedDir);


% ---------------------------------------
% Alignment-only: find existing MC outputs
% ---------------------------------------
CaliAli_options = CaliAli_demo_parameters();

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
