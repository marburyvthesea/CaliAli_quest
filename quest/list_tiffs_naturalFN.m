function [paths, names] = list_tiffs_naturalFN(inDir, pattern)
% list_tiffs_natural  Return full paths to TIFFs in natural-sorted order.
%
% pattern: optional wildcard like '*_converted.tif' or '*.tif'

if nargin < 2 || isempty(pattern)
    pattern = '*.tif*';  % matches .tif and .tiff
end

d = dir(fullfile(inDir, pattern));
assert(~isempty(d), 'No TIFFs found in: %s (pattern=%s)', inDir, pattern);

names = {d.name};

% Prefer natsortfiles if you have it; otherwise fallback to a simple numeric sort
if exist('natsortfiles','file') == 2
    names = natsortfiles(names);
else
    names = simple_nat_sort_by_last_number(names);
end

paths = fullfile(inDir, names);
end

function namesOut = simple_nat_sort_by_last_number(namesIn)
% crude fallback: sort by the last run of digits in the filename
nums = nan(size(namesIn));
for i = 1:numel(namesIn)
    tok = regexp(namesIn{i}, '(\d+)(?!.*\d)', 'tokens', 'once');
    if ~isempty(tok), nums(i) = str2double(tok{1}); end
end
[~, idx] = sortrows([isnan(nums(:)) nums(:)]); % NaNs last
namesOut = namesIn(idx);
end