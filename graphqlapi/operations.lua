local checks = require('checks')
local ddl = require('ddl')

local types = require('graphqlapi.types')
local funcall = require('graphqlapi.funcall')
local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.operations')

vars:new('queries', {})
vars:new('mutations', {})
vars:new('on_resolve_triggers', {})
vars:new('schema_invalid', nil)
vars:new('space_query', {})
vars:new('space_mutation', {})

local function is_invalid()
    return vars.schema_invalid
end

local function reset_invalid()
    vars.schema_invalid = false
end

local function is_space_exists(space)
    local ddl_schema = ddl.get_schema()
    return ddl_schema.spaces[space] or false
end

local function funcall_wrap(fun_name, operation, field_name)
    checks('string', 'string', 'string')
    return function(...)
        for trigger, _ in pairs(vars.on_resolve_triggers) do
            local ok, err = trigger(operation, field_name)
            if ok == false then return nil, err end
        end

        local res, err = funcall.call(fun_name, ...)

        if res == nil and err ~= nil then
            error(err, 0)
        end

        return res, err
    end
end

local function add_query_prefix(prefix, doc)
    checks("string", "?string")

    local kind = types.object{
        name = 'Api'..prefix,
        fields = {},
        description = doc,
    }
    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = doc,
    }
    vars.queries[prefix] = obj
    vars.schema_invalid = true
    return obj
end

local function remove_query_prefix(prefix)
    checks('string')
    if vars.queries ~= nil and type(vars.queries) == 'table' then
        vars.queries[prefix] = nil
        vars.schema_invalid = true
    end
end

local function add_mutation_prefix(prefix, doc)
    checks("string", "?string")

    local kind = types.object({
        name = 'MutationApi'..prefix,
        fields = {},
        description = doc,
    })
    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = doc,
    }
    vars.mutations[prefix] = obj
    vars.schema_invalid = true
    return obj
end

local function remove_mutation_prefix(prefix)
    checks('string')
    if vars.mutations then
        vars.mutations[prefix] = nil
        vars.schema_invalid = true
    end
end

local function add_query(opts)
    checks({
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table|string',
        callback = 'string',
    })

    if opts.prefix then
        local obj = vars.queries[opts.prefix]
        if obj == nil then
            error('No such callback prefix ' .. opts.prefix, 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(opts.callback,
                'query', opts.prefix .. '.' .. opts.name
            ),
            description = opts.doc,
        }

        obj.kind = types.object{
            name = oldkind.name,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        vars.queries[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(opts.callback,
                'query', opts.name
            ),
            description = opts.doc,
        }
    end
    vars.schema_invalid = true
end

local function remove_query(name, prefix)
    checks('string', '?string')
    if prefix == nil then
        vars.queries[name] = nil
    else
        vars.queries[prefix].kind.fields[name] = nil
    end
    vars.schema_invalid = true
end

local function is_query_prefix(query)
    if query and
       type(query) == 'table' and
       query.kind and
       type(query.kind) == 'table' and
       query.kind.__type == 'Object' and
       query.kind.name:sub(1, 3) == 'Api' and
       query.kind.fields and
       type(query.kind.fields) == 'table' then
        return true
    else
        return false
    end
end

local function list_queries()
    local queries = {}
    for query in pairs(vars.queries) do
        if is_query_prefix(vars.queries[query]) then
            for prefixed_query in pairs(vars.queries[query].kind.fields) do
                table.insert(queries, tostring(query)..'.'..tostring(prefixed_query))
            end
        else
            table.insert(queries, query)
        end
    end
    return queries
end

local function add_mutation(opts)
    checks({
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table|string',
        callback = 'string',
    })

    if opts.prefix then
        local obj = vars.mutations[opts.prefix]
        if obj == nil then
            error('No such mutation prefix ' .. opts.prefix, 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(opts.callback,
                'mutation', opts.prefix .. '.' .. opts.name
            ),
            description = opts.doc
        }

        obj.kind = types.object{
            name = oldkind.name,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        vars.mutations[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(opts.callback,
                'mutation', opts.name
            ),
            description = opts.doc,
        }
    end
    vars.schema_invalid = true
end

local function remove_mutation(name, prefix)
    checks('string', '?string')
    if prefix == nil then
        vars.mutations[name] = nil
    else
        vars.mutations[prefix].kind.fields[name] = nil
    end
    vars.schema_invalid = true
end

local function add_space_query(opts)
    checks({
        type_name = '?string',
        description = '?string',
        space = 'string',
        fields = '?table',
        prefix = '?string',
        query_name = '?string',
        doc = '?string',
        args = '?table',
        callback = 'string',
    })

    if not is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space))
    end

    local space_query_type = types.add_space_object({
        name = opts.type_name or opts.space,
        description = opts.description,
        space = opts.space,
        fields = opts.fields
    })

    add_query({
        prefix = opts.prefix,
        name = opts.query_name or opts.space,
        doc = opts.doc,
        args = opts.args,
        kind = types.list(space_query_type),
        callback = opts.callback,
    })

    local query_name
    if opts.prefix and opts.prefix ~= '' then
        query_name = opts.prefix..'.' .. (opts.query_name or opts.space)
    else
        query_name = (opts.query_name or opts.space)
    end
    vars.space_query[opts.space] = utils.merge_arrays(vars.space_query[opts.space] or {}, {query_name})
end

local function add_space_mutation(opts)
    checks({
        type_name = '?string',
        description = '?string',
        space = 'string',
        fields = '?table',
        prefix = '?string',
        mutation_name = '?string',
        doc = '?string',
        args = '?table',
        callback = 'string',
    })

    if not is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space))
    end

    local space_mutation_type = types.add_space_input_object({
        name = opts.type_name or opts.space,
        description = opts.description,
        space = opts.space,
        fields = opts.fields
    })

    add_mutation({
        prefix = opts.prefix,
        name = opts.mutation_name or opts.space,
        doc = opts.doc,
        args = opts.args,
        kind = types.list(space_mutation_type),
        callback = opts.callback,
    })

    local mutation_name
    if opts.prefix and opts.prefix ~= '' then
        mutation_name = opts.prefix..'.' .. (opts.mutation_name or opts.space)
    else
        mutation_name = (opts.mutation_name or opts.space)
    end
    vars.space_mutation[opts.space] = utils.merge_arrays(vars.space_mutation[opts.space] or {}, {mutation_name})
end

local function is_mutation_prefix(mutation)
    if mutation and
       type(mutation) and
       mutation.kind and
       type(mutation.kind) == 'table' and
       mutation.kind.__type == 'Object' and
       mutation.kind.name:sub(1, 11) == 'MutationApi' and
       mutation.kind.fields and
       type (mutation.kind.fields) then
        return true
    else
        return false
    end
end

local function list_mutations()
    local mutations = {}
    for mutation in pairs(vars.mutations) do
        if is_mutation_prefix(vars.mutations[mutation]) then
            for prefixed_mutation in pairs(vars.mutations[mutation].kind.fields) do
                table.insert(mutations, tostring(mutation)..'.'..tostring(prefixed_mutation))
            end
        else
            table.insert(mutations, mutation)
        end
    end
    return mutations
end

local function stop()
    vars.queries = nil
    vars.mutations = nil
    vars.space_query = nil
    vars.space_mutation = nil
    vars.on_resolve_triggers = nil
    vars.schema_invalid = nil
end

local function remove_all()
    vars.queries = nil
    vars.mutations = nil
    vars.space_query = nil
    vars.space_mutation = nil
    vars.schema_invalid = true
end

local function remove_operations_by_space_name(space_name)
    -- Cleanup queries related to space
    local query_list = vars.space_query[space_name]
    if query_list and type(query_list) == 'table' then
        for _, query_name in pairs(query_list) do
            local parts = query_name:split('.')
            if #parts == 2 then
                remove_query(parts[2], parts[1])
            else
                remove_query(query_name)
            end
        end
        vars.space_query[space_name] = nil
    end

    -- Cleanup mutations related to space
    local mutation_list = vars.space_mutation[space_name]
    if mutation_list and type(mutation_list) == 'table' then
        for _, mutation_name in pairs(mutation_list) do
            local parts = mutation_name:split('.')
            if #parts == 2 then
                remove_mutation(parts[2], parts[1])
            else
                remove_mutation(mutation_name)
            end
        end
        vars.space_mutation[space_name] = nil
    end
end

local function on_resolve(trigger_new, trigger_old)
    checks('?function', '?function')
    if trigger_old ~= nil then
        vars.on_resolve_triggers[trigger_old] = nil
    end
    if trigger_new ~= nil then
        vars.on_resolve_triggers[trigger_new] = true
    end
    return trigger_new
end

local function get_queries()
    return vars.queries
end

local function get_mutations()
    return vars.mutations
end

return {
    stop = stop,
    remove_all = remove_all,
    get_queries = get_queries,
    get_mutations = get_mutations,

    -- Queries prefixes
    add_query_prefix = add_query_prefix,
    remove_query_prefix = remove_query_prefix,

    -- Mutations prefixes
    add_mutation_prefix = add_mutation_prefix,
    remove_mutation_prefix = remove_mutation_prefix,

    -- Callbacks
    add_query = add_query,
    remove_query = remove_query,
    list_queries = list_queries,

    -- Mutations
    add_mutation = add_mutation,
    remove_mutation = remove_mutation,
    list_mutations = list_mutations,

    -- Spaces
    add_space_query = add_space_query,
    add_space_mutation = add_space_mutation,
    remove_operations_by_space_name = remove_operations_by_space_name,

    -- Schema invalidation flag
    is_invalid = is_invalid,
    reset_invalid = reset_invalid,

    -- Resolve trigger
    on_resolve = on_resolve,
}
