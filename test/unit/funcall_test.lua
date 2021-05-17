local t = require('luatest')
local g = t.group('funcall')

require('test.helper')
local funcall = require('graphqlapi.funcall')

g.test_call = function()
    t.assert_error_msg_contains('attempt to call a nil value', funcall.call(''))
    t.assert_error_msg_contains('attempt to call a nil value', funcall.call('get_entity'))
    t.assert_error_msg_contains('attempt to call a nil value', funcall.call('entity.get_entity'))
    t.assert_error_msg_contains('attempt to call a nil value', funcall.call('models.entity.get_entity'))
    t.assert_error_msg_contains('attempt to call a nil value', funcall.call('graphqlapi.funcall.get_entity'))
end
