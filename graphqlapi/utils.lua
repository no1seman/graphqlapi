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

local function value_in(val, arr)
    for i, elem in ipairs(arr) do
        if val == elem then
            return true, i
        end
    end
    return false
end

local function is_string_array(data)
    if type(data) ~= 'table' then
        return false
    end
    if #data == 0 then return true end
    for _, v in pairs(data) do
        if type(v) ~= 'string' then
            return false
        end
    end
    return #data > 0 and next(data, #data) == nil
end

return {
    diff = diff,
    merge = merge,
    value_in = value_in,
    is_string_array = is_string_array,
}
