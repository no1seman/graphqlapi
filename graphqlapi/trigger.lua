local checks = require('checks')
local errors = require('errors')
local fiber = require('fiber')
local log = require('log')
local string = require('string')

local defaults = require('graphqlapi.defaults')
local helpers = require('graphqlapi.helpers')
local models = require('graphqlapi.models')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local vars = require('graphqlapi.vars').new('graphqlapi.spaces')

local e_space_update_fiber = errors.new_class('space updater fiber error')

vars:new('updater', nil)

local function updater_init()
    local channel = fiber.channel(defaults.CHANNEL_CAPACITY)
    local updater_fiber = fiber.create(function()
        fiber.self():name('gql_updater', {truncate = true})
        while true do
            fiber.testcancel()
            local ok, err = e_space_update_fiber:pcall(function()
                local message = channel:get(defaults.CHANNEL_TIMEOUT)

                if message ~= nil and
                   message.space and
                   message.space.name and
                   message.space.id > box.schema.SYSTEM_ID_MAX and
                   not string.startswith(message.space.name, '_') then
                    if message.op == 'DELETE' then
                        helpers.update()
                        models.remove_model_by_space_name(message.space.name)
                        types.remove_types_by_space_name(message.space.name)
                        operations.remove_operations_by_space_name(message.space.name)
                    else
                        helpers.update()
                        models.update_space_models(message.space.name)
                    end
                end
            end)
            if not ok and err ~= nil and vars.updater ~= nil then
                log.error('%s', err)
            end
        end
    end)

    vars.updater = {
        fiber = updater_fiber,
        channel = channel,
    }
end

local function set_trigger(trigger)
    checks('function')
    local triggers = box.space._space:on_replace()
    for _, func in pairs(triggers) do
        if func == trigger then
            log.warn('space trigger is already set')
            return nil, 'space trigger is already set'
        end
    end
    box.space._space:on_replace(trigger)
    return true
end

local function remove_trigger(trigger)
    checks('function')
    local triggers = box.space._space:on_replace()
    for _, func in pairs(triggers) do
        if func == trigger then
            box.space._space:on_replace(nil, trigger)
        end
    end
end

local function space_trigger(old, new, sp, op) -- luacheck: no unused args
    box.on_commit(function()
        if new ~= nil then
            -- Insert or update or upsert or replace space
            local new_space = new:tomap({names_only = true})
            if vars.updater and new_space.name then
                vars.updater.channel:put({space = new_space}, 0)
            end
        else
            -- Delete space
            local old_space = old:tomap({names_only = true})
            if vars.updater and old_space.name then
                vars.updater.channel:put({space = old_space, op = 'DELETE'}, 0)
            end
        end
    end)
end

local function init()
    updater_init()
    set_trigger(space_trigger)
end

local function stop()
    remove_trigger(space_trigger)
    if vars.updater then
        if vars.updater.fiber:status() ~= 'dead' then
            vars.updater.fiber:cancel()
        end
        vars.updater.channel:close()
        vars.updater = nil
    end
end

return {
    init = init,
    stop = stop,
}
