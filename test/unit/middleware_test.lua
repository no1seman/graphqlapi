local t = require('luatest')
local g = t.group('middleware')

require('test.helper')
local middleware = require('graphqlapi.middleware')

g.test_render_response = function()
    local req = {}
    local res = middleware.render_response(req)
    t.assert_items_equals(req, res)
end

g.test_authorize_request = function()
    local res = middleware.authorize_request({})
    t.assert_equals(res, true)
end
