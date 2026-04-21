function batch_size = resolve_batch_size_fn(batch_sz, out_sz, Fds)
if isnumeric(batch_sz)
    if isinf(batch_sz) || batch_sz <= 0
        batch_size = Fds;
    else
        batch_size = min(Fds, ceil(batch_sz));
    end
    return
end

if ischar(batch_sz) || (isstring(batch_sz) && isscalar(batch_sz))
    if strcmpi(batch_sz, 'auto')
        try
            [batch_size, ~] = compute_auto_batch_size('auto', [], [out_sz(1), out_sz(2)]);
        catch
            % Fallback if compute_auto_batch_size unavailable
            batch_size = min(Fds, 30000);
        end
        batch_size = min(max(1, batch_size), Fds);
        return
    end
end

batch_size = min(Fds, 10000); % fallback default
end
