local log = require('log')
local json = require('json')

-- local json_cfg = {
--     encode_use_tostring = true,
--     encode_deep_as_nil = true,
--     encode_max_depth = 3,
--     encode_invalid_as_nil = true,
-- }

local fio = require('fio')
local checks = require('checks')
local errors = require('errors')

local execute = require('graphql.execute')
local parse = require('graphql.parse')
local schema = require('graphql.schema')
local validate = require('graphql.validate')

local VERSION = '0.0.1-1'
local DEFAULT_DIR_NAME = 'models'
local DEFAULT_ENDPOINT = '/admin/graphql'

for _, module in ipairs({
    'graphqlapi.cluster',
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

vars:new('graphql_schema', {})
vars:new('model', {})
vars:new('models_dir', nil)
vars:new('endpoint', nil)
vars:new('auth_middleware', nil)
vars:new('httpd', nil)

local e_graphql_internal = errors.new_class('GraphQL internal error')
local e_graphql_parse = errors.new_class('GraphQL parsing failed')
local e_graphql_validate = errors.new_class('GraphQL validation failed')
local e_graphql_execute = errors.new_class('GraphQL execution failed')

local function get_schema(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = 'default'
    else
        schema_name = schema_name:lower()
    end

    if types.is_invalid(schema_name) or operations.is_invalid(schema_name) then
        vars.graphql_schema = nil
        types.reset_invalid(schema_name)
        operations.reset_invalid(schema_name)
    end

    if vars.graphql_schema[schema_name] ~= nil then
        return vars.graphql_schema[schema_name]
    end

    local queries = {}
    for name, fun in pairs(operations.get_queries(schema_name)) do
        queries[name] = fun
    end

    local mutations = {}
    for name, fun in pairs(operations.get_mutations(schema_name)) do
        mutations[name] = fun
    end

    local root = {
        query = types.object {name = 'Query', fields=queries},
    }

    if next(mutations) then
        root.mutation = types.object {name = 'Mutation', fields=mutations}
    end

    vars.graphql_schema[schema_name] = schema.create(root, schema_name)

    return vars.graphql_schema[schema_name]
end

local function http_finalize(obj, status)
    checks('table', '?number')
    return vars.auth_middleware.render_response({
        status = status or 200,
        headers = {['content-type'] = "application/json; charset=utf-8"},
        body = json.encode(obj),
    })
end

local function to_graphql_error(err)
    if type(err.err) ~= 'string' then
        err.err = json.encode(err.err)
    end

    log.error('%s', err)

    local extensions = err.graphql_extensions or {}
    extensions['io.tarantool.errors.class_name'] = err.class_name
    extensions['io.tarantool.errors.stack'] = err.stack

    return {
        message = err.err,
        extensions = extensions,
    }
end

local function _execute_graphql(req)
    if not vars.auth_middleware.authorize_request(req) then
        return http_finalize({
            errors = {{message = "Unauthorized"}},
        }, 401)
    end

    local body = req:read_cached()

    local schema_name = 'default'

    if req.headers.schema ~= nil and type(req.headers.schema) == 'string' then
        schema_name = req.headers.schema:lower()
    end

    if body == nil or body == '' then
        return http_finalize({
            errors = {{message = "Expected a non-empty request body"}},
        }, 400)
    end

    local parsed = json.decode(body)
    if parsed == nil or type(parsed) ~= 'table' then
        return http_finalize({
            errors = {{message = "Body should be a valid JSON"}},
        }, 400)
    end

    if parsed.query == nil or type(parsed.query) ~= 'string' then
        return http_finalize({
            errors = {{message = "Body should have 'query' field"}},
        }, 400)
    end

    if parsed.operationName ~= nil and type(parsed.operationName) ~= 'string' then
        return http_finalize({
            errors = {{message = "'operationName' should be string"}},
        }, 400)
    end

    if parsed.variables ~= nil and type(parsed.variables) ~= "table" then
        return http_finalize({
            errors = {{message = "'variables' should be a dictionary"}},
        }, 400)
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
        }, 400)
    end

    local schema_obj = get_schema(schema_name)

    err = select(2,e_graphql_validate:pcall(validate.validate, schema_obj, ast))

    if err then
        log.error('%s', err)
        return http_finalize({
            errors = {{message = err.err}},
        }, 400)
    end

    local rootValue = {}
    local data
    data, err = e_graphql_execute:pcall(execute.execute,
        schema_obj, ast, rootValue, variables, operationName
    )

    if err ~= nil then
        if errors.is_error_object(err) then
            err = {to_graphql_error(err)}
        elseif type(err) == 'table' then
            local _errors = {}
            for _, _err_arr in ipairs(err) do
                if errors.is_error_object(_err_arr) then
                    table.insert(_errors, to_graphql_error(_err_arr))
                else
                    for _, _err in ipairs(_err_arr) do
                        table.insert(_errors, to_graphql_error(_err))
                    end
                end
            end
            err = _errors
        end
    end

    return http_finalize({
        data = data,
        errors = err,
    }, 200)
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
    if httpd then
        local route = httpd.iroutes[name]
        if route then
            httpd.iroutes[name] = nil
            table.remove(httpd.routes, route)
        end

        for n, r in ipairs(httpd.routes) do
            if r.name then
                httpd.iroutes[r.name] = n
            end
        end
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
    opts.name = vars.endpoint
    opts.method = opts.method or 'POST'
    opts.public = opts.public or false
    vars.httpd:route(opts, execute_graphql)
end


local function get_endpoint()
    return vars.endpoint
end

local function _init()
    if fio.path.is_dir(fio.pathjoin(package.searchroot(), vars.models_dir)) then
        models.init(vars.models_dir)
        return true
    else
        vars.models_dir = nil
        local err = string.format('Path is not valid: %s', tostring(vars.models_dir))
        log.error('%s', err)
        return nil, err
    end
end

local function init(httpd, middleware, endpoint, models_dir, opts)
    checks('table', '?table', '?string', '?string', '?table')

    if not middleware or not middleware.render_response or not middleware.authorize_request then
        middleware = require('graphqlapi.middleware')
    end

    vars.auth_middleware = middleware
    endpoint = endpoint or DEFAULT_ENDPOINT
    vars.models_dir = models_dir or DEFAULT_DIR_NAME

    local ok, err = _init()
    if not ok then
        return err
    end

    vars.httpd = httpd
    set_endpoint(endpoint, opts)

    spaces.init()
end

local function stop()
    delete_route(vars.httpd, vars.endpoint)
    vars.httpd = nil
    spaces.stop()
    helpers.stop()
    models.stop()
    types.remove_all()
    vars.graphql_schema = nil
    vars.model = nil
    operations.stop()
    vars.models_dir = nil
    vars.endpoint = nil
end

local function reload()
    vars.graphql_schema = nil
    vars.model = nil
    operations.remove_all()
    helpers.stop()
    types.remove_all()
    models.stop()

    local ok, err = _init()
    if not ok then
        return nil, err
    end
    return true
end

local function set_models_dir(models_dir)
    checks('string')
    if fio.path.is_dir(fio.pathjoin(package.searchroot(), models_dir)) then
        vars.models_dir = models_dir
        reload()
    end
end

local function get_models_dir()
    return vars.models_dir
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

    -- version
    VERSION = VERSION,
}
