local fio = require('fio')
local t = require('luatest')
local g = t.group('cluster')

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

local function find_by_alias(servers, alias)
    for _, server in pairs(servers) do
        if server.alias == alias then
            return server
        end
    end
end

g.test_get_servers = function()
    local router = g.cluster:server('router')
    local servers = helper.run_remotely(
        router,
        function() return require("graphqlapi.cluster").get_servers() end
    )

    t.assert_equals(#servers, #g.cluster.servers)
    for _, server in pairs(servers) do
        local instance = g.cluster:server(server.alias)
        t.assert_equals(server.replicaset_uuid, instance.replicaset_uuid)
        t.assert_equals(tostring(server.conn.host)..':'..tostring(server.conn.port), instance.net_box_uri)
    end
end

g.test_get_masters = function()
    local router = g.cluster:server('router')
    local servers = helper.run_remotely(
        router,
        function() return require("graphqlapi.cluster").get_masters() end
    )

    t.assert_equals(#servers, 3)
    -- check router
    local _router = find_by_alias(servers, 'router')
    t.assert_equals(_router.replicaset_uuid, router.replicaset_uuid)
    t.assert_equals(tostring(_router.conn.host)..':'..tostring(_router.conn.port), router.net_box_uri)

    -- check storage-1-master
    local storage_1_master = g.cluster:server('storage-1-master')
    local _storage_1_master = find_by_alias(servers, 'storage-1-master')
    t.assert_equals(_storage_1_master.replicaset_uuid, storage_1_master.replicaset_uuid)
    t.assert_equals(
        tostring(_storage_1_master.conn.host)..':'..
        tostring(_storage_1_master.conn.port), storage_1_master.net_box_uri)

    -- check storage-2-master
    local storage_2_master = g.cluster:server('storage-2-master')
    local _storage_2_master = find_by_alias(servers, 'storage-2-master')
    t.assert_equals(_storage_2_master.replicaset_uuid, storage_2_master.replicaset_uuid)
    t.assert_equals(
        tostring(_storage_2_master.conn.host)..':'..
        tostring(_storage_2_master.conn.port), storage_2_master.net_box_uri)
end

g.test_get_storages_masters = function()
    local router = g.cluster:server('router')
    local servers = helper.run_remotely(
        router,
        function() return require("graphqlapi.cluster").get_storages_masters() end
    )
    t.assert_equals(#servers, 2)

    -- check storage-1-master
    local storage_1_master = g.cluster:server('storage-1-master')
    local _storage_1_master = find_by_alias(servers, 'storage-1-master')
    t.assert_equals(_storage_1_master.replicaset_uuid, storage_1_master.replicaset_uuid)
    t.assert_equals(
        tostring(_storage_1_master.conn.host)..':'..
        tostring(_storage_1_master.conn.port), storage_1_master.net_box_uri)

    -- check storage-2-master
    local storage_2_master = g.cluster:server('storage-2-master')
    local _storage_2_master = find_by_alias(servers, 'storage-2-master')
    t.assert_equals(_storage_2_master.replicaset_uuid, storage_2_master.replicaset_uuid)
    t.assert_equals(
        tostring(_storage_2_master.conn.host)..':'..
        tostring(_storage_2_master.conn.port), storage_2_master.net_box_uri)
end
