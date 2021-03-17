local checks = require('checks')
local log = require('log')

local models = require('graphqlapi.models')

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

local function space_trigger(old, new, sp, op)
    if new ~= nil then
        -- Insert, Update, Upsert, Replace space
        local new_space = new:tomap({names_only = true})
        if next(new_space.format) and new_space.name then
            models.update_space_models(new_space.name)
        end
    else
        -- Delete space
        local old_space = old:tomap({names_only = true})
        models.remove_model_by_space_name(old_space)
    end
end

local function init()
    set_trigger(space_trigger)
end

local function stop()
    remove_trigger(space_trigger)
end

return {
    init = init,
    stop = stop,
}
