function plot_session_bv_boxes_vs_caliali(isa, sessionIdx)
% Left: Original BV projection (plot_P row "Original", col "Blood Vessels") + 3 ROI boxes
% Right: CaliAli BV projection (plot_P row "CaliAli", col "Blood Vessels")
%
% Usage:
%   isa = CaliAli_options.inter_session_alignment;
%   plot_session_bv_boxes_vs_caliali(isa, 1);

A = isa;
P = A.P;

% -------------------------------
% 0) Find which P-column is "Original" and which is "CaliAli"
% -------------------------------
names = P.Properties.VariableNames;
iOrig = find(strcmpi(names, "Original"), 1);
iCal  = find(strcmpi(names, "CaliAli"),   1);
if isempty(iOrig) || isempty(iCal)
    error('Could not find P columns named "Original" and/or "CaliAli". Found: %s', strjoin(names, ', '));
end

% -------------------------------
% 1) Pull BV projection images from P
%    plot_P uses field (2) = "Blood Vessels"
% -------------------------------
origStack = P.(iOrig)(1,:).(2){1,1};
calStack  = P.(iCal )(1,:).(2){1,1};

origBV = pick_frame(origStack, sessionIdx);
calBV  = pick_frame(calStack,  sessionIdx);

origBV = ensure_rgb(origBV);
calBV  = ensure_rgb(calBV);

% -------------------------------
% 2) Compute rectangles in ORIGINAL coords (no centering)
% -------------------------------
% Original canvas from Mask{sessionIdx}
origMask = logical(A.Mask{sessionIdx});
H0 = size(origMask,1);
W0 = size(origMask,2);

% Where T_Mask canvas sits in ORIGINAL coords: bbox of origMask
rows0 = find(any(origMask,2));
cols0 = find(any(origMask,1));
if isempty(rows0) || isempty(cols0)
    error("origMask empty for sessionIdx=%d", sessionIdx);
end
x0 = cols0(1);  y0 = rows0(1);

Htmask = size(A.T_Mask,1);
Wtmask = size(A.T_Mask,2);

rectTmask_orig = [x0, y0, Wtmask, Htmask];  % cyan

% Shifts canvas size (this is the Translation/CaliAli canvas)
Ht = size(A.shifts,1);
Wt = size(A.shifts,2);

% Find tight bbox of the valid region in T_Mask (T_Mask coords)
validT = logical(A.T_Mask);
rowsT = find(any(validT,2));
colsT = find(any(validT,1));
if isempty(rowsT) || isempty(colsT)
    error("T_Mask appears empty.");
end
cropRect_Tmask = [colsT(1) rowsT(1) colsT(end)-colsT(1)+1 rowsT(end)-rowsT(1)+1];

% Map the shifts canvas into ORIGINAL coords (placed inside T_Mask bbox)
rectShiftCanvas_orig = [ ...
    x0 + (cropRect_Tmask(1)-1), ...
    y0 + (cropRect_Tmask(2)-1), ...
    Wt, Ht];                                % yellow

% Valid ROI inside shifts canvas (derived from finite shifts for this session)
dx = A.shifts(:,:,1,sessionIdx);
dy = A.shifts(:,:,2,sessionIdx);
validShift = isfinite(dx) & isfinite(dy);

rowsS = find(any(validShift,2));
colsS = find(any(validShift,1));
if isempty(rowsS) || isempty(colsS)
    error("validShift is empty (no finite shifts?) for sessionIdx=%d", sessionIdx);
end
cropRect_shifts = [colsS(1) rowsS(1) colsS(end)-colsS(1)+1 rowsS(end)-rowsS(1)+1];

rectShiftROI_orig = [ ...
    rectShiftCanvas_orig(1) + (cropRect_shifts(1)-1), ...
    rectShiftCanvas_orig(2) + (cropRect_shifts(2)-1), ...
    cropRect_shifts(3), cropRect_shifts(4) ];   % magenta

% -------------------------------
% 3) Plot 2-column figure
% -------------------------------
figure('Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% LEFT: Original BV + boxes
nexttile;
imshow(origBV, 'InitialMagnification', 150); axis image; hold on;
title(sprintf('Session %d: Original BV + ROI mapping', sessionIdx), 'Interpreter','none');

% optional: outline origMask
B = bwboundaries(origMask);
for k = 1:numel(B)
    xy = B{k};
    plot(xy(:,2), xy(:,1), 'w', 'LineWidth', 1);
end

rectangle('Position', rectTmask_orig,       'EdgeColor',[0 1 1], 'LineWidth',2); % cyan
rectangle('Position', rectShiftCanvas_orig, 'EdgeColor',[1 1 0], 'LineWidth',2); % yellow
rectangle('Position', rectShiftROI_orig,    'EdgeColor',[1 0 1], 'LineWidth',2); % magenta

% legend (dummy handles)
h1 = plot(nan,nan,'-','Color',[0 1 1],'LineWidth',2,'DisplayName','Translations canvas (T_Mask)');
h2 = plot(nan,nan,'-','Color',[1 1 0],'LineWidth',2,'DisplayName','CaliAli shifts canvas');
h3 = plot(nan,nan,'-','Color',[1 0 1],'LineWidth',2,'DisplayName','Valid ROI (from shifts)');
lgd = legend([h1 h2 h3], 'Location','southoutside');
set(lgd,'Interpreter','none','TextColor','k');

% RIGHT: CaliAli BV
nexttile;
imshow(calBV, 'InitialMagnification', 150); axis image; hold on;
title(sprintf('Session %d: CaliAli BV', sessionIdx), 'Interpreter','none');

% Print numeric mapping
fprintf("\nSession %d\n", sessionIdx);
fprintf("Original canvas: %dx%d\n", H0, W0);
fprintf("T_Mask canvas in original:       x=%d..%d, y=%d..%d\n", ...
    rectTmask_orig(1), rectTmask_orig(1)+rectTmask_orig(3)-1, ...
    rectTmask_orig(2), rectTmask_orig(2)+rectTmask_orig(4)-1);
fprintf("Shifts canvas in original:       x=%d..%d, y=%d..%d\n", ...
    rectShiftCanvas_orig(1), rectShiftCanvas_orig(1)+rectShiftCanvas_orig(3)-1, ...
    rectShiftCanvas_orig(2), rectShiftCanvas_orig(2)+rectShiftCanvas_orig(4)-1);
fprintf("Valid ROI in original:           x=%d..%d, y=%d..%d\n", ...
    rectShiftROI_orig(1), rectShiftROI_orig(1)+rectShiftROI_orig(3)-1, ...
    rectShiftROI_orig(2), rectShiftROI_orig(2)+rectShiftROI_orig(4)-1);

end

% -------------------------------
% helper: pick one session image from a stack
% -------------------------------
function img = pick_frame(stack, idx)
    sz = size(stack);

    if ismatrix(stack)
        img = stack;
        return;
    end

    if numel(sz)==3
        % H×W×N
        if idx > sz(3), error("sessionIdx=%d exceeds stack size %d", idx, sz(3)); end
        img = stack(:,:,idx);
        return;
    end

    if numel(sz)==4
        % Either H×W×3×N or H×W×N×3
        if sz(3)==3
            if idx > sz(4), error("sessionIdx=%d exceeds stack size %d", idx, sz(4)); end
            img = stack(:,:,:,idx);
            return;
        elseif sz(4)==3
            if idx > sz(3), error("sessionIdx=%d exceeds stack size %d", idx, sz(3)); end
            img = squeeze(stack(:,:,idx,:)); % -> H×W×3
            return;
        end
    end

    error("Unsupported stack dims: %s", mat2str(sz));
end

% -------------------------------
% helper: ensure an image is RGB for imshow
% -------------------------------
function imrgb = ensure_rgb(im)
    im = squeeze(im);
    if ndims(im)==2
        im = mat2gray(im);
        imrgb = repmat(im, [1 1 3]);
    elseif ndims(im)==3 && size(im,3)==1
        im = mat2gray(im);
        imrgb = repmat(im, [1 1 3]);
    elseif ndims(im)==3 && size(im,3)==3
        if isa(im,'uint8')
            imrgb = im;
        else
            imrgb = mat2gray(im);
        end
    else
        error("Unexpected image dims: %s", mat2str(size(im)));
    end
end

