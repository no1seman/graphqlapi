local argparse = require('cartridge.argparse')
local cartridge = require('cartridge')
local checks = require('checks')
local errors = require('errors')
local pool = require('cartridge.pool')
local vshard = require('vshard')

local e_space_api = errors.new_class('spaceAPI error', { capture_stack = false })

local function get_alias_by_uuid(conn)
    checks('table')
    for _, server in pairs(cartridge.admin_get_servers()) do
        if server.uuid == conn.peer_uuid then
            return server.alias
        end
    end
    return tostring(conn.host)..':'..tostring(conn.port)
end

local function get_servers()
    local servers = {}
    local connect_errors
    for _,server in pairs(cartridge.admin_get_servers()) do
        local conn, err = pool.connect(server.uri)
        local replicaset_uuid = server.replicaset.uuid or '00000000-0000-0000-0000-000000000000'
        local alias = server.alias or 'unknown'
        if conn then
            table.insert(servers, {replicaset_uuid = replicaset_uuid, alias = alias, conn = conn})
        else
            connect_errors = connect_errors or {}
            table.insert(connect_errors,  e_space_api:new('instance \'%s\' error: %s', alias, err))
        end
    end
    return servers, connect_errors
end

local function get_masters()
    local masters = {}
    local connect_errors
    for _, replicaset in pairs(require('cartridge').admin_get_replicasets()) do
        local conn, err = pool.connect(replicaset.active_master.uri)
        local replicaset_uuid = replicaset.uuid or '00000000-0000-0000-0000-000000000000'
        local alias = replicaset.active_master.alias or 'unknown'
        if conn then
            table.insert(masters, {replicaset_uuid = replicaset_uuid, alias = alias, conn = conn})
        else
            connect_errors = connect_errors or {}
            table.insert(connect_errors,  e_space_api:new('instance \'%s\' error: %s', alias, err))
        end
    end
    return masters, connect_errors
end

local function get_storages_masters()
    local masters = {}
    for uuid, replicaset in pairs(vshard.router.routeall()) do
        local conn = replicaset.master.conn
        local replicaset_uuid = uuid or '00000000-0000-0000-0000-000000000000'
        local alias = get_alias_by_uuid(conn)
        table.insert(masters, {replicaset_uuid = replicaset_uuid, alias = alias, conn = replicaset.master.conn})
    end
    return masters
end

local function get_self_alias()
    local parse = argparse.parse()
    return parse.instance_name or parse.alias or box.info.uuid
end

return {
    get_servers = get_servers,
    get_masters = get_masters,
    get_storages_masters = get_storages_masters,
    get_self_alias = get_self_alias,
}