--local t = require('luatest')
local fio = require('fio')

local helper = table.copy(require('cartridge.test-helpers'))

helper.root = fio.dirname(debug.sourcedir())
local tmpdir = fio.pathjoin(helper.root, '../tmp')
helper.datadir = fio.abspath(fio.pathjoin(tmpdir, 'db_test'))
helper.project_root = fio.dirname(debug.sourcedir())

function helper.entrypoint(name)
    local path = fio.pathjoin(
        helper.project_root,
        'entrypoint',
        string.format('%s.lua', name)
    )
    if not fio.path.exists(path) then
        error(path .. ': no such entrypoint', 2)
    end
    return path
end

helper.cluster_config = {
    server_command = helper.entrypoint('basic_srv'),
    datadir = helper.datadir,
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
                },
                {
                    instance_uuid = helper.uuid('b', 2),
                    alias = 'storage-1-replica',
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
                },
                {
                    instance_uuid = helper.uuid('c', 2),
                    alias = 'storage-2-replica',
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

return helper
