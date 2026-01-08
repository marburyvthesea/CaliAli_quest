%% modification of "Demo_pipeline.mlx" to run on quest 
% JJM 1/2026

%
CaliAli_options = CaliAli_demo_parameters();

%manually inputting files 
%CaliAli_options.downsampling.input_files{1,1} = '/gpfs/home/jma819/CaliAli/260105_151408_ses00.avi' ; 
%CaliAli_options.downsampling.input_files{1,2} = '/gpfs/home/jma819/CaliAli/260105_151408_ses01.avi' ; 
%CaliAli_options.downsampling.input_files{1,3} = '/gpfs/home/jma819/CaliAli/260105_151408_ses02.avi' ; 
%CaliAli_options.downsampling.input_files{1,4} = '/gpfs/home/jma819/CaliAli/260105_151408_ses03.avi' ; 

dsList = dir(fullfile(dsPath, '*ds.mat'));
assert(~isempty(dsList), 'No *ds.mat files found in: %s', dsPath);

dsNames = sort({dsList.name});                     % works because 00,01,02...
dsPaths = fullfile(dsPath, dsNames);
CaliAli_options.motion_correction.input_files = reshape(dsPaths, 1, []);

%% run motion correction 

CaliAli_options = CaliAli_motion_correction(CaliAli_options);

%% pipe output of motion correction into intersesion alignment and run 

CaliAli_options.inter_session_alignment.input_files = CaliAli_options.motion_correction.output_files ;

CaliAli_options = CaliAli_align_sessions_quest(CaliAli_options);

fprintf('BV Score: %.4f\n', CaliAli_options.inter_session_alignment.BV_score);


%% saved intersession alignemnt file
disp('saved intersession alignemnt file')
disp(CaliAli_options.inter_session_alignment.out_aligned_sessions)


%% if running CNMFE from here 
% inputCellArrayofFiles = {CaliAli_options.inter_session_alignment.out_aligned_sessions}
% File_path = CaliAli_cnmfe_quest(inputCellArrayofFiles)

