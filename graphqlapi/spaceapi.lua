local checks = require('checks')
local ddl = require('ddl')
local errors = require('errors')
local fiber = require('fiber')
local vshard = require('vshard')
local json = require('json')

local utils = require('graphqlapi.utils')

local NET_BOX_CONNECTION_TIMEOUT = 1
local e_space_api = errors.new_class('spaceAPI error', { capture_stack = false })

local function list_spaces(schema)
    local spaces = {}
    for space in pairs(schema.spaces) do
        table.insert(spaces, space)
    end
    return spaces
end

local function _get_space_size(spaces)
    local counters = {}
    local fibers = {}
    local remote_errors

    local shards = vshard.router.routeall()

    for uid, replica in pairs(shards) do
        local f = fiber.new(function()
            local ok, res, eval_err = pcall(function()
                return replica.master.conn:eval([[
                    local log = require('log')
                    local fiber = require('fiber')
                    local errors = require('errors')
                    local spaces = ... or {}
                    local counters = {}
                    local err = {}

                    local e_space_api = errors.new_class('spaceAPI error', { capture_stack = false })

                    for _, space_name in pairs(spaces) do
                        local space = box.space[space_name]
                        if space then
                            counters[space_name] = {}
                            counters[space_name].len = space:len() or 0
                            counters[space_name].bsize = space:bsize() or 0

                            counters[space_name].index = {}
                            for i = 0, #space.index do
                                local index = space.index[i]
                                if index ~= nil then
                                    counters[space_name].index[i] = {}
                                    counters[space_name].index[i].len = index:len() or 0
                                    counters[space_name].index[i].bsize = index:bsize() or 0
                                end
                            end
                        else
                            local ctg, instance = pcall(function()
                                local parse = require('cartridge.argparse').parse()
                                if parse and type(parse) == 'table' then
                                    return parse.instance_name or parse.alias or nil
                                else
                                    return nil
                                end
                            end)
                            if not ctg then
                                instance = box.info.uuid
                            end
                            local space_size_error = e_space_api:new('space "%s" not found on "%s"',
                            space_name,
                            instance)
                            space_size_error.file = 'spaceapi.lua'
                            log.error('%s', space_size_error)
                            table.insert(err, space_size_error)
                        end
                        fiber.yield()
                    end
                    return counters, err
                ]], {spaces}, {timeout = NET_BOX_CONNECTION_TIMEOUT})
            end)

            local ctg, instance = pcall(function()
                local parse = require('cartridge.argparse').parse()
                if parse and type(parse) == 'table' then
                    return parse.instance_name or parse.alias or nil
                else
                    return nil
                end
            end)
            if not ctg then
                instance = box.info.uuid
            end

            if ok then
                for _, space_name in pairs(spaces) do
                    if box.space[space_name] then
                        if res[space_name] then
                            counters[space_name] = counters[space_name] or {}
                            counters[space_name].len =
                                (counters[space_name].len or 0) + (res[space_name].len or 0)
                            counters[space_name].bsize =
                                (counters[space_name].bsize or 0) + (res[space_name].bsize or 0)

                            counters[space_name].index =  counters[space_name].index or {}
                            for i = 0, #box.space[space_name].index do
                                counters[space_name].index[i] = counters[space_name].index[i] or {}
                                counters[space_name].index[i].len =
                                    (counters[space_name].index[i].len or 0) + (res[space_name].index[i].len or 0)
                                counters[space_name].index[i].bsize =
                                    (counters[space_name].index[i].bsize or 0) + (res[space_name].index[i].bsize or 0)
                            end
                        end
                    else
                        remote_errors = remote_errors or {}
                        table.insert(
                            remote_errors,
                            e_space_api:new('space "%s" not found on %s', space_name, instance)
                        )
                    end
                end
            else
                local storage = tostring(replica.master.conn.host)..':'..tostring(replica.master.conn.port)
                remote_errors = remote_errors or {}
                table.insert(remote_errors, e_space_api:new('instance "%s" error: %s', storage, res))
            end

            if eval_err and #eval_err > 0 then
                remote_errors = utils.concat_arrays(remote_errors, eval_err)
            end

            return true
        end)
        f:set_joinable(true)
        f:name(uid, { truncate=true })
        table.insert(fibers, f)
        fiber.yield()
    end

    for _, f in pairs(fibers) do
        f:join()
    end

    return counters, remote_errors
end

local function space_info(_, args)
    checks('?', { name = 'table' })
    local spaces = args.name or {}
    local schema = ddl.get_schema()

    local res

    local router_spaces = list_spaces(schema)

    if not next(spaces) then
        spaces = router_spaces
    else
        local _spaces = utils.diff_arrays(spaces, router_spaces)
        if not next(_spaces) then
            return nil, e_space_api:new('spaces %s not found', json.encode(spaces))
        end
        spaces = _spaces
    end

    local spaces_size, remote_errors = _get_space_size(spaces)

    for _, space_name in pairs(spaces) do
        local space = {}
        local _space = box.space[space_name]
        if _space then
            if spaces_size[space_name] then
                for k, v in pairs(_space) do
                    if type(v) ~= 'table' and type(v) ~= 'function' then space[k] = v end
                end

                space.format = _space:format()

                space.bsize = spaces_size[space_name].bsize or 0
                space.len = spaces_size[space_name].len or 0
                space.field_count = #space.format

                space.index = {}
                for i = 0, #_space.index do
                    if _space.index[i] ~= nil and
                    spaces_size[space_name].index and
                    spaces_size[space_name].index[i] then
                        local index = table.copy(_space.index[i])
                        index.id = i
                        index.len = spaces_size[space_name].index[i].len or 0
                        index.bsize = spaces_size[space_name].index[i].bsize or 0
                        table.insert(space.index, index)
                    end
                end

                space.ck_constraint = {}
                if _space.ck_constraint then
                    for _, v in pairs(_space.ck_constraint) do
                        table.insert(space.ck_constraint, v)
                    end
                end
                res = res or {}
                table.insert(res, space)
            end
        end
    end

    return res, remote_errors
end

-- local function space_drop(_, args)
--     checks('?', { name = 'string' }, '?')
--     local space = args.name
--     local fibers = {}
--     local remote_errors = {}

--     local shards, err = vshard.router.routeall()
--     if err ~= nil then
--         error(err)
--     end

--     for uid, replica in pairs(shards) do
--         local f = fiber.new(function()
--             local _, _, eval_err = pcall(function()
--                 return replica.master.conn:eval([[
--                     local space = box.space[...]
--                     if space then
--                         return box.space[space]:drop()
--                     end
--                 ]], {space}, {timeout = 30})
--             end)

--             if eval_err and #eval_err > 0 then
--                 table.insert(remote_errors, eval_err)
--             end

--             return true
--         end)
--         f:set_joinable(true)
--         f:name(uid, { truncate=true })
--         table.insert(fibers, f)
--         fiber.yield()
--     end

--     for _, f in pairs(fibers) do
--         f:join()
--     end

--     if remote_errors and #remote_errors > 0 then
--         return nil, remote_errors
--     else
--         return true
--     end
-- end

-- local function space_truncate(_, args)
--     checks('?', { name = 'string' })
--     local space = args.name
--     local fibers = {}
--     local remote_errors = {}

--     local shards, err = vshard.router.routeall()
--     if err ~= nil then
--         error(err)
--     end

--     for uid, replica in pairs(shards) do
--         local f = fiber.new(function()
--             local _, _, eval_err = pcall(function()
--                 return replica.master.conn:eval([[
--                     local space = box.space[...]
--                     if space then
--                         space:truncate()
--                         -- counters[space_name].len = space:len() or 0
--                         -- counters[space_name].bsize = space:bsize() or 0
--                     end
--                 ]], {space}, {timeout = 30})
--             end)

--             if eval_err and #eval_err > 0 then
--                 table.insert(remote_errors, eval_err)
--             end

--             return true
--         end)
--         f:set_joinable(true)
--         f:name(uid, { truncate=true })
--         table.insert(fibers, f)
--         fiber.yield()
--     end

--     for _, f in pairs(fibers) do
--         f:join()
--     end

--     if remote_errors and #remote_errors > 0 then
--         return nil, remote_errors
--     else
--         return true
--     end
-- end

-- local function space_create(args)
--     local space_name = args.name
--     local space_index = args.index
--     local space_ck_constraints = args.ck_constraint

--     if box.space[space_name] then
--         return nil, e_space_api:new('space %s already exists', space_name)
--     end

--     local space_options = {
--         engine = args.engine and args.engine or 'memtx',
--         field_count = args.field_count and
--             tonumber(args.field_count) or 0,
--         id = args.id and args.id or nil,
--         if_not_exists = args.if_not_exists and args.if_not_exists or
--             false,
--         is_local = args.is_local and args.is_local or false,
--         temporary = args.temporary and args.temporary or false,
--         user = args.user and args.user or box.session.user()
--     }

--     local format = {}
--     for _, field in pairs(args.format) do
--         table.insert(format, {
--             name = field.name,
--             type = field.type,
--             is_nullable = field.is_nullable and field.is_nullable or false
--         })
--     end

--     space_options.format = format

--     local ok, err = pcall(box.schema.space.create, space_name, space_options)

--     if not ok then
--         return nil, e_space_api:new('space creation error: %s', err)
--     end

--     for _, index in pairs(space_index) do
--         local index_name = index.name
--         local index_options = {
--             type = index.type and index.type or 'TREE',
--             id = index.id and index.id or nil,
--             unique = index.unique and index.unique or true,
--             if_not_exists = index.if_not_exists and index.if_not_exists or true
--         }

--         index_options.parts = {}

--         if index.parts then
--             for _, part in pairs(index.parts) do
--                 table.insert(index_options.parts, {
--                     field = part.fieldno,
--                     type = part.type,
--                     is_nullable = part.is_nullable
--                 })
--             end
--         else
--             index_options.parts = {1, 'unsigned'}
--         end

--         ok = box.space[space_name]:create_index(index_name, index_options)

--         if not ok then
--             return nil, e_space_api:new('Index %s creation error: %s', index_name, err)
--         end
--     end

--     for _, check_constraint in pairs(space_ck_constraints) do
--         local check_constraint_name = check_constraint.name
--         local check_constraint_expr = check_constraint.expr
--         local check_constraint_is_enabled = check_constraint.is_enabled
--         box.space[space_name]:create_check_constraint(check_constraint_name,
--                                                       check_constraint_expr)
--         box.space[space_name].ck_constraint[check_constraint_name]:enable(
--             check_constraint_is_enabled)
--     end

--     return _space_get(space_name)
-- end

return {
    space_info = space_info,
    --space_drop = space_drop,
    --space_truncate = space_truncate,
    -- space_create = space_create,
    list_spaces = list_spaces,
    NET_BOX_CONNECTION_TIMEOUT = NET_BOX_CONNECTION_TIMEOUT,
}
