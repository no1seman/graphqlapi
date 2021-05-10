local t = require('luatest')
local g = t.group('spaceapi')

-- local json = require('json')

-- local json_cfg = {
--     encode_use_tostring = true,
--     encode_deep_as_nil = true,
--     encode_max_depth = 10,
--     encode_invalid_as_nil = true
-- }

local helper = require('test.helper.integration')
local cluster = helper.cluster

g.before_each = function()
    g.cluster = helper.cluster
    g.cluster:start()
end

g.after_each = function()
    g.cluster:stop()
end

local function sample_data(length)
return {{
    format = {
        { type = 'unsigned', name = 'bucket_id', is_nullable = false, },
        { type = 'string', name = 'entity_id', is_nullable = false, },
        { type = 'string', name = 'entity', is_nullable = false, },
        { type = 'number', name = "entity_value", is_nullable = true, }
    },
    id = 512, engine = 'memtx', field_count = 4, is_sync = false,
    index = {
        {
            parts = {{ type = 'string', fieldno = 2, is_nullable = false, }},
            id = 0, space_id = 512, len = length, unique = true, bsize = 49152*length,
            hint = true, type = 'TREE', name = 'primary',
        },
        {
            parts = {{ type = 'number', fieldno = 4, is_nullable = true, }},
            id = 1, space_id = 512, len = length, unique = true, bsize = 49152*length,
            hint = true, type = 'TREE', name = 'secondary',
        },
        {
            parts = {{ type = 'unsigned', fieldno = 1, is_nullable = false, }},
            id = 2, space_id = 512, len = length, unique = false, bsize = 49152*length,
            hint = true, type = 'TREE', name = 'bucket_id',
        }
    },
    bsize = length*16+(length-1)*2,
    temporary = false,
    ck_constraint = {
        {
            space_id = 512, is_enabled = false,
            name = 'entity_value', expr = "'entity_value' > 0",
        }
    },
    is_local = false, enabled = true, name = 'entity', len = length,
}}
end

local function create_test_space(space_name)
    local format = {
        {name = 'bucket_id', type = 'unsigned', is_nullable = false},
        {name = 'entity_id', type = 'string', is_nullable = false},
        {name = 'entity', type = 'string', is_nullable = false},
        {name = 'entity_value', type = 'number', is_nullable = true}
    }

    local primary_index_parts = { {field = 'entity_id'} }
    local secondary_index_parts = { {field = 'entity_value'} }
    local sharding_key = {{'entity_id'}}

    helper.create_space_on_cluster(cluster, space_name, format)
    helper.create_primary_index_on_cluster(cluster, space_name, primary_index_parts)
    helper.create_secondary_index_on_cluster(cluster, space_name, 'secondary', true, secondary_index_parts)
    helper.create_bucket_index_on_cluster(cluster, space_name, sharding_key)
    helper.create_check_constraint_on_cluster(cluster, space_name, 'entity_value', [['entity_value' > 0]])
end

g.test_space_info = function()
    local router = helper.get_server_by_alias(cluster, 'router')
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

    create_test_space('entity')

    helper.insert_data(
        cluster, 'entity',
        { bucket_id= 1, entity_id = '001', entity = 'entity_1', entity_value = 1 }
    )

    helper.insert_data(
        cluster, 'entity',
        { bucket_id= 30000, entity_id = '002', entity = 'entity_2', entity_value = 2 }
    )

    -- check space_info with unexisting space on router
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity1'}
        )

        t.assert_equals(space_info, nil)
        t.assert_equals(space_info_err.err, 'spaces ["entity1"] not found')
    end

    -- check space_info with list of existing spaces
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )

        t.assert_items_equals(space_info, sample_data(2))
        t.assert_equals(space_info_err, nil)
    end

    -- check space_info with wildcard list of spaces
    do
        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {}
        )

        t.assert_items_equals(space_info, sample_data(2))
        t.assert_equals(space_info_err, nil)
    end

    -- check space_info with list of unexisting space on storage
    do
        helper.get_server_by_alias(cluster, 'storage-1-master').net_box:eval(
            [[ box.space['entity']:drop()]])

        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )

        t.assert_equals(space_info, sample_data(1))
        t.assert_str_contains(space_info_err[1].str, 'space "entity" not found on "storage-1-master"')
    end

    -- check space_info with one replicaset not available
    do
        helper.stop_server(cluster, 'storage-1-master')
        helper.stop_server(cluster, 'storage-1-replica')

        space_info, space_info_err = router.net_box:eval(
            [[ return require('graphqlapi.spaceapi').space_info(nil, {name = {...}}) ]],
            {'entity'}
        )
        t.assert_items_equals(space_info, sample_data(1))
        t.assert_str_contains(space_info_err[1].str, 'Connection refused')
    end

    -- print(json.encode(space_info), json.encode(space_info_err))
    -- error()
    -- --helper.drop_space_on_cluster(cluster, 'entity')
end

g.test_space_drop = function()

end

g.test_space_truncate = function()

end

g.test_space_update = function()

end

g.test_space_create = function()

end
