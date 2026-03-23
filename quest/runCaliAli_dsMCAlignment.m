%% modification of "Demo_pipeline.mlx" to run on quest 
% JJM 1/2026


multiTiffInput = {'/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m326_Yiwen/day_001_04012025_13_54_32', ...
                    '/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m326_Yiwen/day_002_04022025_15_27_34'} ; 

%
disp('setting downsampling to')
disp(multiTiffInput)

CaliAli_options = CaliAli_demo_parameters();
CaliAli_options.downsampling.file_extesnion = '.tiff'; 
%CaliAli_options.downsampling.input_files = multiTiffInput; 

CaliAli_options.downsampling.spatial_ds=dsInput;

%% run downsampling

CaliAli_options = CaliAli_downsample_batch(CaliAli_options) ; 

% this should populate the "CaliAli_options.downsampling.output_files" structure
% print to confirm

disp('downsamling finished, saved files:')
disp(CaliAli_options.downsampling.output_files)

%% pipe output of downsampling into motion correction and run 

CaliAli_options.motion_correction.input_files = CaliAli_options.downsampling.output_files ;

CaliAli_options = CaliAli_motion_correction_quest(CaliAli_options);

%% pipe output of motion correction into intersesion alignment and run 

CaliAli_options.inter_session_alignment.input_files = CaliAli_options.motion_correction.output_files;

CaliAli_options = CaliAli_align_sessions_quest(CaliAli_options);

fprintf('BV Score: %.4f\n', CaliAli_options.inter_session_alignment.BV_score);


%% saved intersession alignemnt file
disp('saved intersession alignemnt file')
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions)


%% if running CNMFE from here 
% inputCellArrayofFiles = {CaliAli_options.inter_session_alignment.out_aligned_sessions}
% File_path = CaliAli_cnmfe_quest(inputCellArrayofFiles)

