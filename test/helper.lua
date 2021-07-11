local fio = require('fio')
local t = require('luatest')

local helper = table.copy(require('cartridge.test-helpers'))

helper.project_root = fio.dirname(debug.sourcedir())
helper.datadir = fio.pathjoin(helper.project_root, 'tmp', 'unit_test')

function helper.entrypoint(name)
    local path = fio.pathjoin(
        helper.project_root,
        'test',
        'entrypoint',
        string.format('%s.lua', name)
    )
    if not fio.path.exists(path) then
        error(path .. ': no such entrypoint', 2)
    end
    return path
end

helper.create_space = function()
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false, comment = 'Sharding key', },
        { name = 'entity_id', type = 'string', is_nullable = false, comment = 'Entity ID', },
        { name = 'entity', type = 'string', is_nullable = true, comment = 'Entity value', },
        { name = 'property', type = 'string', is_nullable = true, },
        { name = 'feature', type = 'string', is_nullable = false, },
    }

    local space = box.space['entity']
    if space == nil and not box.cfg.read_only then
        space = box.schema.space.create('entity', { if_not_exists = true })
        space:format(format)
        return space
    end
end

helper.cluster_config = {
    server_command = helper.entrypoint('basic_srv'),
    datadir = fio.pathjoin(helper.project_root, 'tmp', 'db_test'),
    use_vshard = true,
    replicasets = {
        {
            alias = 'api',
            uuid = helper.uuid('a'),
            roles = {
                'vshard-router',
                'graphqlapi',
                'app.roles.api',
            },
            servers = {
                {
                    instance_uuid = helper.uuid('a', 1),
                    alias = 'router',
                    advertise_port = 13301,
                    http_port = 8281,
                },
            },
        },
        {
            alias = 'storage-1',
            uuid = helper.uuid('b'),
            roles = {
                'vshard-storage',
                'app.roles.storage'
            },
            servers = {
                {
                    instance_uuid = helper.uuid('b', 1),
                    alias = 'storage-1-master',
                    advertise_port = 13302,
                    http_port = 8282,
                },
                {
                    instance_uuid = helper.uuid('b', 2),
                    alias = 'storage-1-replica',
                    advertise_port = 13303,
                    http_port = 8283,
                },
            },
        },
        {
            alias = 'storage-2',
            uuid = helper.uuid('c'),
            roles = {
                'vshard-storage',
                'app.roles.storage'
            },
            servers = {
                {
                    instance_uuid = helper.uuid('c', 1),
                    alias = 'storage-2-master',
                    advertise_port = 13304,
                    http_port = 8284
                },
                {
                    instance_uuid = helper.uuid('c', 2),
                    alias = 'storage-2-replica',
                    advertise_port = 13305,
                    http_port = 8285
                },
            },
        },
    },
}

function helper.get_server_by_alias(cluster, alias)
    for index, server in ipairs(cluster.servers) do
        if server.alias == alias then
            return cluster.servers[index]
        end
    end
end

function helper.create_space_on_cluster(cluster, space_name, format)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, format = ...
            local space = box.space[space_name]
            if space == nil and not box.cfg.read_only then
                space = box.schema.space.create(space_name, { if_not_exists = true })
                space:format(format)
            end
        ]], {space_name, format})
    end
end

function helper.create_primary_index_on_cluster(cluster, space_name, parts)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, parts = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:create_index('primary', {
                    parts = parts,
                    if_not_exists = true,
                })
            end
        ]], {space_name, parts})
    end
end

function helper.create_secondary_index_on_cluster(cluster, space_name, name, unique, parts)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, name, unique, parts = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:create_index(name, {
                    parts = parts,
                    unique = unique,
                    if_not_exists = true,
                })
            end
        ]], {space_name, name, unique, parts})
    end
end

function helper.create_bucket_index_on_cluster(cluster, space_name, fields)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, fields = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                local bucket_field = 'bucket_id'
                space:create_index(bucket_field, {
                    parts = { bucket_field },
                    unique = false,
                    if_not_exists = true,
                })

                -- register sharding key
                if box.space._ddl_sharding_key == nil then
                    local sharding_space = box.schema.space.create('_ddl_sharding_key', {
                    format = {
                            {name = 'space_name', type = 'string', is_nullable = false},
                            {name = 'sharding_key', type = 'array', is_nullable = false}
                        },
                        if_not_exists = true
                    })
                    sharding_space:create_index(
                    'space_name', {
                            type = 'TREE',
                            unique = true,
                            parts = {{'space_name', 'string', is_nullable = false}},
                            if_not_exists = true
                        }
                    )
                end
                box.space._ddl_sharding_key:replace{space_name, fields}
            end
        ]], {space_name, fields})
    end
end

function helper.drop_index_on_cluster(cluster, space_name, index_name)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, index_name = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:create_check_constraint(name, expression)
            end
        ]], {space_name, index_name})
    end
end

function helper.create_check_constraint_on_cluster(cluster, space_name, name, expression)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, name, expression = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                local constraint = space:create_check_constraint(name, expression)
                constraint:enable(false)
            end
        ]], {space_name, name, expression})
    end
end

function helper.create_test_space(cluster, space_name)
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

function helper.insert_data(cluster, space_name, data)
    local router = helper.get_server_by_alias(cluster, 'router')
    local res, err = router.net_box:eval([[
        local space_name, data = ...
        local _data = box.space.entity:frommap(data)
        local vshard = require('vshard')
        return vshard.router.callrw(data.bucket_id, 'box.space.'..space_name..':insert', {_data}, {timeout=5})
    ]], {space_name, data})
    return res, err
end

function helper.sample_data(length)
    local bsize

    if length == 0 then
        bsize = 0
    else
        bsize = length*16+(length-1)*2
    end

    local full_bsize = bsize+3*49152*length

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
        bsize = bsize,
        full_bsize = full_bsize,
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

function helper.drop_space_on_cluster(cluster, space_name)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:drop()
            end
        ]], {space_name})
    end
end

function helper.truncate_space_on_cluster(cluster, space_name)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:truncate()
            end
        ]], {space_name})
    end
end

t.before_suite(function()
    fio.rmtree(helper.datadir)
    fio.mktree(helper.datadir)
    box.cfg({
        memtx_dir = helper.datadir,
        wal_dir = helper.datadir
    })
end)

return helper
