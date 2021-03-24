local checks = require('checks')
local ddl = require('ddl')
--local errors = require('errors')
local fiber = require('fiber')
--local json = require('json')
--local log = require('log')
local vshard = require('vshard')

--local e_space_api = errors.new_class('space API error', { capture_stack = false })

local function list_spaces(schema)
    local spaces = {}
    schema = schema or ddl.get_schema()
    for space in pairs(schema.spaces) do
        spaces[space]=space
    end
    return spaces
end

local function get_space_size(spaces)
    local counters = {}
    local fibers = {}
    local remote_errors = {}

    local shards, err = vshard.router.routeall()
    if err ~= nil then
        error(err)
    end

    for uid, replica in pairs(shards) do
        local f = fiber.new(function()
            local ok, res, eval_err = pcall(function()
                return replica.master.conn:eval([[
                    local log = require('log')
                    local fiber = require('fiber')
                    local spaces = ... or {}
                    local counters = {}
                    local errors = {}

                    for _, space_name in pairs(spaces) do
                        local space = box.space[space_name]
                        if space then
                            counters[space_name] = {}
                            counters[space_name].len = space:len() or 0
                            counters[space_name].size = space:bsize() or 0

                            counters[space_name].index = {}
                            for i = 0, #space.index do
                                local index = space.index[i]
                                if index ~= nil then
                                    counters[space_name].index[i] = {}
                                    counters[space_name].index[i].len = index:len() or 0
                                    counters[space_name].index[i].size = index:bsize() or 0
                                end
                            end
                        else
                            log.error(string.format(
                                    'Error: space "%s" not found on instance "%s"',
                                    space_name,
                                    box.info.uuid))
                            table.insert(errors, string.format(
                                    'Error: space "%s" not found on instance "%s"',
                                    space_name,
                                    box.info.uuid))
                        end
                        fiber.yield()
                    end
                    return counters, errors
                ]], {spaces}, {timeout = 30})
            end)

            if ok then
                for _, space_name in pairs(spaces) do
                    if res[space_name] then
                        counters[space_name] = counters[space_name] or {}
                        counters[space_name].len = (counters[space_name].len or 0) + (res[space_name].len or 0)
                        counters[space_name].size = (counters[space_name].size or 0) + (res[space_name].size or 0)

                        counters[space_name].index =  counters[space_name].index or {}
                        for i = 0, #box.space[space_name].index do
                            counters[space_name].index[i] = counters[space_name].index[i] or {}
                            counters[space_name].index[i].len =
                            (counters[space_name].index[i].len or 0) + (res[space_name].index[i].len or 0)
                            counters[space_name].index[i].size =
                            (counters[space_name].index[i].size or 0) + (res[space_name].index[i].size or 0)
                        end

                    end
                end
            end

            if next(eval_err) then
                table.insert(remote_errors, eval_err)
            end

            return true
        end)
        f:set_joinable(true)
        f:name(uid, {truncate=true})
        table.insert(fibers, f)
        fiber.yield()
    end

    for _, f in pairs(fibers) do
        f:join()
    end

    if next(remote_errors) then
        return counters, remote_errors
    else
        return counters
    end
end

local function space_get(_, args, _)
    checks('?', {name = 'table'}, '?')
    local spaces = args.name
    local schema = ddl.get_schema()

    local res = {}

    if not next(spaces) then
        spaces = list_spaces(schema)
    end

    local spaces_size = get_space_size(spaces)

    for _,space_name in pairs(spaces) do
        local space = {}

        for k, v in pairs(box.space[space_name]) do
            if type(v) ~= 'table' then space[k] = v end
        end

        space.format = box.space[space_name]:format()
        space.size = spaces_size[space_name].size or 0
        space.len = spaces_size[space_name].len or 0
        space.field_count = #space.format

        space.index = {}
        for i = 0, #box.space[space_name].index do
            local index = {}
            if box.space[space_name].index[i] ~= nil and
               spaces_size[space_name].index and
               spaces_size[space_name].index[i] then
                index.id = i
                index.len = spaces_size[space_name].index[i].len or 0
                index.size = spaces_size[space_name].index[i].size or 0
                table.insert(space.index, index)
            end
        end

        space.ck_constraint = {}
        if box.space[space_name].ck_constraint then
            for _, v in pairs(box.space[space_name].ck_constraint) do
                table.insert(space.ck_constraint, v)
            end
        end
        table.insert(res, space)
    end

    return res
end

-- local function _space_get(space_name)
--     local space = {}

--     for k, v in pairs(box.space[space_name]) do
--         if type(v) ~= 'table' then space[k] = v end
--     end

--     space.format = box.space[space_name]:format()

--     space.index = {}
--     for i = 0, #box.space[space_name].index do
--         local index = box.space[space_name].index[i]
--         if index ~= nil then
--             index.id = i
--             table.insert(space.index, index)
--         end
--     end

--     space.ck_constraint = {}
--     if box.space[space_name].ck_constraint then
--         for _, v in pairs(box.space[space_name].ck_constraint) do
--             table.insert(space.ck_constraint, v)
--         end
--     end

--     return space
-- end

-- local function _space_remove_by_id(space_id)
--     checks('number')

--     local space = _space_get(box.space['_space']:select(space_id)[1][3])

--     log.info(space)
--     local ok, err = pcall(box.schema.space.drop, space_id)

--     if ok then
--         return space
--     else
--         return nil,
--                e_space_api:new('space id=%s delete error: %s', space_id, err)
--     end
-- end

-- local function _space_remove_by_name(space_name)
--     checks('string')

--     if box.space[space_name] then
--         local space_id = box.space[space_name].id
--         return _space_remove_by_id(space_id)
--     else
--         return nil, e_space_api:new("space %s doesn't exist", space_name)
--     end
-- end

-- local function space_remove(args)
--     local space_name = args.name
--     local space_id = tonumber(args.id)

--     -- if both space name and space id is provided - return an error
--     if (space_name and space_id) then
--         local err = e_space_api:new('Both space name and space id is provided in request')
--         return nil, err
--     end

--     if space_name and space_name ~= '' then
--         return _space_remove_by_name(space_name)
--     end

--     if space_id and space_id ~= '' then
--         return _space_remove_by_id(space_id)
--     end
--     local err = e_space_api:new('No space name nor space id is provided in request')
--     return nil, err
-- end

-- local function space_add(args)
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
    space_get = space_get,
    -- space_remove = space_remove,
    -- space_add = space_add,
    list_spaces = list_spaces,
}
