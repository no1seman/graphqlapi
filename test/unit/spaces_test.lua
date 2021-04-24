local t = require('luatest')
local g = t.group('spaces')

local fiber = require('fiber')

local test_helper = require('test.helper.unit')
local spaces = require('graphqlapi.spaces')
local helpers = require('graphqlapi.helpers')

local triggers_number = function()
    return #box.space._space:on_replace()
end

g.test_init_stop = function()
    spaces.init()
    t.assert_equals(triggers_number(), 1)
    spaces.init()
    t.assert_equals(triggers_number(), 1)
    spaces.stop()
    t.assert_equals(triggers_number(), 0)
    spaces.stop()
    t.assert_equals(triggers_number(), 0)

    local custom_trigger = function()
    end

    box.space._space:on_replace(custom_trigger)
    t.assert_equals(triggers_number(), 1)
    spaces.init()
    t.assert_equals(triggers_number(), 2)
    spaces.stop()
    t.assert_equals(triggers_number(), 1)
    t.assert_equals(box.space._space:on_replace()[1], custom_trigger)
    box.space._space:on_replace(nil, custom_trigger)
    t.assert_equals(triggers_number(), 0)
end

g.test_space_trigger = function()
    spaces.init()
    local space = test_helper.create_space()
    t.assert_equals(triggers_number(), 1)

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_updater' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_updater')

    space:drop()
    spaces.stop()
end

g.test_updater_init = function()
    spaces.init()
    helpers.update_lists = nil
    local space = test_helper.create_space()

    local fiber_name
    for _, f in pairs(fiber.info()) do
        if f.name == 'gql_updater' then
            fiber_name = f.name
        end
    end

    t.assert_equals(fiber_name, 'gql_updater')

    space:drop()
    spaces.stop()
end