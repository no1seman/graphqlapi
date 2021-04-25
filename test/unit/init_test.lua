local t = require('luatest')
local g = t.group('graphqlapi')
local fiber = require('fiber')

local helper = require('test.helper.unit')

local HOST = '0.0.0.0'
local PORT = 8000
local ENDPOINT = '/graphql'
local url = 'http://'..HOST..':'..tostring(PORT)..'/admin/graphql'

local http = require('http.server')
local http_client = require('http.client').new()
local graphqlapi = require('graphqlapi')
local helpers = require('graphqlapi.helpers')
local types = require('graphqlapi.types')

g.test_init_stop = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')

    graphqlapi.stop()
    httpd:stop()
end

g.test_set_get_models_dir = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    graphqlapi.set_models_dir(helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), helper.shared.root..'/test/models/suite1')
    graphqlapi.stop()
    httpd:stop()
end

g.test_set_get_endpoint = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
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
    graphqlapi.init(httpd, custom_middleware, nil, helper.shared.root..'/test/models/suite1')
    helpers.init()
    local space = helper.create_space()
    while not types['SpaceInfoNames'].values['entity']  do
        fiber.yield()
    end
    fiber.yield()
    fiber.yield()
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
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')

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
    while not types['SpaceInfoNames'].values['entity']  do
        fiber.yield()
    end

    response = http_client:post(url, query)
    t.assert_str_contains(response.body, 'attempt to call field \'routeall\' (a nil value)')
    t.assert_equals(response.status, 500)

    helpers.stop()
    graphqlapi.stop()
    httpd:stop()
    space:drop()
end

g.test_execute_graphql = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    local httpd = http.new(HOST, PORT,{ log_requests = false })
    httpd:start()
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    helpers.init()
    local space = helper.create_space()
    while not types['SpaceInfoNames'].values['entity']  do
        fiber.yield()
    end

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
    t.assert_equals(response.status, 500)

    graphqlapi.stop()
    httpd:stop()
    space:drop()
end

g.test_execute_graphql_data_and_errors = function()

end