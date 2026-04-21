function reader = build_reader_fn(fullFileName, ext, opts)
if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'prefer_ffmpeg'), opts.prefer_ffmpeg = true; end
if ~isfield(opts, 'batch_size'), opts.batch_size = []; end
ext = lower(ext);
switch true
    case contains(ext, {'.avi', '.m4v', '.mp4'})
        v = VideoReader(fullFileName);
        reader.nFrames = v.NumFrames;
        reader.size = [v.Height, v.Width];
        reader.fps = v.FrameRate;
        f0 = read(v, 1);
        if size(f0, 3) == 3
            f0 = rgb2gray(f0);
        end
        reader.src_class = class(f0);
        reader.read_range = @(s, e) read_video_range(v, s, e);
        if opts.prefer_ffmpeg && ismac
            ffmpegPath = find_packaged_ffmpeg();
            if ~isempty(ffmpegPath)
                bitDepth = class_to_bitdepth(reader.src_class);
                reader.read_range = @(s, e) read_video_range_ffmpeg(fullFileName, s, e, reader.size, reader.fps, ffmpegPath, bitDepth);
            end
        end
    case contains(ext, '.isxd')
        movieObj = open_isxd_movie(fullFileName);
        reader.nFrames = movieObj.timing.num_samples;
        f0 = movieObj.get_frame_data(0);
        reader.size = [size(f0, 1), size(f0, 2)];
        reader.src_class = class(f0);
        reader.read_range = @(s, e) read_isxd_range(movieObj, s, e);
    case contains(ext, '.tif')
        info = imfinfo(fullFileName);
        reader.nFrames = numel(info);
        reader.size = [info(1).Height, info(1).Width];
        reader.src_class = bitdepth_to_class(info(1).BitDepth);
        reader.read_range = @(s, e) read_tiff_range(fullFileName, s, e, reader.size);
        % Fast TIFF preloading is avoided in batch mode to keep memory lower
        if isfield(opts, 'batch_size') && ~isempty(opts.batch_size) && opts.batch_size < reader.nFrames
            if exist('cprintf', 'file')
                cprintf('-comment', 'Skipping fast TIFF preload for %s to keep batch memory lower.\n', fullFileName);
            else
                fprintf(1, 'Skipping fast TIFF preload for %s to keep batch memory lower.\n', fullFileName);
            end
        end
    case contains(ext, '.h5')
        info = h5info(fullFileName, '/Object');
        dims = info.Dataspace.Size;
        reader.nFrames = dims(3);
        reader.size = [dims(1), dims(2)];
        sample = h5read(fullFileName, '/Object', [1 1 1], [1 1 1]);
        reader.src_class = class(sample);
        reader.read_range = @(s, e) cast(h5read(fullFileName, '/Object', [1 1 s], [dims(1) dims(2) e - s + 1]), reader.src_class);
    
    case contains(ext, '.mat')
        varName = 'Y';  % or make it opts.varName
        mf = matfile(fullFileName);   % does not load Y
    
        dims = size(mf, varName);     % [H W T]
        reader.nFrames  = dims(3);
        reader.size     = [dims(1), dims(2)];
    
        % Determine class without loading the whole array
        sample = mf.(varName)(1,1,1);
        reader.src_class = class(sample);

        % Must return HxWxN (like all other readers)
        reader.read_range = @(s,e) mf.(varName)(:,:,s:e);

    
    otherwise
        error('Unsupported file format. Supported formats are: .avi, .m4v, .mp4, .isxd, .tif, .tiff, .h5');
end
end