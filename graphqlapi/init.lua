local log = require('log')
local json = require('json')
local fio = require('fio')
local checks = require('checks')
local errors = require('errors')

local parse = require('graphql.parse')
local schema = require('graphql.schema')
local execute = require('graphql.execute')
local validate = require('graphql.validate')

local VERSION = '0.0.1-1'
local DEFAULT_DIR_NAME = 'models'
local DEFAULT_ENDPOINT = '/admin/graphql'

for _, module in ipairs({
    'graphqlapi.funcall',
    'graphqlapi.helpers',
    'graphqlapi.middleware',
    'graphqlapi.models',
    'graphqlapi.operations',
    'graphqlapi.spaceapi',
    'graphqlapi.spaces',
    'graphqlapi.types',
    'graphqlapi.utils',
    'graphqlapi.vars',
}) do
    package.loaded[module] = nil
end

local helpers = require('graphqlapi.helpers')
local models = require('graphqlapi.models')
local operations = require('graphqlapi.operations')
local spaces = require('graphqlapi.spaces')
local types = require('graphqlapi.types')
local vars = require('graphqlapi.vars').new('graphqlapi.graphql')

vars:new('graphql_schema', nil)
vars:new('model', {})
vars:new('dir_name', nil)
vars:new('endpoint', nil)
vars:new('auth_middleware', nil)
vars:new('httpd', nil)

local e_graphql_internal = errors.new_class('GraphQL internal error')
local e_graphql_parse = errors.new_class('GraphQL parsing failed')
local e_graphql_validate = errors.new_class('GraphQL validation failed')
local e_graphql_execute = errors.new_class('GraphQL execution failed')

local function set_model(model_entrypoints)
    vars.model = model_entrypoints
end

local function get_schema()
    if types.is_invalid then
        vars.graphql_schema = nil
    end
    if operations.is_invalid then
        vars.graphql_schema = nil
    end
    if vars.graphql_schema ~= nil then
        return vars.graphql_schema
    end

    local fields = {}

    for name, fun in pairs(operations.queries) do
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
    for name, fun in pairs(operations.mutations) do
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
    return vars.auth_middleware.render_response({
        status = 200,
        headers = {['content-type'] = "application/json; charset=utf-8"},
        body = json.encode(obj),
    })
end

local function _execute_graphql(req)
    if not vars.auth_middleware.authorize_request(req) then
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

local function delete_route(httpd, name)
    if httpd.routes and httpd.routes[name] then
        httpd.routes[name] = nil
    end
    if httpd.iroutes and httpd.iroutes[name] then
        httpd.iroutes[name] = nil
    end
end

local function remove_side_slashes(path)
    if path:startswith('/') then
        path = path:sub(2)
    end
    if path:endswith('/') then
        path = path:sub(1, -2)
    end
    return path
end

local function set_endpoint(endpoint, opts)
    checks('string', '?table')
    delete_route(vars.httpd, vars.endpoint)
    vars.endpoint = remove_side_slashes(endpoint)
    opts = opts or {}
    opts.path = vars.endpoint
    opts.method = opts.method or 'POST'
    opts.public = opts.public or true
    vars.httpd:route(opts, execute_graphql)
end

local function get_endpoint()
    return vars.endpoint
end

local function _init()
    if fio.path.is_dir(vars.dir_name) then
        models.init(vars.dir_name)
        spaces.init()
        return true
    else
        vars.dir_name = nil
        local err = ('Path is not valid: %s'):format(tostring(vars.dir_name))
        log.warn(err)
        return nil, err
    end
end

local function init(httpd, middleware, endpoint, dir_name, opts)
    checks('table', '?table', '?string', '?string', '?table')

    if not middleware or not middleware.render_response or not middleware.authorize_request then
        middleware = require('graphqlapi.middleware')
    end

    vars.auth_middleware = middleware
    dir_name = dir_name or DEFAULT_DIR_NAME
    endpoint = endpoint or DEFAULT_ENDPOINT
    vars.dir_name = fio.pathjoin(package.searchroot(), dir_name)

    local ok, err = _init()
    if not ok then
        return err
    end

    vars.httpd = httpd
    set_endpoint(endpoint, opts)
    
    --require('graphqlapi.printer').print_types(types)
end

local function stop()
    vars.httpd.routes[vars.endpoint] = nil
    vars.httpd.iroutes[vars.endpoint] = nil
    vars.httpd = nil
    spaces.stop()
    helpers.stop()
    models.stop()
    vars.graphql_schema = nil
    vars.model = nil
    operations.stop()
    vars.dir_name = nil
    vars.endpoint = nil
end

local function reload()
    log.info('Global schema: '..json.encode(types.get_env(), {
        encode_use_tostring = true,
        encode_deep_as_nil = true,
        encode_max_depth = 3,
        encode_invalid_as_nil = true,
    }))
    log.info('Types: ' .. json.encode(types.list_types()))
    log.info('Mutations: ' .. json.encode(operations.list_mutations()))
    log.info('Queries: ' ..json.encode(operations.list_queries()))
    log.info('Models: '..json.encode(models.list_models()))
    log.info('Loaded: '..json.encode(models.list_loaded()))
    log.info('Modules: '..json.encode(models.list_modules()))

    vars.graphql_schema = nil
    vars.model = nil
    operations.remove_all()
    helpers.stop()
    types.remove_all()
    models.stop()

    types.get_env()

    local ok, err = _init()
    if not ok then
        return err
    end

    log.info('Global schema: '..json.encode(types.get_env(), {
        encode_use_tostring = true,
        encode_deep_as_nil = true,
        encode_max_depth = 3,
        encode_invalid_as_nil = true,
    }))
    log.info('Types: ' .. json.encode(types.list_types()))
    log.info('Mutations: ' .. json.encode(operations.list_mutations()))
    log.info('Queries: ' ..json.encode(operations.list_queries()))
    log.info('Models: '..json.encode(models.list_models()))
    log.info('Loaded: '..json.encode(models.list_loaded()))
    log.info('Modules: '..json.encode(models.list_modules()))
end

local function set_models_dir(dir_name)
    if fio.path.is_dir(dir_name) then
        vars.dir_name = dir_name
        reload()
    end
end

local function get_models_dir()
    return vars.dir_name
end

return {
    -- Common methods
    init = init,
    stop = stop,
    reload = reload,
    set_models_dir = set_models_dir,
    get_models_dir = get_models_dir,
    set_endpoint = set_endpoint,
    get_endpoint = get_endpoint,

    -- Types
    set_model = set_model,
    types = types,

    -- Operations
    operations = operations,

    -- Execute GraphQL
    execute_graphql = execute_graphql,

    -- version
    VERSION = VERSION,
}
