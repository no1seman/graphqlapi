local checks = require('checks')

local types = require('graphqlapi.types')
local funcall = require('graphqlapi.funcall')
local vars = require('graphqlapi.vars').new('graphqlapi.operations')

vars:new('queries', {})
vars:new('mutations', {})
vars:new('on_resolve_triggers', {})
vars:new('schema_invalid', nil)

local function is_invalid()
    return vars.schema_invalid
end

local function reset_invalid()
    vars.schema_invalid = false
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

local function list_queries()
    local queries = {}
    for query in pairs(vars.queries) do
        if vars.queries[query].kind and type(vars.queries[query].kind) == 'table' and
            vars.queries[query].kind.__type == 'Object' and
            vars.queries[query].kind.name:sub(1, 3) == 'Api' then
            if vars.queries[query].kind.fields then
                for prefixed_query in pairs(vars.queries[query].kind.fields) do
                    table.insert(queries, tostring(query)..'.'..tostring(prefixed_query))
                end
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

local function list_mutations()
    local mutations = {}
    for mutation in pairs(vars.mutations) do
        if vars.mutations[mutation].kind and type(vars.mutations[mutation].kind) == 'table' and
            vars.mutations[mutation].kind.__type == 'Object' and
            vars.mutations[mutation].kind.name:sub(1, 11) == 'MutationApi' then
            if vars.mutations[mutation].kind.fields then
                for prefixed_mutation in pairs(vars.mutations[mutation].kind.fields) do
                    table.insert(mutations, tostring(mutation)..'.'..tostring(prefixed_mutation))
                end
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
    vars.on_resolve_triggers = nil
    vars.schema_invalid = nil
end

local function remove_all()
    vars.queries = nil
    vars.mutations = nil
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

    -- Schema invalidation flag
    is_invalid = is_invalid,
    reset_invalid = reset_invalid,

    -- Resolve trigger
    on_resolve = on_resolve,
}
