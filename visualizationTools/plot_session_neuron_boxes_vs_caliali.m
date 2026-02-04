function plot_session_neuron_boxes_vs_caliali(isa, sessionIdx)
% Left: Original neuron projection (plot_P row "Original", col "Neurons") + 3 ROI boxes
% Right: CaliAli neuron projection (plot_P row "CaliAli", col "Neurons")
%
% Usage:
%   isa = CaliAli_options.inter_session_alignment;
%   plot_session_neuron_boxes_vs_caliali(isa, 1);

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
% 1) Pull neuron projection images from P
%    plot_P uses field (3) = "Neurons"
% -------------------------------
origStack = P.(iOrig)(1,:).(3){1,1};
calStack  = P.(iCal )(1,:).(3){1,1};

origNeuron = pick_frame(origStack, sessionIdx);
calNeuron  = pick_frame(calStack,  sessionIdx);

origNeuron = ensure_rgb(origNeuron);
calNeuron  = ensure_rgb(calNeuron);

% -------------------------------
% 2) Compute rectangles in ORIGINAL coords (no centering)
% -------------------------------
% Original canvas from Mask{sessionIdx}
origMask = logical(A.Mask{sessionIdx});
H0 = size(origMask,1);
W0 = size(origMask,2);

% Where T_Mask canvas sits in ORIGINAL coords (bbox of origMask)
rows0 = find(any(origMask,2));
cols0 = find(any(origMask,1));
if isempty(rows0) || isempty(cols0)
    error("origMask empty for sessionIdx=%d", sessionIdx);
end
x0 = cols0(1);  y0 = rows0(1);            % top-left placement of T_Mask in original

Htmask = size(A.T_Mask,1);
Wtmask = size(A.T_Mask,2);

rectTmask_orig = [x0, y0, Wtmask, Htmask];  % cyan

% Shifts canvas location INSIDE T_Mask:
% We derive it from the T_Mask valid ROI bounds that match shifts canvas size.
% This avoids assumptions and works when shifts canvas is a cropped subregion.
Ht = size(A.shifts,1);
Wt = size(A.shifts,2);

validT = logical(A.T_Mask);

% Find tight bbox of the "valid" region in T_Mask;
% In your case this should become x=276..376, y=72..389 (w=101,h=318)
rowsT = find(any(validT,2));
colsT = find(any(validT,1));
if isempty(rowsT) || isempty(colsT)
    error("T_Mask appears empty.");
end
cropRect_Tmask = [colsT(1) rowsT(1) colsT(end)-colsT(1)+1 rowsT(end)-rowsT(1)+1];

% Sanity: expect cropRect_Tmask to match Wt×Ht. If not, we still proceed,
% but it’s a hint that T_Mask validity is not the shifts canvas region.
if cropRect_Tmask(3) ~= Wt || cropRect_Tmask(4) ~= Ht
    fprintf("Warning: T_Mask bbox is %dx%d but shifts canvas is %dx%d.\n", ...
        cropRect_Tmask(3), cropRect_Tmask(4), Wt, Ht);
end

rectShiftCanvas_orig = [ ...
    x0 + (cropRect_Tmask(1)-1), ...
    y0 + (cropRect_Tmask(2)-1), ...
    Wt, Ht];                                % yellow

% Valid ROI inside shifts canvas (from your shifts-derived bbox)
% (If you computed it already, replace these numbers.)
% Here we derive it generically: "valid pixels" = locations where shifts are finite.
dx = A.shifts(:,:,1,sessionIdx);
dy = A.shifts(:,:,2,sessionIdx);
validShift = isfinite(dx) & isfinite(dy);

rowsS = find(any(validShift,2));
colsS = find(any(validShift,1));
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

% LEFT: Original neurons + boxes
nexttile;
imshow(origNeuron, 'InitialMagnification', 150); axis image; hold on;
title(sprintf('Session %d: Original Neurons + ROI mapping', sessionIdx), 'Interpreter','none');

% draw origMask outline (optional)
B = bwboundaries(origMask);
for k = 1:numel(B)
    xy = B{k};
    plot(xy(:,2), xy(:,1), 'w', 'LineWidth', 1);
end

rectangle('Position', rectTmask_orig,       'EdgeColor',[0 1 1], 'LineWidth',2); % cyan
rectangle('Position', rectShiftCanvas_orig, 'EdgeColor',[1 1 0], 'LineWidth',2); % yellow
rectangle('Position', rectShiftROI_orig,    'EdgeColor',[1 0 1], 'LineWidth',2); % magenta

% legend (dummy handles)
h1 = plot(nan,nan,'-','Color',[0 1 1],'LineWidth',2,'DisplayName','Translations canvas (T\_Mask)');
h2 = plot(nan,nan,'-','Color',[1 1 0],'LineWidth',2,'DisplayName','CaliAli shifts canvas');
h3 = plot(nan,nan,'-','Color',[1 0 1],'LineWidth',2,'DisplayName','Valid ROI (from shifts)');
lgd = legend([h1 h2 h3], 'Location','southoutside'); set(lgd,'Interpreter','none','TextColor','k');

% RIGHT: CaliAli neurons
nexttile;
imshow(calNeuron, 'InitialMagnification', 150); axis image; hold on;
title(sprintf('Session %d: CaliAli Neurons', sessionIdx), 'Interpreter','none');

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
% helper: ensure an image is RGB for imshow
% -------------------------------
function img = pick_frame(stack, idx)
    % Supports:
    %   H×W×N
    %   H×W×3×N
    %   H×W×N×3
    %   H×W (single image)
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
            % H×W×3×N
            if idx > sz(4), error("sessionIdx=%d exceeds stack size %d", idx, sz(4)); end
            img = stack(:,:,:,idx);
            return;
        elseif sz(4)==3
            % H×W×N×3
            if idx > sz(3), error("sessionIdx=%d exceeds stack size %d", idx, sz(3)); end
            img = squeeze(stack(:,:,idx,:)); % -> H×W×3
            return;
        end
    end

    error("Unsupported stack dims: %s", mat2str(sz));
end

function imrgb = ensure_rgb(im)
    % Accepts H×W, H×W×1, H×W×3, uint8 or float.
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
            % keep relative intensity but scale to [0,1] for display
            imrgb = mat2gray(im);
        end
    else
        error("Unexpected image dims: %s", mat2str(size(im)));
    end
end


