function frame = plot_P_JJM(isa)
% frame = plot_P_JJM(isa)
% Like CaliAli's plot_P, but stamps the session basename (no full path).
%
% Input:
%   isa : CaliAli_options.inter_session_alignment struct
%         must contain fields: isa.P and isa.input_files (or input_file_labels)
%
% Output:
%   frame : uint8 movie captured from the tiled figure

P = isa.P;

% ---- get filenames (prefer input_files; fall back to input_file_labels) ----
files = [];
if isfield(isa,'input_files') && ~isempty(isa.input_files)
    files = isa.input_files;
elseif isfield(isa,'input_file_labels') && ~isempty(isa.input_file_labels)
    files = isa.input_file_labels;
else
    % fallback: just label by index
    files = cell(1, size(P.(1)(1,:).(5){1,1}, 4));
    for k = 1:numel(files), files{k} = sprintf('session_%03d', k); end
end

% Ensure row cell array
if isstring(files), files = cellstr(files); end
if ischar(files), files = {files}; end
files = files(:).';  % row

% ---- preprocess P like original ----
for ii = 1:size(P,2)
    P.(ii)(1,:).(1){1,1} = gray2rgb(v2uint8(P.(ii)(1,:).(1){1,1}));
    P.(ii)(1,:).(2){1,1} = gray2rgb(v2uint8(P.(ii)(1,:).(2){1,1}), 'bone');
    P.(ii)(1,:).(3){1,1} = gray2rgb(v2uint8(P.(ii)(1,:).(3){1,1}), 'hot');
    P.(ii)(1,:).(5){1,1} = mat2gray(P.(ii)(1,:).(5){1,1});
end
names = P.Properties.VariableNames;

% ---- figure ----
fig = figure('Visible', 'off');
set(fig, 'Position', [745 49.8 1247.2 828.8]);

nFrames = size(P.(1)(1,:).(5){1,1}, 4);
N = numel(files);

for i = progress(1:nFrames)
    tiledlayout(size(P,2), 4, "TileSpacing", "compact");

    % Choose basename label for this frame index
    if i <= N
        fi = files{i};
        if isstring(fi), fi = char(fi); end
        if iscell(fi), fi = fi{1}; end
        [~, base, ext] = fileparts(fi);
        baseLabel = sprintf('%03d/%03d  %s%s', i, N, base, ext);
    else
        baseLabel = sprintf('%03d/%03d', i, max(i,N));
    end

    for j = 1:size(P,2)
        % ---- Average frame ----
        nexttile;
        imshow(P.(j)(1,:).(1){1,1}(:,:,:,i));
        if j == 1; title("Average frame"); end
        ylabel(names{1, j});
        text(6, 14, baseLabel, 'Color','w', 'FontSize',10, 'FontWeight','bold', ...
             'Interpreter','none');

        % ---- Blood vessels ----
        nexttile;
        imshow(P.(j)(1,:).(2){1,1}(:,:,:,i));
        if j == 1; title("Blood Vessels"); end
        text(6, 14, baseLabel, 'Color','w', 'FontSize',10, 'FontWeight','bold', ...
             'Interpreter','none');

        % ---- Neurons ----
        nexttile;
        imshow(P.(j)(1,:).(3){1,1}(:,:,:,i));
        if j == 1; title("Neurons"); end
        text(6, 14, baseLabel, 'Color','w', 'FontSize',10, 'FontWeight','bold', ...
             'Interpreter','none');

        % ---- BV+Neurons ----
        nexttile;
        imshow(P.(j)(1,:).(5){1,1}(:,:,:,i));
        if j == 1; title("BV+Neurons"); end
        text(6, 14, baseLabel, 'Color','w', 'FontSize',10, 'FontWeight','bold', ...
             'Interpreter','none');

        plot_darkmode
    end

    temp = getframe(fig);
    frame(:,:,:,i) = temp.cdata; %#ok<AGROW>
    drawnow limitrate;
end

close(fig);
implay(frame);
end
