local t = require('luatest')
local g = t.group('vars')

require('test.helper')
local vars = require('graphqlapi.vars').new('vars_test')

vars:new('test_nil', nil)
vars:new('test_not_nil', 'not_nil')

g.test_vars = function()
    t.assert_equals(vars.test_nil, nil)
    t.assert_equals(vars.test_not_nil, 'not_nil')
    vars.test_nil = {}
    t.assert_equals(vars.test_nil, {})
    vars.test_nil = nil
    t.assert_equals(vars.test_nil, nil)
end
