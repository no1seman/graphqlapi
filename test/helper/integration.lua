local t = require('luatest')

local fio = require('fio')

local cartridge_helpers = require('cartridge.test-helpers')
local shared = require('test.helper')

local helper = {shared = shared}

helper.project_root = fio.dirname(debug.sourcedir())

helper.cluster = cartridge_helpers.Cluster:new({
    server_command = shared.server_command,
    datadir = shared.datadir,
    use_vshard = true,
    replicasets = {
        {
            alias = 'api',
            uuid = cartridge_helpers.uuid('a'),
            roles = {
                'vshard-router',
                'test.entrypoint.app.roles.api',
            },
            servers = {
                {
                    instance_uuid = cartridge_helpers.uuid('a', 1),
                    alias = 'router',
                },
            },
        },
        {
            alias = 'storage-1',
            uuid = cartridge_helpers.uuid('b'),
            roles = {
                'vshard-storage',
                'test.entrypoint.app.roles.storage'
            },
            servers = {
                {
                    instance_uuid = cartridge_helpers.uuid('b', 1),
                    alias = 'storage-1-master',
                },
                {
                    instance_uuid = cartridge_helpers.uuid('b', 2),
                    alias = 'storage-1-replica',
                },
            },
        },
        {
            alias = 'storage-2',
            uuid = cartridge_helpers.uuid('c'),
            roles = {
                'vshard-storage',
                'test.entrypoint.app.roles.storage'
            },
            servers = {
                {
                    instance_uuid = cartridge_helpers.uuid('c', 1),
                    alias = 'storage-2-master',
                },
                {
                    instance_uuid = cartridge_helpers.uuid('c', 2),
                    alias = 'storage-2-replica',
                },
            },
        },
    },
})

function helper.register_sharding_key(space_name, fields)
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

function helper.create_secondary_index_on_cluster(cluster, space_name, unique, parts)
    assert(cluster ~= nil)
    for _, server in ipairs(cluster.servers) do
        server.net_box:eval([[
            local space_name, unique, parts = ...
            local space = box.space[space_name]
            if space ~= nil and not box.cfg.read_only then
                space:create_index(name, {
                    parts = parts,
                    unique = unique,
                    if_not_exists = true,
                })
            end
        ]], {space_name, unique, parts})
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

t.before_suite(function() helper.cluster:start() end)
t.after_suite(function() helper.cluster:stop() end)

return helper
