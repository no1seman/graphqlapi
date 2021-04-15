local function value_in(val, arr)
    if not arr or arr == {} then return false end
    for i, elem in ipairs(arr) do
        if val == elem then
            return true, i
        end
    end
    return false
end

local function diff(t1, t2, ret)
    for k in pairs(t2) do
        if not t1[k] and not value_in(k, ret) then
            table.insert(ret, k)
        end
    end
    return ret
end

local function merge_maps(...)
    local ret = {}

    for i = 1, select('#', ...) do
        local tbl = select(i, ...)
        assert(type(tbl) == 'table')
        for k, v in pairs(tbl) do
            if v == box.NULL then
                ret[k] = nil
            else
                ret[k] = v
            end
        end
    end

    return ret
end

local function merge_arrays(a1, a2)
    local a = table.copy(a1)
    for _, value in ipairs(a2) do
        if not value_in(value, a) then
            table.insert(a, value)
        end
    end
    return a
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
    merge_maps = merge_maps,
    merge_arrays = merge_arrays,
    value_in = value_in,
    is_string_array = is_string_array,
}
