%% load the saved CaliAliOptions data structure 

A = isa ; 


%% look at how masks affected cropping
%A = CaliAli_options.inter_session_alignment;


%% 1) Start with "all valid"
baseMask = logical(A.T_Mask);          % pixel-sized reference mask
validAll = baseMask;

%%
% Intersect per-session masks ONLY if they match the base size
if isfield(A,'Mask') && iscell(A.Mask)
    for i = 1:numel(A.Mask)
        Mi = A.Mask{i};
        if isempty(Mi), continue; end
        Mi = logical(Mi);

        if isequal(size(Mi), size(baseMask))
            validAll = validAll & Mi;
        else
            fprintf("Skipping Mask{%d}: %s (base is %s)\n", ...
                i, mat2str(size(Mi)), mat2str(size(baseMask)));
        end
    end
end

% Tight bounding box in T_Mask coordinates
rows = find(any(validAll,2));
cols = find(any(validAll,1));
cropRect = [cols(1) rows(1) cols(end)-cols(1)+1 rows(end)-rows(1)+1];
fprintf("Common valid ROI (T_Mask coords): x=%d..%d, y=%d..%d => w=%d, h=%d\n", ...
    cols(1), cols(end), rows(1), rows(end), cropRect(3), cropRect(4));


%% 3) Also intersect global masks if you want
if isfield(A,'T_Mask') && ~isempty(A.T_Mask)
    validAll = validAll & logical(A.T_Mask);
end
if isfield(A,'NR_Mask') && ~isempty(A.NR_Mask)
    validAll = validAll & logical(A.NR_Mask);
end

%% 4) Compute tight bounding box of the intersection
rows = find(any(validAll, 2));
cols = find(any(validAll, 1));

cropRect = [cols(1) rows(1) cols(end)-cols(1)+1 rows(end)-rows(1)+1]; % [x y w h]
fprintf("Common valid ROI: x=%d..%d, y=%d..%d  =>  w=%d, h=%d\n", ...
    cols(1), cols(end), rows(1), rows(end), cropRect(3), cropRect(4));

%% represent this cropping visually 
%% Visualize how masks reduce the FOV (overlay on 600x600 canvas)

A = CaliAli_options.inter_session_alignment;

baseH = 600; baseW = 600;  % your original FOV

% ---------- helper: embed smaller mask into base canvas (centered) ----------
embedCentered = @(m) local_embedCentered(m, baseH, baseW);

% Embed the global masks
T = embedCentered(logical(A.T_Mask));
NR = embedCentered(logical(A.NR_Mask));

% Start with intersection of global masks
validAll = T & NR;

% Embed per-session masks (they may differ slightly in size)
Mcell = cell(size(A.Mask));
for i = 1:numel(A.Mask)
    if isempty(A.Mask{i})
        Mcell{i} = [];
        fprintf("Mask{%d}: empty\n", i);
    else
        fprintf("Mask{%d}: %s\n", i, mat2str(size(A.Mask{i})));
        Mcell{i} = embedCentered(logical(A.Mask{i}));
        validAll = validAll & Mcell{i};
    end
end

% Compute tight bounding box of intersection in BASE coords (600x600)
rows = find(any(validAll, 2));
cols = find(any(validAll, 1));
cropRect = [cols(1) rows(1) cols(end)-cols(1)+1 rows(end)-rows(1)+1]; % [x y w h]
fprintf("Common valid ROI (base coords): x=%d..%d, y=%d..%d => w=%d, h=%d\n", ...
    cols(1), cols(end), rows(1), rows(end), cropRect(3), cropRect(4));

% ---------- plot ----------
figure('Color','w'); 
imshow(0.2*ones(baseH, baseW), 'InitialMagnification', 150); % neutral background
hold on; axis image; title('CaliAli mask/cropping visualization (embedded into 600x600)');

% Outline global masks
hT  = plotMaskOutline(T,  'y', 2);   set(hT,  'DisplayName','T\_Mask');
hNR = plotMaskOutline(NR, 'c', 2);   set(hNR, 'DisplayName','NR\_Mask');

% Per-session: plot outlines and keep ONE representative handle per session
nSess = numel(Mcell);
hSess = gobjects(nSess,1);

colors = {'r','g','b','m',[1 1 1],[1 .5 0],[.5 1 .5],[.5 .5 1]}; % extend if needed

for i = 1:nSess
    if ~isempty(Mcell{i})
        ci = colors{1+mod(i-1,numel(colors))};

        % use a version of plotMaskOutline that accepts RGB too (see below)
        hSess(i) = plotMaskOutline(Mcell{i}, ci, 1);

        if isgraphics(hSess(i))
            set(hSess(i), 'DisplayName', sprintf('Mask{%d}', i));
        end
    end
end

% --- intersection + ROI ---
hAll = plotMaskOutline(validAll, 'k', 3);
if ishandle(hAll), set(hAll,'DisplayName','intersection (all masks)'); end

rectangle('Position', cropRect, 'EdgeColor','w', 'LineWidth',2, 'LineStyle','--');
hRectLegend = plot(nan, nan, 'w--', 'LineWidth', 2, 'DisplayName','tight ROI');

% ---- build legend handle list robustly ----
hList = [];
if ishandle(hT),  hList(end+1) = hT;  end
if ishandle(hNR), hList(end+1) = hNR; end

for i = 1:numel(hSess)
    if ishandle(hSess(i))
        hList(end+1) = hSess(i);
    end
end

if ishandle(hAll),        hList(end+1) = hAll;        end
if ishandle(hRectLegend), hList(end+1) = hRectLegend; end

lgd = legend(hList, 'Location','southoutside');
set(lgd,'Interpreter','none','TextColor','k');



%% ---------- local functions ----------
function out = local_embedCentered(m, baseH, baseW)
    % Embed m into a baseH x baseW false canvas, centered.
    [h,w] = size(m);
    out = false(baseH, baseW);

    % center placement
    offY = floor((baseH - h)/2);
    offX = floor((baseW - w)/2);

    % safety clamp (in case someone passes larger-than-base)
    y1 = max(1, 1+offY);           y2 = min(baseH, offY+h);
    x1 = max(1, 1+offX);           x2 = min(baseW, offX+w);

    my1 = 1 + (y1 - (1+offY));     my2 = my1 + (y2-y1);
    mx1 = 1 + (x1 - (1+offX));     mx2 = mx1 + (x2-x1);

    out(y1:y2, x1:x2) = m(my1:my2, mx1:mx2);
end

function h = plotMaskOutline(mask, colorSpec, lw)
    h = gobjects(1,1);
    if ~any(mask(:)), return; end

    B = bwboundaries(mask);

    for k = 1:numel(B)
        xy = B{k};
        hk = plot(xy(:,2), xy(:,1), 'LineWidth', lw, 'Color', colorSpec);

        % capture the first real line as the representative handle
        if ~ishandle(h)
            h = hk;
        end
    end
end