local function diff(t1, t2, ret)
    for k in pairs(t2) do
        if not t1[k] then
            table.insert(ret, k)
        end
    end
end

local function merge(...)
    local ret = {}

    for i = 1, select('#', ...) do
        local tbl = select(i, ...)
        assert(type(tbl) == 'table')
        for k, v in pairs(tbl) do
            ret[k] = v
        end
    end

    return ret
end

return {
    diff = diff,
    merge = merge,
}