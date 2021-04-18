local t = require('luatest')
local g = t.group('graphqlapi')

local helper = require('test.helper.unit')

local HOST = '0.0.0.0'
local PORT = 8000
local ENDPOINT = '/graphql'

local http = require('http.server')
local httpd = http.new(HOST, PORT,{ log_requests = false })
local graphqlapi = require('graphqlapi')

g.test_init_stop = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_endpoint(), 'admin/graphql')
    graphqlapi.stop()
end

g.test_set_get_models_dir = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    graphqlapi.set_models_dir(helper.shared.root..'/test/models/suite1')
    t.assert_equals(graphqlapi.get_models_dir(), helper.shared.root..'/test/models/suite1')
    graphqlapi.stop()
end

g.test_set_get_endpoint = function()
    package.path = helper.shared.root.. '/test/models/suite1/?.lua;' .. package.path
    graphqlapi.init(httpd, nil, nil, helper.shared.root..'/test/models/suite1')
    graphqlapi.set_endpoint(ENDPOINT)
    t.assert_equals(graphqlapi.get_endpoint(), 'graphql')
    graphqlapi.set_endpoint(ENDPOINT..'/')
    t.assert_equals(graphqlapi.get_endpoint(), 'graphql')
    graphqlapi.stop()
end

g.test_reload = function()
    --
end

