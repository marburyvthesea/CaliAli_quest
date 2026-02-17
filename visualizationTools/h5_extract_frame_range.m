function outPath = h5_extract_frame_range(inPath, outDir, frameStart, frameEnd, varargin)
%H5_EXTRACT_FRAME_RANGE  Copy a frame range from an HDF5 movie into a new H5 file.
%
% outPath = h5_extract_frame_range(inPath, outDir, frameStart, frameEnd)
% outPath = h5_extract_frame_range(..., 'Dataset', '/mov', 'ChunkFrames', 200, 'CastTo', '')
%
% Inputs
%   inPath      - path to input .h5
%   outDir      - directory to write output file (created if needed)
%   frameStart  - 1-based start frame (inclusive)
%   frameEnd    - 1-based end frame (inclusive)
%
% Name-Value
%   'Dataset'     - dataset name (default '/mov')
%   'ChunkFrames' - how many frames per read/write chunk (default 200)
%   'CastTo'      - '' (no cast) or e.g. 'single','uint16' (default '')
%
% Notes
% - Works in headless MATLAB.
% - Writes dataset as [H W (frameEnd-frameStart+1)].
% - Preserves input datatype unless CastTo is provided.

p = inputParser;
p.addParameter('Dataset', '/mov', @(s)ischar(s)||isstring(s));
p.addParameter('ChunkFrames', 200, @(x)isnumeric(x)&&isscalar(x)&&x>=1);
p.addParameter('CastTo', '', @(s)ischar(s)||isstring(s));
p.parse(varargin{:});

dset = char(p.Results.Dataset);
chunkFrames = double(p.Results.ChunkFrames);
castTo = char(p.Results.CastTo);

if ~exist(outDir, 'dir'); mkdir(outDir); end

info = h5info(inPath, dset);
sz = info.Dataspace.Size;
assert(numel(sz) == 3, 'Expected dataset %s to be 3D (H×W×T). Got size=%s', dset, mat2str(sz));

H = sz(1); W = sz(2); T = sz(3);

assert(frameStart >= 1 && frameStart <= T, 'frameStart out of range (1..%d)', T);
assert(frameEnd   >= 1 && frameEnd   <= T, 'frameEnd out of range (1..%d)', T);
assert(frameEnd >= frameStart, 'frameEnd must be >= frameStart');

nFramesOut = frameEnd - frameStart + 1;

% build output filename
[~, base, ~] = fileparts(inPath);
outPath = fullfile(outDir, sprintf('%s_frames_%07d_%07d.h5', base, frameStart, frameEnd));
if exist(outPath, 'file'); delete(outPath); end

% Determine datatype to write
inClass = h5_read_datatype_as_matlab_class(info.Datatype);
if isempty(castTo)
    outClass = inClass;
else
    outClass = castTo;
end

% Create output dataset with chunking
% Chunk size: H×W×min(chunkFrames,nFramesOut) (good for sequential frame IO)
chunkSz = [H W min(chunkFrames, nFramesOut)];
h5create(outPath, dset, [H W nFramesOut], 'Datatype', outClass, 'ChunkSize', chunkSz);

% Copy in chunks
outFrame0 = 1; % index into output
for f = frameStart:chunkFrames:frameEnd
    f2 = min(frameEnd, f + chunkFrames - 1);
    countT = f2 - f + 1;

    start = [1 1 f];
    count = [H W countT];

    block = h5read(inPath, dset, start, count);

    if ~isempty(castTo)
        block = cast(block, castTo);
    end

    h5write(outPath, dset, block, [1 1 outFrame0], [H W countT]);
    outFrame0 = outFrame0 + countT;
end

% Optional: write some metadata
h5writeatt(outPath, '/', 'source_file', inPath);
h5writeatt(outPath, '/', 'source_dataset', dset);
h5writeatt(outPath, '/', 'frameStart_1based', int64(frameStart));
h5writeatt(outPath, '/', 'frameEnd_1based', int64(frameEnd));

fprintf('Wrote %d frames (%d..%d) to:\n%s\n', nFramesOut, frameStart, frameEnd, outPath);

end

% --- helper: map H5 datatype -> MATLAB class string (best-effort) ---
function cls = h5_read_datatype_as_matlab_class(dt)
cls = '';
try
    % dt.Class is like 'H5T_INTEGER' / 'H5T_FLOAT'
    % dt.Size is bytes
    if isfield(dt,'Class') && isfield(dt,'Size')
        if strcmp(dt.Class,'H5T_FLOAT')
            if dt.Size == 4, cls = 'single'; elseif dt.Size == 8, cls = 'double'; end
        elseif strcmp(dt.Class,'H5T_INTEGER')
            % Signedness may be in dt.Sign (0/1) in some MATLAB versions
            signed = isfield(dt,'Sign') && dt.Sign ~= 0;
            if dt.Size == 1, cls = ternary(signed,'int8','uint8'); end
            if dt.Size == 2, cls = ternary(signed,'int16','uint16'); end
            if dt.Size == 4, cls = ternary(signed,'int32','uint32'); end
            if dt.Size == 8, cls = ternary(signed,'int64','uint64'); end
        end
    end
catch
end
if isempty(cls)
    % fallback: let h5create default happen if user uses CastTo; otherwise single is safest
    cls = 'single';
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

