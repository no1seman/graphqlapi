local defaults = require('graphqlapi.defaults')

local function value_in(val, arr)
    if not arr or arr == {} then return false end
    for i, elem in ipairs(arr) do
        if val == elem then
            return true, i
        end
    end
    return false
end

local function diff_maps(t1, t2, ret)
    for k in pairs(t2) do
        if not t1[k] and not value_in(k, ret) then
            table.insert(ret, k)
        end
    end
    return ret
end

local function diff_arrays(t1, t2)
    local ret = {}
    for _,space in ipairs(t1) do
        if value_in(space, t2) then
            table.insert(ret, space)
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

local function concat_arrays(...)
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
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

local function dedup_array(tbl)
    if not tbl or type(tbl) ~= 'table' then
        return {}
    end
    local kv = {}
    for i = #tbl, 1, -1 do
        local str = tbl[i]
        if not kv[str] then
            kv[str] = true
        else
            table.remove(tbl, i)
        end
    end

    return tbl
end

local function is_map(tbl)
    if type(tbl) ~= 'table' then
        return false
    end

    local key, _ = next(tbl)

    return type(key) == 'string'
end

local function coerce_schema(schema)
    if schema == nil then
        schema = defaults.DEFAULT_SCHEMA_NAME
    else
        schema = schema:lower()
    end
    return schema
end

return {
    value_in = value_in,
    diff_maps = diff_maps,
    diff_arrays = diff_arrays,
    merge_maps = merge_maps,
    merge_arrays = merge_arrays,
    concat_arrays = concat_arrays,
    is_string_array = is_string_array,
    dedup_array = dedup_array,
    is_map = is_map,
    coerce_schema = coerce_schema,
}
