local log = require('log')
local json = require('json')
local checks = require('checks')
local errors = require('errors')

local parse = require('graphql.parse')
local schema = require('graphql.schema')
local execute = require('graphql.execute')
local validate = require('graphql.validate')

for _, module in ipairs({
    'graphqlapi.funcall',
    'graphqlapi.models',
    'graphqlapi.spaces',
    'graphqlapi.types',
    'graphqlapi.vars',
}) do
    package.loaded[module] = nil
end

local funcall = require('graphqlapi.funcall')
local vars = require('graphqlapi.vars').new('graphqlapi.graphql')
local types = require('graphqlapi.types')
local spaces = require('graphqlapi.spaces')
local models = require('graphqlapi.models')

local auth_middleware = nil

vars:new('graphql_schema', nil)
vars:new('model', {})
vars:new('on_resolve_triggers', {})
vars:new('callbacks', {})
vars:new('mutations', {})
vars:new('dir_name', nil)

local e_graphql_internal = errors.new_class('GraphQL internal error')
local e_graphql_parse = errors.new_class('GraphQL parsing failed')
local e_graphql_validate = errors.new_class('GraphQL validation failed')
local e_graphql_execute = errors.new_class('GraphQL execution failed')

local function set_model(model_entrypoints)
    vars.model = model_entrypoints
end

local function funcall_wrap(fun_name, operation, field_name)
    checks('string', 'string', 'string')
    return function(...)
        for trigger, _ in pairs(vars.on_resolve_triggers) do
            local ok, err = trigger(operation, field_name)
            if not ok then return nil, err end
        end

        local res, err = funcall.call(fun_name, ...)

        if err ~= nil then
            error(err, 0)
        end

        return res
    end
end

local function add_callback_prefix(prefix, doc)
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
    vars.callbacks[prefix] = obj
    vars.graphql_schema = nil
    return obj
end

local function remove_callback_prefix(prefix)
    checks('string')
    vars.callbacks[prefix] = nil
    vars.graphql_schema = nil
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
    vars.graphql_schema = nil
    return obj
end

local function remove_mutation_prefix(prefix)
    checks('string')
    vars.mutation[prefix] = nil
    vars.graphql_schema = nil
end

local function add_callback(opts)
    checks({
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table',
        callback = 'string',
    })

    if opts.prefix then
        local obj = vars.callbacks[opts.prefix]
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
        vars.callbacks[opts.name] = {
            kind = opts.kind,
            arguments = opts.args,
            resolve = funcall_wrap(opts.callback,
                'query', opts.name
            ),
            description = opts.doc,
        }
    end
    vars.graphql_schema = nil
end

local function remove_callback(name)
    checks('string')
    vars.callbacks[name] = nil
    vars.graphql_schema = nil
end

local function list_callbacks()
    local _callbacks = {}
    for _callback in pairs(vars.callbacks) do
        table.insert(_callbacks, _callback)
    end
    return _callbacks
end

local function add_mutation(opts)
    checks({
        prefix = '?string',
        name = 'string',
        doc = '?string',
        args = '?table',
        kind = 'table',
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
    vars.graphql_schema = nil
end

local function remove_mutation(name)
    checks('string')
    vars.mutations[name] = nil
    vars.graphql_schema = nil
end

local function list_mutations()
    local _mutations = {}
    for _mutation in pairs(vars.mutations) do
        table.insert(_mutations, _mutation)
    end
    return _mutations
end

local function get_schema()
    if types.is_invalid then
        vars.graphql_schema = nil
    end
    if vars.graphql_schema ~= nil then
        return vars.graphql_schema
    end

    local fields = {}

    for name, fun in pairs(vars.callbacks) do
        fields[name] = fun
    end

    for name, entry in pairs(vars.model) do
        local original_resolve = entry.resolve
        entry.resolve = function(...)
            if original_resolve then
                return original_resolve(...)
            end
            return true
        end
        fields[name] = entry
    end

    local mutations = {}
    for name, fun in pairs(vars.mutations) do
        mutations[name] = fun
    end

    local root = {query = types.object {name = 'Query', fields=fields}}

    if next(mutations) then
        root.mutation = types.object {name = 'Mutation', fields=mutations}
    end

    vars.graphql_schema = schema.create(root)
    return vars.graphql_schema
end

local function http_finalize(obj)
    checks('table')
    return auth_middleware.render_response({
        status = 200,
        headers = {['content-type'] = "application/json; charset=utf-8"},
        body = json.encode(obj),
    })
end

local function _execute_graphql(req)
    if not auth_middleware.authorize_request(req) then
        return http_finalize({
            errors = {{message = "Unauthorized"}},
        })
    end

    local body = req:read_cached()

    if body == nil or body == '' then
        return http_finalize({
            errors = {{message = "Expected a non-empty request body"}},
        })
    end

    local parsed = json.decode(body)
    if parsed == nil then
        return http_finalize({
            errors = {{message = "Body should be a valid JSON"}},
        })
    end

    if parsed.query == nil or type(parsed.query) ~= "string" then
        return http_finalize({
            errors = {{message = "Body should have 'query' field"}},
        })
    end


    if parsed.operationName ~= nil and type(parsed.operationName) ~= "string" then
        return http_finalize({
            errors = {{message = "'operationName' should be string"}},
        })
    end

    if parsed.variables ~= nil and type(parsed.variables) ~= "table" then
        return http_finalize({
            errors = {{message = "'variables' should be a dictionary"}},
        })
    end

    local operationName = nil

    if parsed.operationName ~= nil then
        operationName = parsed.operationName
    end

    local variables = nil
    if parsed.variables ~= nil then
        variables = parsed.variables
    end
    local query = parsed.query

    local ast, err = e_graphql_parse:pcall(parse.parse, query)

    if not ast then
        log.error('%s', err)
        return http_finalize({
            errors = {{message = err.err}},
        })
    end

    local schema_obj = get_schema()
    local _, err = e_graphql_validate:pcall(validate.validate, schema_obj, ast)

    if err then
        log.error('%s', err)
        return http_finalize({
            errors = {{message = err.err}},
        })
    end

    local rootValue = {}

    local data, err = e_graphql_execute:pcall(execute.execute,
        schema_obj, ast, rootValue, variables, operationName
    )

    if data == nil then
        if not errors.is_error_object(err) then
            err = e_graphql_execute:new(err or "Unknown error")
        end

        if type(err.err) ~= 'string' then
            err.err = json.encode(err.err)
        end

        log.error('%s', err)

        local extensions = err.graphql_extensions or {}
        extensions['io.tarantool.errors.class_name'] = err.class_name
        extensions['io.tarantool.errors.stack'] = err.stack

        -- Specification: https://spec.graphql.org/June2018/#sec-Errors
        return http_finalize({
            errors = {{
                message = err.err,
                extensions = extensions,
            }}
        })
    end

    return http_finalize({
        data = data,
    })

end

local function execute_graphql(req)
    local resp, err = e_graphql_internal:pcall(_execute_graphql, req)
    if resp == nil then
        log.error('%s', err)
        return {
            status = 500,
            body = tostring(err),
        }
    end

    return resp
end

local function init(httpd, middleware, endpoint, dir_name)
    checks('table', 'table', 'string', '?string')
    log.info(type(httpd))
    assert(middleware.render_response and middleware.render_response ~= nil,
    'http middleware render_response() function must be provided')
    assert(middleware.authorize_request and middleware.authorize_request ~= nil,
    'http middleware authorize_request() function must be provided')

    auth_middleware = middleware
    vars.dir_name = dir_name or 'models'
    models.init(vars.dir_name)
    spaces.init()
    httpd:route(
        {
            method = 'POST',
            path = endpoint,
            public = true,
        },
        execute_graphql
    )
end

local function stop(httpd, endpoint)
    httpd.routes[endpoint] = nil
    httpd.iroutes[endpoint] = nil
    spaces.stop()
    models.remove_all()
    vars.graphql_schema = nil
    vars.model = nil
    vars.on_resolve_triggers = nil
    vars.callbacks = nil
    vars.mutations = nil
end

local function reload()
    vars.graphql_schema = nil
    vars.model = nil
    vars.callbacks = nil
    vars.mutations = nil
    types.remove_all()
    models.remove_all()
    models.init(vars.dir_name)
    spaces.init()
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

return {
    init = init,
    stop = stop,
    reload = reload,
    set_model = set_model,
    types = types,

    -- Callbacks prefixes
    add_callback_prefix = add_callback_prefix,
    remove_callback_prefix = remove_callback_prefix,

    -- Mutations prefixes
    add_mutation_prefix = add_mutation_prefix,
    remove_mutation_prefix = remove_mutation_prefix,

    -- Callbacks
    add_callback = add_callback,
    remove_callback = remove_callback,
    list_callbacks = list_callbacks,

    -- Mutations
    add_mutation = add_mutation,
    remove_mutation = remove_mutation,
    list_mutations = list_mutations,

    -- Execute GraphQL
    execute_graphql = execute_graphql,

    -- Resolve trigger
    on_resolve = on_resolve,
}
