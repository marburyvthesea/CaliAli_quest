function sortedNames = natsortfiles(names)
% Very small natural-sort for filenames containing digits.
% Input:  cellstr of filenames (no paths)
% Output: cellstr sorted naturally

% Split into non-digit and digit runs, compare digits numerically
tokens = regexp(names, '\d+|\D+', 'match');
maxLen = max(cellfun(@numel, tokens));

% Build sortable keys
key = strings(numel(names), maxLen);
for i = 1:numel(names)
    t = tokens{i};
    for j = 1:numel(t)
        if all(isstrprop(t{j}, 'digit'))
            key(i,j) = sprintf('%020d', str2double(t{j}));  % zero-pad numbers
        else
            key(i,j) = lower(string(t{j}));
        end
    end
end

[~, idx] = sortrows(key);
sortedNames = names(idx);
end

