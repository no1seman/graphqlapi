local t = require('luatest')
local g = t.group('graphqlapi_role')

local helper = require('test.helper.integration')
local cluster = helper.cluster

g.before_each = function()
    g.cluster = helper.cluster
    g.cluster:start()
end

g.after_each = function()
    g.cluster:stop()
end

g.test_role_init_stop = function()
    local server = cluster.main_server
    --local response = server:http_request('post', '/admin/graphql', {json = {query = '{}'}})
    --t.assert_equals(response.json, {data = {}})
    -- t.assert_equals(server.net_box:eval('return box.cfg.memtx_dir'), server.workdir)
    t.assert_equals(server.net_box:eval('return box.cfg.memtx_dir'), server.workdir)
    server.net_box:eval([[
        require('cartridge').service_get('graphqlapi').stop()
    ]])
end
