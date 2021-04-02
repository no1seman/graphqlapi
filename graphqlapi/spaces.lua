local checks = require('checks')
local fiber = require('fiber')
local log = require('log')

local models = require('graphqlapi.models')
local helpers = require('graphqlapi.helpers')
local vars = require('graphqlapi.vars').new('graphqlapi.spaces')

local CHANNEL_CAPACITY = 1000
local UPDATE_TIMEOUT = 3

vars:new('updater', nil)

local function updater_init()
    local channel = fiber.channel(CHANNEL_CAPACITY)
    local updater_fiber = fiber.create(function()
        while true do
            fiber.testcancel()

            local message = channel:get(UPDATE_TIMEOUT)

            if message ~= nil and message.space and message.space.name then
                if message.op == 'DELETE' then
                    --log.info('Updater fiber: delete space %s', message.space.name)
                    helpers.update_lists()
                    models.remove_model_by_space_name(message.space.name)
                else
                    --log.info('Updater fiber: update space %s', message.space.name)
                    helpers.update_lists()
                    models.update_space_models(message.space.name)
                end
            end
        end
    end)

    updater_fiber:name('gql_updater', {truncate = true})
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
    box.space._space:on_replace(nil, trigger)
end

local function space_trigger(old, new, sp, op) -- luacheck: no unused args
    box.on_commit(function()
        if new ~= nil then
            -- Insert, Update, Upsert, Replace space
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
