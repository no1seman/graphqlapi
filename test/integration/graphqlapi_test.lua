local fio = require('fio')
local t = require('luatest')
local g = t.group('graphqlapi_role')

local entity_space = require('test.helper.entity_space')
local helper = require('test.helper.integration')

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
    router.net_box:eval([[
        require('cartridge').service_get('graphqlapi').stop()
    ]])
end

g.test_roles_reload = function()
    local router = g.cluster.main_server
    local hotreload = router.net_box:eval([[ return require('cartridge.hotreload').state_saved() ]])

    t.skip_if(not hotreload, 'Roles reload is not allowed')

    entity_space.create_test_space(g.cluster, 'entity')

    local space_info, space_info_err = router.net_box:eval(
        [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
        {'entity'}
    )

    t.assert_items_equals(space_info, entity_space.sample_data(0))
    t.assert_equals(space_info_err, nil)

    router.net_box:eval([[ return require('cartridge').reload_roles() ]])

    space_info, space_info_err = router.net_box:eval(
        [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
        {'entity'}
    )

    t.assert_items_equals(space_info, entity_space.sample_data(0))
    t.assert_equals(space_info_err, nil)
end
