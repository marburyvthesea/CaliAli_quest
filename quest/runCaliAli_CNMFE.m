%% modification of "Demo_pipeline.mlx" to run on quest 
% JJM 1/2026

%
disp('running CNMFE on aligned sessions')
disp(alignedMATFile)

CaliAli_options = CaliAli_demo_parameters();

%% running CNMFE from here 
inputCellArrayofFiles = {alignedMATFile}
File_path = CaliAli_cnmfe_quest(inputCellArrayofFiles)

disp(File_path)

