local fio = require('fio')
local t = require('luatest')
local g = t.group('spaceapi')

-- local json = require('json')

-- local json_cfg = {
--     encode_use_tostring = true,
--     encode_deep_as_nil = true,
--     encode_max_depth = 10,
--     encode_invalid_as_nil = true
-- }

local helper = require('test.helper')

g.before_each(function()
    local cluster_config = table.deepcopy(helper.cluster_config)
    g.cluster = helper.Cluster:new(cluster_config)
    g.cluster:start()
end)

g.after_each(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
    g.cluster = nil
end)

g.test_space_info = function()
    local router = g.cluster:server('router')
    local space_info, space_info_err

    -- check space_info with empty cluster
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {}
        )
        t.assert_equals(space_info, nil)
        t.assert_equals(space_info_err, nil)
    end

    -- check space_info with non-existing space on router
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )
        t.assert_equals(space_info, nil)
        t.assert_equals(space_info_err.err, 'space(s) ["entity"] not found')
    end

    helper.create_test_space(g.cluster, 'entity')

    helper.insert_data(
        g.cluster, 'entity',
        { bucket_id= 1, entity_id = '001', entity = 'entity_1', entity_value = 1 }
    )
    helper.insert_data(
        g.cluster, 'entity',
        { bucket_id= 30000, entity_id = '002', entity = 'entity_2', entity_value = 2 }
    )

    -- check space_info with list of existing spaces
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_info, helper.sample_data(2))
        t.assert_equals(space_info_err, nil)
    end

    -- check space_info with wildcard list of spaces
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {}
        )
        t.assert_items_equals(space_info, helper.sample_data(2))
        t.assert_equals(space_info_err, nil)
    end

    -- check space_info with list of non-existing space on storage
    do
        g.cluster:server('storage-1-master').net_box:eval(
            [[ box.space['entity']:drop()]])

        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )
        t.assert_equals(space_info, helper.sample_data(1))
        t.assert_str_contains(space_info_err[1].str, 'space "entity" not found on "storage-1-master"')
    end

    -- check space_info with one replicaset not available
    do
        g.cluster:server('storage-1-master'):stop()
        g.cluster:server('storage-1-replica'):stop()
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_info, helper.sample_data(1))
        t.assert_str_contains(space_info_err[1].str, 'Connection refused')
    end
end

g.test_space_drop = function()
    local router = g.cluster:server('router')
    local space_drop, space_drop_err

    -- check space_drop with non-existing space on router
    do
        space_drop, space_drop_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_drop(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_equals(space_drop, false)
        t.assert_equals(space_drop_err.str, "spaceAPI error: space 'entity' not found")
    end

    -- check space_drop with existing space
    do
        helper.create_test_space(g.cluster, 'entity')
        space_drop, space_drop_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_drop(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_equals(space_drop, true)
        t.assert_equals(space_drop_err, nil)
    end

    -- check space_drop with non-existing space on storage
    do
        helper.create_test_space(g.cluster, 'entity')
        g.cluster:server('storage-1-master').net_box:eval([[ box.space['entity']:drop()]])
        space_drop, space_drop_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_drop(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_equals(space_drop, true)
        t.assert_str_contains(space_drop_err[1].str, 'space "entity" not found on "storage-1-master"')
    end

    -- check space_info with one replicaset not available
    do
        helper.create_test_space(g.cluster, 'entity')
        g.cluster:server('storage-1-master'):stop()
        g.cluster:server('storage-1-replica'):stop()
        space_drop, space_drop_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_drop(nil, {name = ...}) ]],
            {'entity'}
        )

        t.assert_equals(space_drop, true)
        t.assert_str_contains(space_drop_err[1].str, 'Connection refused')
    end
end

g.test_space_truncate = function()
    local router = g.cluster:server('router')
    local space_truncate, space_truncate_err

    -- check space_truncate with non-existing space on router
    do
        space_truncate, space_truncate_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_truncate(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_equals(space_truncate, nil)
        t.assert_equals(space_truncate_err.str, "spaceAPI error: space 'entity' not found")
    end

    -- check space_truncate with existing empty space
    do
        helper.create_test_space(g.cluster, 'entity')
        space_truncate, space_truncate_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_truncate(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_truncate, { truncated_bsize = 0, truncated_len = 0, name = "entity" })
        t.assert_equals(space_truncate_err, nil)
    end

    -- check space_truncate with existing space
    do
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 1, entity_id = '001', entity = 'entity_1', entity_value = 1 }
        )
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 30000, entity_id = '002', entity = 'entity_2', entity_value = 2 }
        )
        space_truncate, space_truncate_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_truncate(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_truncate, { truncated_bsize = 294946, truncated_len = 2, name = "entity" })
        t.assert_equals(space_truncate_err, nil)
    end

    -- check space_truncate with non-existing space on storage
    do
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 1, entity_id = '001', entity = 'entity_1', entity_value = 1 }
        )
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 30000, entity_id = '002', entity = 'entity_2', entity_value = 2 }
        )
        g.cluster:server('storage-1-master').net_box:eval([[ box.space['entity']:drop()]])
        space_truncate, space_truncate_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_truncate(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_equals(space_truncate, { truncated_bsize = 147472, truncated_len = 1, name = "entity" })
        t.assert_str_contains(space_truncate_err[1].str, 'space "entity" not found on "storage-1-master"')
    end

    -- check space_info with one replicaset not available
    do
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 1, entity_id = '001', entity = 'entity_1', entity_value = 1 }
        )
        helper.insert_data(
            g.cluster, 'entity',
            { bucket_id= 30000, entity_id = '002', entity = 'entity_2', entity_value = 2 }
        )
        g.cluster:server('storage-1-master'):stop()
        g.cluster:server('storage-1-replica'):stop()
        space_truncate, space_truncate_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_truncate(nil, {name = ...}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_truncate, { truncated_bsize = 147472, truncated_len = 1, name = "entity" })
        t.assert_str_contains(space_truncate_err[1].str, 'Connection refused')
    end
end

g.test_space_create = function()

end

g.test_space_update = function()

end
