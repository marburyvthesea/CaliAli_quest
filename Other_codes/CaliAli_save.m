function filename = CaliAli_save(target, varargin)
% CaliAli_save: Save or append variables to a MAT-file.
% target:
%   - string filename (original behavior)
%   - cell {filename, session_id, start_frame, end_frame, output_filename} (batch)
% varargin:
%   - positional vars (names via inputname when available), OR
%   - name, value, name, value ... (preferred when names would be lost)
%
% Outputs:
%   - resolved filename used for the save

filename = '';
if iscell(target)
    batch_info = target;
    requested_filename = batch_info{5};
else
    requested_filename = target;
end

filename = resolve_save_target(requested_filename);
if nargin == 1
    return;
end

% ---- build data struct from varargin
data = struct();
if isNameValue(varargin)
    for k = 1:2:numel(varargin)
        varName = varargin{k};
        data.(varName) = varargin{k+1};
    end
else
    for i = 1:numel(varargin)
        varName = inputname(i + 1);
        if isempty(varName), varName = ['var' num2str(i)]; end
        data.(varName) = varargin{i};
    end
end

if isfield(data, 'CaliAli_options')
    data.CaliAli_options = update_saved_output_path( ...
        data.CaliAli_options, requested_filename, filename);
end

% ---- batch mode
if iscell(target)
    % {filename, session_id, start_frame, end_frame, output_filename}
    start_frame     = batch_info{3};
    end_frame       = batch_info{4};
    m = matfile(filename, 'Writable', true);

    fn = fieldnames(data);
    for i = 1:numel(fn)
        field = fn{i};
        if strcmp(field, 'Y')
            m.Y(:, :, start_frame:end_frame) = data.(field);
            fprintf('Saved batch frames %d-%d to %s\n', start_frame, end_frame, filename);
        else
            % recurse using NAME–VALUE so the name is preserved
            CaliAli_save(filename, field, data.(field));
        end
    end
    return;
end

% ---- original (non-batch) behavior
if exist(filename, 'file')
    save(filename, '-nocompression', '-struct', 'data', '-append');
else
    save(filename, '-v7.3', '-nocompression', '-struct', 'data');
end
end

function tf = isNameValue(args)
tf = ~isempty(args) && mod(numel(args),2)==0;
if tf
    names = args(1:2:end);
    tf = all(cellfun(@(x) (ischar(x) || (isstring(x)&&isscalar(x))), names));
end
end

function filename = resolve_save_target(target)
filename = normalize_filename(target);
[filepath, name, ext] = fileparts(filename);

if ~strcmpi(ext, '.mat')
    return;
end

if isempty(regexp(name, 'Aligned$', 'once')) || has_timestamp_suffix(name)
    return;
end

timestamp = datestr(now, 'yyyymmdd_HHMMSSFFF');
filename = fullfile(filepath, sprintf('%s_%s%s', name, timestamp, ext));
end

function tf = has_timestamp_suffix(name)
tf = ~isempty(regexp(name, '_\d{8}_\d{9}$', 'once'));
end

function filename = normalize_filename(target)
if isstring(target)
    target = char(target);
end
filename = char(target);
filename = filename(:).';
end

function opt = update_saved_output_path(opt, requested_filename, resolved_filename)
if ~isstruct(opt) || ~isfield(opt, 'inter_session_alignment') || ...
        ~isfield(opt.inter_session_alignment, 'out_aligned_sessions')
    return;
end

current_filename = normalize_filename(opt.inter_session_alignment.out_aligned_sessions);
requested_filename = normalize_filename(requested_filename);

if strcmp(current_filename, requested_filename) || strcmp(current_filename, resolved_filename)
    opt.inter_session_alignment.out_aligned_sessions = resolved_filename;
end
end
