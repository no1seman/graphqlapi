local t = require('luatest')
local g = t.group('spaces')

require('test.helper.unit')
local spaces = require('graphqlapi.spaces')

g.test_init_stop = function()
    local triggers_number = function()
        return #box.space._space:on_replace()
    end

    spaces.init()
    t.assert_equals(triggers_number(), 1)
    spaces.init()
    t.assert_equals(triggers_number(), 1)
    spaces.stop()
    t.assert_equals(triggers_number(), 0)
    spaces.stop()
    t.assert_equals(triggers_number(), 0)
end
