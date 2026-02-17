srcFile = "/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m7_day1_2_9_test/Day9rec_2025_01_28_14_08_34_My_V4_Miniscope_53_ds_mc_Aligned.h5";
srcPath = "/mov";
dstFile = "/Users/johnmarshall/Documents/Analysis/miniscope_analysis/caliAliData/m7_day1_2_9_test/Day9rec_2025_01_28_14_08_34_My_V4_Miniscope_53_ds_mc_Aligned_rechunk.h5";
dstPath = "/mov";

% Read source dataset info
din = h5info(srcFile, srcPath);
sz  = din.Dataspace.Size;      % [316 98 T]
dt  = din.Datatype;            % preserve type

% Create destination dataset with desired chunking
if isfile(dstFile); delete(dstFile); end

h5create(dstFile, dstPath, sz, ...
    "Datatype", class(h5read(srcFile, srcPath, [1 1 1], [1 1 1])), ... % quick type inference
    "ChunkSize", [sz(1) sz(2) 1], ...
    "Deflate", 1);   % optional compression (set to [] / omit if you don't want)

% Copy frame-by-frame
T = sz(3);
for t = 1:T
    frame = h5read(srcFile, srcPath, [1 1 t], [sz(1) sz(2) 1]);
    h5write(dstFile, dstPath, frame, [1 1 t], [sz(1) sz(2) 1]);
    if mod(t,500)==0, fprintf("Copied %d/%d frames\n", t, T); end
end
