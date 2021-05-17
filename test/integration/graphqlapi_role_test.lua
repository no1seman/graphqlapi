local fio = require('fio')
local t = require('luatest')
local g = t.group('graphqlapi_role')

local helper = require('test.helper')

g.before_all = function()
    local cluster_config = table.deepcopy(helper.cluster_config)
    g.cluster = helper.Cluster:new(cluster_config)
    g.cluster:start()
end

g.after_all = function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
    g.cluster = nil
end

g.test_role_init_stop = function()
    local router = g.cluster:server('router')
    --local response = server:http_request('post', '/admin/graphql', {json = {query = '{}'}})
    --t.assert_equals(response.json, {data = {}})
    -- t.assert_equals(server.net_box:eval('return box.cfg.memtx_dir'), server.workdir)
    t.assert_equals(router.net_box:eval('return box.cfg.memtx_dir'), router.workdir)
    local endpoint = router.net_box:eval([[
        local cartridge = require('cartridge')
        local graphqlapi = cartridge.service_get('graphqlapi')
        local endpoint = graphqlapi.get_endpoint()
        graphqlapi.stop()
        return cartridge.service_get('httpd').iroutes[endpoint]
    ]])
    t.assert_equals(endpoint, nil)
end

g.test_roles_reload = function()
    local router = g.cluster.main_server
    local hotreload = router.net_box:eval([[ return require('cartridge.hotreload').state_saved() ]])

    t.skip_if(not hotreload, 'Roles reload is not allowed')

    helper.create_test_space(g.cluster, 'entity')

    local space_info, space_info_err = router.net_box:eval(
        [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
        {'entity'}
    )

    t.assert_items_equals(space_info, helper.sample_data(0))
    t.assert_equals(space_info_err, nil)

    for _ = 1, 10 do
        router.net_box:eval([[ return require('cartridge').reload_roles() ]])
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )

        t.assert_items_equals(space_info, helper.sample_data(0))
        t.assert_equals(space_info_err, nil)
    end
end
