-- $Id: lualatexquotejobname.tex 22957 2011-06-13 20:49:26Z mpg $
-- Manuel Pegourie-Gonnard, originally written 2010. WTFPL v2.
--
-- Goal: see lualatexquotejobname.tex
--
-- Cache the results of previous calls, not so much for the speed gain which
-- probably doesn't matter, but to avoid repeated error messages.
local jobname_cache = {}
callback.register('process_jobname', function(jobname)
    -- use a cached version if available
    local cached = jobname_cache[jobname]
    if cached ~= nil then return cached end
    -- remove the quotes in jobname
    local clean, n_quotes = jobname:gsub([["]], [[]])
    -- complain if they wasn't an even number of quotes (aka unbalanced)
    if n_quotes % 2 ~= 0 then
        texio.write_nl('! Unbalanced quotes in jobname: ' .. jobname )
    end
    -- add quotes around the cleaned up jobname if necessary
    if jobname:find(' ') then
        clean = '"' .. clean .. '"'
    end
    -- remember the result before returning
    jobname_cache[jobname] = clean
    return clean
end)
