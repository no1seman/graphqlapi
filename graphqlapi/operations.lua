local checks = require('checks')

local cluster = require('graphqlapi.cluster')
local defaults = require('graphqlapi.defaults')
local funcall = require('graphqlapi.funcall')
local types = require('graphqlapi.types')
local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.operations')

vars:new('queries', {})
vars:new('mutations', {})
vars:new('on_resolve_triggers', {})
vars:new('schema_invalid', {})

vars:new('space_query', {})
vars:new('space_mutation', {})

local function is_invalid(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    return vars.schema_invalid[schema_name]
end

local function reset_invalid(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    vars.schema_invalid[schema_name] = false
end

local function funcall_wrap(fun_name, operation_type, operation_schema, operation_prefix, operation_name)
    checks('string', 'string', 'string|nil', 'string|nil', 'string')

    return function(...)
        for trigger, _ in pairs(vars.on_resolve_triggers) do
            local ok, err = trigger(operation_type, operation_schema, operation_prefix, operation_name, ...)
            if ok == false then return nil, err end
        end

        local res, err = funcall.call(fun_name, ...)

        if res == nil and err ~= nil then
            error(err, 0)
        end

        return res, err
    end
end

local function add_queries_prefix(opts)
    checks({
        prefix = 'string',
        schema = '?string',
        doc = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.queries[opts.schema] = vars.queries[opts.schema] or {}

    local kind = types.object{
        name = defaults.QUERY_PREFIX..opts.prefix,
        fields = {},
        description = opts.doc,
    }
    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = opts.doc,
    }
    vars.queries[opts.schema][opts.prefix] = obj
    vars.schema_invalid[opts.schema] = true
    return obj
end

local function remove_query_prefix(opts)
    checks({
        prefix = 'string',
        schema = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.queries[opts.schema] = vars.queries[opts.schema] or {}
    -- Remove all queries with removed prefix
    vars.queries[opts.schema][opts.prefix] = nil
    -- Cleanup vars.space_query with removed prefix
    for space in pairs(vars.space_query) do
        local space_queries = table.copy(vars.space_query[space])
        for index, query in pairs(space_queries or {}) do
            if query.schema == opts.schema and
                query.prefix == opts.prefix then
                table.remove(vars.space_query[space], index)
            end
        end
    end

    vars.schema_invalid[opts.schema] = true
end

local function add_mutations_prefix(opts)
    checks({
        prefix = 'string',
        schema = '?string',
        doc = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.mutations[opts.schema] = vars.mutations[opts.schema] or {}

    local kind = types.object({
        name = defaults.MUTATION_PREFIX..opts.prefix,
        fields = {},
        description = opts.doc,
    })
    local obj = {
        kind = kind,
        arguments = {},
        resolve = function()
            return {}
        end,
        description = opts.doc,
    }
    vars.mutations[opts.schema][opts.prefix] = obj
    vars.schema_invalid[opts.schema] = true
    return obj
end

local function remove_mutation_prefix(opts)
    checks({
        prefix = 'string',
        schema = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.mutations[opts.schema] = vars.mutations[opts.schema] or {}
    -- Remove all mutations with removed prefix
    vars.mutations[opts.schema][opts.prefix] = nil
    -- Cleanup vars.space_mutation with removed prefix
    for space in pairs(vars.space_mutation) do
        local space_mutations = table.copy(vars.space_mutation[space])
        for index, mutation in pairs(space_mutations or {}) do
            if mutation.schema == opts.schema and
                mutation.prefix == opts.prefix then
                table.remove(vars.space_mutation[space], index)
            end
        end
    end
    vars.schema_invalid[opts.schema] = true
end

local function add_query(opts)
    checks({
        schema = '?string',
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table|string',
        callback = 'string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.queries[opts.schema] = vars.queries[opts.schema] or {}

    if opts.prefix then
        local obj = vars.queries[opts.schema][opts.prefix]
        if obj == nil then
            error('No such query prefix "' .. opts.prefix..'"', 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'query',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }

        obj.kind = types.object{
            name = oldkind.name,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        vars.queries[opts.schema][opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'query',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }
    end
    vars.schema_invalid[opts.schema] = true
end

local function remove_query(opts)
    checks({
        name = 'string',
        schema = '?string',
        prefix = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.queries[opts.schema] = vars.queries[opts.schema] or {}

    if opts.prefix == nil then
        vars.queries[opts.schema][opts.name] = nil
    else
        if vars.queries[opts.schema][opts.prefix] and
           vars.queries[opts.schema][opts.prefix].kind and
           vars.queries[opts.schema][opts.prefix].kind.fields then
            vars.queries[opts.schema][opts.prefix].kind.fields[opts.name] = nil
        end
    end

    for space in pairs(vars.space_query) do
        local space_queries = table.copy(vars.space_query[space])
        for index, query in pairs(space_queries or {}) do
            if query.schema == opts.schema and
               query.prefix == opts.prefix and
               query.name == opts.name then
                table.remove(vars.space_query[space], index)
            end
        end
    end

    vars.schema_invalid[opts.schema] = true
end

local function is_query_prefix(query)
    if query and
       type(query) == 'table' and
       query.kind and
       type(query.kind) == 'table' and
       query.kind.__type == 'Object' and
       query.kind.name:sub(1, #defaults.QUERY_PREFIX) == defaults.QUERY_PREFIX and
       query.kind.fields and
       type(query.kind.fields) == 'table' then
        return true
    else
        return false
    end
end

local function list_queries(schema_name)
    checks('?string')

    local queries = {}

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    vars.queries[schema_name] = vars.queries[schema_name] or {}

    for query in pairs(vars.queries[schema_name]) do
        if is_query_prefix(vars.queries[schema_name][query]) then
            for prefixed_query in pairs(vars.queries[schema_name][query].kind.fields or {}) do
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
        schema = '?string',
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table|string',
        callback = 'string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.mutations[opts.schema] = vars.mutations[opts.schema] or {}

    if opts.prefix then
        local obj = vars.mutations[opts.schema][opts.prefix]
        if obj == nil then
            error('No such mutation prefix "' .. opts.prefix..'"', 0)
        end

        local oldkind = obj.kind
        oldkind.fields[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'mutation',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc
        }

        obj.kind = types.object{
            name = oldkind.name,
            fields = oldkind.fields,
            description = oldkind.description,
        }
    else
        vars.mutations[opts.schema][opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(
                opts.callback,
                'mutation',
                opts.schema,
                opts.prefix,
                opts.name
            ),
            description = opts.doc,
        }
    end
    vars.schema_invalid[opts.schema] = true
end

local function remove_mutation(opts)
    checks({
        name = 'string',
        schema = '?string',
        prefix = '?string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.mutations[opts.schema] = vars.mutations[opts.schema] or {}

    if opts.prefix == nil then
        vars.mutations[opts.schema][opts.name] = nil
    else
        if vars.mutations[opts.schema][opts.prefix] and
           vars.mutations[opts.schema][opts.prefix].kind and
           vars.mutations[opts.schema][opts.prefix].kind.fields then
            vars.mutations[opts.schema][opts.prefix].kind.fields[opts.name] = nil
        end
    end

    for space in pairs(vars.space_mutation) do
        local space_mutations = table.copy(vars.space_mutation[space])
        for index, mutation in pairs(space_mutations or {}) do
            if mutation.schema == opts.schema and
               mutation.prefix == opts.prefix and
               mutation.name == opts.name then
                table.remove(vars.space_mutation[space], index)
            end
        end
    end

    vars.schema_invalid[opts.schema] = true
end

local function add_space_query(opts)
    checks({
        schema = '?string',
        type_name = '?string',
        description = '?string',
        space = 'string',
        fields = '?table',
        prefix = '?string',
        name = '?string',
        doc = '?string',
        args = '?table',
        kind = '?boolean',
        callback = 'string',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    vars.queries[opts.schema] = vars.queries[opts.schema] or {}

    if not cluster.is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space))
    end

    local type_name = opts.type_name or opts.space

    types.add_space_object({
        schema = opts.schema,
        name = type_name,
        description = opts.description,
        space = opts.space,
        fields = opts.fields
    })

    local name = opts.name or opts.space

    add_query({
        schema = opts.schema,
        prefix = opts.prefix,
        name = name,
        doc = opts.doc,
        args = opts.args,
        kind = opts.kind or types(opts.schema)[type_name] and types.list(types(opts.schema)[type_name]),
        callback = opts.callback,
    })

    vars.space_query[opts.space] = utils.merge_arrays(
        vars.space_query[opts.space] or {},
        {
            {
                name = name,
                schema = opts.schema,
                prefix = opts.prefix,
                type_name = opts.type_name,
            }
        }
    )
end

local function remove_space_query(opts)
    checks({
        schema = '?string',
        prefix = '?string',
        space = 'string',
        name = '?string',
    })

    -- TODO: remove space related type ?

    if opts.name == nil then
        local space_queries = table.copy(vars.space_query[opts.space])
        for index, query in pairs(space_queries or {}) do
            if query.schema == nil then
                query.schema = defaults.DEFAULT_SCHEMA_NAME
            else
                query.schema = query.schema:lower()
            end

            vars.queries[query.schema] = vars.queries[query.schema] or {}

            if query.prefix == nil then
                vars.queries[query.schema][query.name] = nil
            else
                if vars.queries[query.schema][query.prefix] and
                   vars.queries[query.schema][query.prefix].kind and
                   vars.queries[query.schema][query.prefix].kind.fields then
                    vars.queries[query.schema][query.prefix].kind.fields[query.name] = nil
                end
            end
            table.remove(vars.space_query[opts.space], index)
            vars.schema_invalid[query.schema] = true
        end
    else
        if opts.schema == nil then
            opts.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            opts.schema = opts.schema:lower()
        end

        remove_query({
            name = opts.name,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
end

local function add_space_mutation(opts)
    checks({
        schema = '?string',
        type_name = '?string',
        description = '?string',
        space = 'string',
        fields = '?table',
        prefix = '?string',
        name = '?string',
        doc = '?string',
        args = '?table',
        kind = '?boolean',
        callback = 'string',
    })

    if not cluster.is_space_exists(opts.space) then
        error(string.format("space '%s' doesn't exists", opts.space))
    end

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    local type_name = opts.type_name or opts.space

    types.add_space_input_object({
        schema = opts.schema,
        name = type_name,
        description = opts.description,
        space = opts.space,
        fields = opts.fields
    })

    local name = opts.name or opts.space

    add_mutation({
        schema = opts.schema,
        prefix = opts.prefix,
        name = name,
        doc = opts.doc,
        args = opts.args,
        kind = opts.kind or types(opts.schema)[type_name] and types.list(types(opts.schema)[type_name]),
        callback = opts.callback,
    })

    vars.space_mutation[opts.space] = utils.merge_arrays(
        vars.space_mutation[opts.space] or {},
        {
            {
                name = name,
                schema = opts.schema,
                prefix = opts.prefix,
                type_name = type_name,
            }
        }
    )
end

local function remove_space_mutation(opts)
    checks({
        schema = '?string',
        prefix = '?string',
        space = 'string',
        name = '?string',
    })

    -- TODO: remove space related type ?

    if opts.name == nil then
        local space_queries = table.copy(vars.space_mutation[opts.space])
        for index, mutation in pairs(space_queries or {}) do
            if mutation.schema == nil then
                mutation.schema = defaults.DEFAULT_SCHEMA_NAME
            else
                mutation.schema = mutation.schema:lower()
            end

            vars.mutations[mutation.schema] = vars.mutations[mutation.schema] or {}

            if mutation.prefix == nil then
                vars.mutations[mutation.schema][mutation.name] = nil
            else
                if vars.mutations[mutation.schema][mutation.prefix] and
                   vars.mutations[mutation.schema][mutation.prefix].kind and
                   vars.mutations[mutation.schema][mutation.prefix].kind.fields then
                    vars.mutations[mutation.schema][mutation.prefix].kind.fields[mutation.name] = nil
                end
            end
            table.remove(vars.space_mutation[opts.space], index)
            vars.schema_invalid[mutation.schema] = true
        end
    else
        if opts.schema == nil then
            opts.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            opts.schema = opts.schema:lower()
        end

        remove_mutation({
            name = opts.name,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
end

local function is_mutation_prefix(mutation)
    if mutation and
       type(mutation) and
       mutation.kind and
       type(mutation.kind) == 'table' and
       mutation.kind.__type == 'Object' and
       mutation.kind.name:sub(1, #defaults.MUTATION_PREFIX) == defaults.MUTATION_PREFIX and
       mutation.kind and
       mutation.kind.fields and
       type (mutation.kind.fields) then
        return true
    else
        return false
    end
end

local function list_mutations(schema_name)
    checks('?string')

    local mutations = {}

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    vars.mutations[schema_name] = vars.mutations[schema_name] or {}

    for mutation in pairs(vars.mutations[schema_name]) do
        if is_mutation_prefix(vars.mutations[schema_name][mutation]) then
            for prefixed_mutation in pairs(vars.mutations[schema_name][mutation].kind.fields or {}) do
                table.insert(mutations, tostring(mutation)..'.'..tostring(prefixed_mutation))
            end
        else
            table.insert(mutations, mutation)
        end
    end
    return mutations
end

local function remove_on_resolve_triggers()
    vars.on_resolve_triggers = nil
end

local function stop()
    vars.queries = nil
    vars.mutations = nil
    vars.space_query = nil
    vars.space_mutation = nil
    remove_on_resolve_triggers()
    vars.schema_invalid = nil
end

local function remove_all(opts)
    checks({
        schema = '?string',
    })

    if opts ~= nil then
        if opts.schema == nil then
            opts.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            opts.schema = opts.schema:lower()
        end

        vars.queries[opts.schema] = nil

        for space in pairs(vars.space_query) do
            local space_queries = table.copy(vars.space_query[space])
            for index, query in pairs(space_queries or {}) do
                if query.schema == opts.schema then
                    table.remove(vars.space_query[space], index)
                end
            end
        end

        vars.mutations[opts.schema] = nil

        for space in pairs(vars.space_mutation) do
            local space_mutations = table.copy(vars.space_mutation[space])
            for index, mutation in pairs(space_mutations or {}) do
                if mutation.schema == opts.schema then
                    table.remove(vars.space_mutation[space], index)
                end
            end
        end

        vars.schema_invalid[opts.schema] = nil
    else
        vars.queries = nil
        vars.mutations = nil
        vars.space_query = nil
        vars.space_mutation = nil
        vars.schema_invalid = nil
    end
end

local function remove_operations_by_space_name(space_name)
    checks('string')

    -- Cleanup queries related to space
    for _, query in pairs(vars.space_query[space_name] or {}) do
        if query.schema == nil then
            query.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            query.schema = query.schema:lower()
        end

        vars.queries[query.schema] = vars.queries[query.schema] or {}

        if query.prefix == nil then
            vars.queries[query.schema][query.name] = nil
        else
            if vars.queries[query.schema][query.prefix] and
               vars.queries[query.schema][query.prefix].kind and
               vars.queries[query.schema][query.prefix].kind.fields then
                vars.queries[query.schema][query.prefix].kind.fields[query.name] = nil
            end
        end

        vars.schema_invalid[query.schema] = true
    end

    vars.space_query[space_name] = nil

    -- Cleanup mutations related to space
    for _, mutation in pairs(vars.space_mutation[space_name] or {}) do
        if mutation.schema == nil then
            mutation.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            mutation.schema = mutation.schema:lower()
        end

        vars.mutations[mutation.schema] = vars.mutations[mutation.schema] or {}

        if mutation.prefix == nil then
            vars.mutations[mutation.schema][mutation.name] = nil
        else
            if vars.mutations[mutation.schema] and
               vars.mutations[mutation.schema][mutation.prefix].kind and
               vars.mutations[mutation.schema][mutation.prefix].kind.fields then
                vars.mutations[mutation.schema][mutation.prefix].kind.fields[mutation.name] = nil
            end
        end

        vars.schema_invalid[mutation.schema] = true

    end
    vars.space_mutation[space_name] = nil
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

local function get_queries(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    return vars.queries[schema_name] or {}
end

local function get_mutations(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    return vars.mutations[schema_name] or {}
end

local function schemas()
    local _schemas = {}
    for schema_name in pairs(vars.schema_invalid) do
        table.insert(_schemas, schema_name)
    end
    return _schemas
end

return {
    stop = stop,
    remove_all = remove_all,
    get_queries = get_queries,
    get_mutations = get_mutations,
    schemas = schemas,

    -- Queries prefixes
    add_queries_prefix = add_queries_prefix,
    remove_query_prefix = remove_query_prefix,

    -- Mutations prefixes
    add_mutations_prefix = add_mutations_prefix,
    remove_mutation_prefix = remove_mutation_prefix,

    -- Queries
    add_query = add_query,
    remove_query = remove_query,
    list_queries = list_queries,

    -- Mutations
    add_mutation = add_mutation,
    remove_mutation = remove_mutation,
    list_mutations = list_mutations,

    -- Spaces queries and mutations
    add_space_query = add_space_query,
    remove_space_query = remove_space_query,
    add_space_mutation = add_space_mutation,
    remove_space_mutation = remove_space_mutation,
    remove_operations_by_space_name = remove_operations_by_space_name,

    -- Schema invalidation flag
    is_invalid = is_invalid,
    reset_invalid = reset_invalid,

    -- Resolve trigger
    on_resolve = on_resolve,
    remove_on_resolve_triggers = remove_on_resolve_triggers,
}
