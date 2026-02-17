
%%create video of aligned projections from aligned file

P = isa.P;
%frame = plot_P(P);
%or 
frame = plot_P_JJM(isa);

%% plot where the "aligned regions correspond to back to the original movie
%% Plot Translation canvas + CaliAli(shifts) canvas + ROI on ORIGINAL canvas (no centering)

A = isa;
sessionIdx = 1;

% --- original canvas size from Mask{sessionIdx}
origMask = logical(A.Mask{sessionIdx});
H0 = size(origMask,1);
W0 = size(origMask,2);

% --- where the T_Mask canvas sits in ORIGINAL coords (from origMask bbox)
rows0 = find(any(origMask,2));
cols0 = find(any(origMask,1));
if isempty(rows0) || isempty(cols0)
    error("origMask empty for sessionIdx=%d", sessionIdx);
end
x0 = cols0(1);  y0 = rows0(1);              % top-left of T_Mask canvas in original
bboxW = cols0(end)-cols0(1)+1;
bboxH = rows0(end)-rows0(1)+1;

% --- sanity check: should match T_Mask
Htmask = size(A.T_Mask,1);
Wtmask = size(A.T_Mask,2);
fprintf("Original: %dx%d\n", H0,W0);
fprintf("T_Mask:   %dx%d, origMask bbox: %dx%d\n", Htmask,Wtmask,bboxH,bboxW);

% --- (1) rectangle for full Translation canvas (T_Mask) in ORIGINAL coords
rectTmask_orig = [x0, y0, Wtmask, Htmask];   % [x y w h]

% --- (2) rectangle for full CaliAli shifts canvas inside T_Mask coords
% You already computed from T_Mask validity earlier:
%   Common valid ROI (T_Mask coords): x=276..376, y=72..389 => w=101, h=318
cropRect_Tmask = [276 72 101 318];           % [x y w h] in T_Mask coords

Ht = size(A.shifts,1);   % 318
Wt = size(A.shifts,2);   % 101
fprintf("shifts canvas: %dx%d\n", Ht, Wt);

% Map shifts-canvas rectangle into ORIGINAL coords:
rectShiftCanvas_orig = [ ...
    x0 + (cropRect_Tmask(1)-1), ...
    y0 + (cropRect_Tmask(2)-1), ...
    cropRect_Tmask(3), ...
    cropRect_Tmask(4) ];

% --- (3) ROI inside shifts canvas (from shifts-derived valid ROI)
cropRect_shifts = [2 2 100 317];             % [x y w h] in shifts canvas coords

rectShiftROI_orig = [ ...
    rectShiftCanvas_orig(1) + (cropRect_shifts(1)-1), ...
    rectShiftCanvas_orig(2) + (cropRect_shifts(2)-1), ...
    cropRect_shifts(3), ...
    cropRect_shifts(4) ];

% --- background (use a projection if you have it; otherwise gray)
bg = 0.2*ones(H0,W0,'single');

figure('Color','w');
imshow(bg, [], 'InitialMagnification', 150); axis image; hold on;
title(sprintf('Session %d: Translation + CaliAli crops in ORIGINAL coords', sessionIdx));

% Optional: draw origMask outline to see the kept region
B = bwboundaries(origMask);
for k = 1:numel(B)
    xy = B{k};
    plot(xy(:,2), xy(:,1), 'w', 'LineWidth', 1);
end

% Draw rectangles
rectangle('Position', rectTmask_orig,        'EdgeColor',[0 1 1], 'LineWidth',2); % cyan
rectangle('Position', rectShiftCanvas_orig,  'EdgeColor',[1 1 0], 'LineWidth',2); % yellow
rectangle('Position', rectShiftROI_orig,     'EdgeColor',[1 0 1], 'LineWidth',2); % magenta

% Labels
text(rectTmask_orig(1), rectTmask_orig(2)-8, 'Translations canvas (T\_Mask)', ...
    'Color',[0 1 1], 'FontWeight','bold','Interpreter','none');

text(rectShiftCanvas_orig(1), rectShiftCanvas_orig(2)-8, 'CaliAli shifts canvas (within T\_Mask)', ...
    'Color',[1 1 0], 'FontWeight','bold','Interpreter','none');

text(rectShiftROI_orig(1), rectShiftROI_orig(2)-8, 'Valid ROI (from shifts)', ...
    'Color',[1 0 1], 'FontWeight','bold','Interpreter','none');

% Legend (dummy handles so it always works)
h1 = plot(nan,nan,'-','Color',[0 1 1],'LineWidth',2,'DisplayName','Translations canvas (T\_Mask)');
h2 = plot(nan,nan,'-','Color',[1 1 0],'LineWidth',2,'DisplayName','CaliAli shifts canvas');
h3 = plot(nan,nan,'-','Color',[1 0 1],'LineWidth',2,'DisplayName','Valid ROI (from shifts)');
lgd = legend([h1 h2 h3], 'Location','southoutside');
set(lgd,'Interpreter','none','TextColor','k');

% Print numeric ranges
fprintf("T_Mask in original:       x=%d..%d, y=%d..%d\n", ...
    rectTmask_orig(1), rectTmask_orig(1)+rectTmask_orig(3)-1, ...
    rectTmask_orig(2), rectTmask_orig(2)+rectTmask_orig(4)-1);

fprintf("Shifts canvas in original: x=%d..%d, y=%d..%d\n", ...
    rectShiftCanvas_orig(1), rectShiftCanvas_orig(1)+rectShiftCanvas_orig(3)-1, ...
    rectShiftCanvas_orig(2), rectShiftCanvas_orig(2)+rectShiftCanvas_orig(4)-1);

fprintf("ROI in original:          x=%d..%d, y=%d..%d\n", ...
    rectShiftROI_orig(1), rectShiftROI_orig(1)+rectShiftROI_orig(3)-1, ...
    rectShiftROI_orig(2), rectShiftROI_orig(2)+rectShiftROI_orig(4)-1);

%% plot neuron projections
plot_session_neuron_boxes_vs_caliali(isa, 140)
%% plot BV projections 
plot_session_bv_boxes_vs_caliali(isa, 90)



