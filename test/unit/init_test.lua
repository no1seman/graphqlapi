local t = require('luatest')
local g = t.group('graphqlapi')
local fiber = require('fiber')
local json = require('json')

local helper = require('test.helper.unit')

local HOST = 'localhost'
local PORT = 15999
local ENDPOINT = '/graphql'
local url = 'http://'..HOST..':'..tostring(PORT)..'/admin/graphql'

local errors = require('errors')
local http = require('http.server')
local http_client = require('http.client').new()
local graphqlapi = require('graphqlapi')
local helpers = require('graphqlapi.helpers')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')

g.test_init_stop = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), '../../test/models/suite1')
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')

    graphqlapi.stop()
    httpd:stop()
end

g.test_set_get_models_dir = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')
    graphqlapi.set_models_dir('../../test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), '../../test/models/suite1')
    graphqlapi.stop()
    httpd:stop()
end

g.test_set_get_endpoint = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')
    graphqlapi.set_endpoint(ENDPOINT)
    t.assert_equals(graphqlapi.get_endpoint(), 'graphql')
    graphqlapi.set_endpoint(ENDPOINT..'/')
    t.assert_equals(graphqlapi.get_endpoint(), 'graphql')
    graphqlapi.stop()
    httpd:stop()
end

g.test_reload = function()
    --
end

g.test_custom_auth_middleware = function()
    local custom_middleware = {
        authorize_request = function(req) -- luacheck: no unused args
            return false
        end,
        render_response = function(resp)
            return resp
        end
    }
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, custom_middleware, nil, '../../test/models/suite1')
    helpers.init()
    local space = helper.create_space()
    fiber.sleep(10)

    local query = [[
        {
            "query":"
                query {
                    space_info(name: []) {
                        name
                    }
                }",
            "variables":null
        }
    ]]

    local response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Unauthorized\"}]}")
    t.assert_equals(response.status, 401)

    graphqlapi.stop()
    httpd:stop()
    space:drop()
end

g.test_invalid_requests = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')

    local query = ''
    local response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Expected a non-empty request body\"}]}")
    t.assert_equals(response.status, 400)

    query = '""'
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Body should be a valid JSON\"}]}")
    t.assert_equals(response.status, 400)

    query = '{"field":{}}'
    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"Body should have 'query' field\"}]}")
    t.assert_equals(response.status, 400)

    query = [[
        {
            "operationName": true,
            "query":"query MyQuery {space_info(name: [qqqq]) {name}}",
            "variables":null
        }
    ]]

    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"'operationName' should be string\"}]}")
    t.assert_equals(response.status, 400)

    query = [[
        {
            "query":"query {space_info(name: [qqqq]) {name}}",
            "variables":"variable"
        }
    ]]

    response = http_client:post(url, query)
    t.assert_equals(response.body, "{\"errors\":[{\"message\":\"'variables' should be a dictionary\"}]}")
    t.assert_equals(response.status, 400)

    query = [[
        {
            "operationName": "MyQuery",
            "query":"query MyQuery {space_info(name:) {name}}",
            "variables":null
        }
    ]]

    response = http_client:post(url, query)
    t.assert_equals(
        response.body,
        "{\"errors\":[{\"message\":\"1.32: syntax error, unexpected )\"}]}"
    )
    t.assert_equals(response.status, 400)

    query = [[
        {
            "query":"query($space: [SpaceInfoNames]!){ space_info(name: $space) { name } }",
            "variables":{"space":["entity"]}
        }
    ]]

    helpers.init()
    local space = helper.create_space()
    fiber.sleep(10)

    response = http_client:post(url, query)
    t.assert_str_contains(response.body, 'attempt to call field \'routeall\' (a nil value)')
    t.assert_equals(response.status, 200)

    --helpers.stop()
    graphqlapi.stop()
    httpd:stop()
    space:drop()
end

g.test_execute_graphql = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')
    helpers.init()
    local space = helper.create_space()
    fiber.sleep(10)

    local query = [[
        {
            "query":"
                query {
                    space_info(name: []) {
                        name
                    }
                }",
            "variables":null
        }
    ]]

    local response = http_client:post(url, query)
    t.assert_str_contains(response.body, 'attempt to call field \'routeall\' (a nil value)')
    t.assert_equals(response.status, 200)

    graphqlapi.stop()
    httpd:stop()
    space:drop()
end

g.test_execute_graphql_data_and_or_errors = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, '../../test/models/suite1')

    -- test return data without errors
    do
        operations.add_query({
            name = 'test_data',
            doc = 'Get test_data',

            kind = types.object(
            {
                name = 'some_data1',
                fields = {
                    some_data1 = types.string
                }
            }),
            callback = 'test.unit.init_test.stub_data'
        })

        local query = [[
            {
                "query":"{ test_data {some_data1}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_items_equals(json.decode(response.body), { data = { test_data = {some_data1 = 'some_data1'} }})
        t.assert_equals(response.status, 200)
    end

    -- test return data and errors
    do
        operations.add_query({
            name = 'test_and_errors',
            doc = 'Get test_and_errors',

            kind = types.object(
            {
                name = 'some_data2',
                fields = {
                    some_data2 = types.string
                }
            }),
            callback = 'test.unit.init_test.stub_data_errors'
        })

        local query = [[
            {
                "query":"{ test_and_errors {some_data2}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, "Some error #1")
        t.assert_equals(json.decode(response.body).errors[2].message, "Some error #2")
        t.assert_equals(json.decode(response.body).errors[3].message, "Some error #3")
        t.assert_items_equals(json.decode(response.body).data, { test_and_errors = {some_data2 = 'some_data2'} })
        t.assert_equals(response.status, 200)
    end

    -- test return only simple string error
    do
        operations.add_query({
            name = 'test_errors_string',
            doc = 'Get test_errors_string',

            kind = types.object(
            {
                name = 'some_data3',
                fields = {
                    some_data3 = types.string
                }
            }),
            callback = 'test.unit.init_test.stub_error_string'
        })

        local query = [[
            {
                "query":"{ test_errors_string {some_data3}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)

        t.assert_equals(json.decode(response.body).errors[1].message, 'Simple string error')
        t.assert_equals(response.status, 200)
    end

    -- test return only simple error
    do
        operations.add_query({
            name = 'test_errors_error',
            doc = 'Get test_errors_error',

            kind = types.object(
            {
                name = 'some_data4',
                fields = {
                    some_data4 = types.string
                }
            }),
            callback = 'test.unit.init_test.stub_error_error'
        })

        local query = [[
            {
                "query":"{ test_errors_error {some_data4}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, 'Simple error()')
        t.assert_equals(response.status, 200)
    end

    -- test return only array of errors
    do
        operations.add_query({
            name = 'test_errors_array',
            doc = 'Get test_errors_error',

            kind = types.object(
            {
                name = 'some_data5',
                fields = {
                    some_data5 = types.string
                }
            }),
            callback = 'test.unit.init_test.stub_errors_array'
        })

        local query = [[
            {
                "query":"{ test_errors_array {some_data5}}",
                "variables":null
            }
        ]]

        local response = http_client:post(url, query)
        t.assert_equals(json.decode(response.body).errors[1].message, "Some error #1")
        t.assert_equals(json.decode(response.body).errors[2].message, "Some error #2")
        t.assert_equals(json.decode(response.body).errors[3].message, "Some error #3")
        t.assert_equals(response.status, 200)
    end

    graphqlapi.stop()
    httpd:stop()
end

local function stub_data()
    return {some_data1 = 'some_data1'}
end

local function stub_data_errors()
    local request_error = errors.new_class('GraphQL request error')
    local err = {}
    for i = 1, 3, 1 do
        local _err = request_error:new('Some error #'..tostring(i))
        table.insert(err, _err)
    end
    return {some_data2 = 'some_data2'}, err
end

local function stub_error_string()
    return nil, 'Simple string error'
end

local function stub_error_error()
    error('Simple error()', 0)
end

local function stub_errors_array()
    local request_error = errors.new_class('GraphQL request error')
    local err = {}
    for i = 1, 3, 1 do
        local _err = request_error:new('Some error #'..tostring(i))
        table.insert(err, _err)
    end
    return nil, err
end

return {
    stub_data = stub_data,
    stub_data_errors = stub_data_errors,
    stub_error_string = stub_error_string,
    stub_error_error = stub_error_error,
    stub_errors_array = stub_errors_array,
}
