local t = require('luatest')
local g = t.group('utils')

require('test.helper.unit')
local utils = require('graphqlapi.utils')

g.test_diff = function()
    local res = utils.diff({['a'] = true, ['c'] = true}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
    res = utils.diff({}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
end

g.test_merge = function()
    local res = utils.merge({}, {a = 'a', b = 'b'})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge({a = 'a', b = 'b'}, {})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge({a = 'a', b = 'b'}, {c = 'c', d = 'd'})
    t.assert_items_equals(res, {a = 'a', b = 'b', c = 'c', d = 'd'})
end

g.test_value_in = function()
    t.assert_equals(utils.value_in(nil, {}), false)
    t.assert_equals(utils.value_in(1, {2, 3, 4}), false)
    t.assert_equals(utils.value_in('1', {1, 2}), false)
    t.assert_equals(utils.value_in('1', {'2', '1'}), true)
end

g.test_is_string_array = function()
    t.assert_equals(utils.is_string_array(nil), false)
    t.assert_equals(utils.is_string_array('a'), false)
    t.assert_equals(utils.is_string_array({1, 'a'}), false)
    t.assert_equals(utils.is_string_array({'a', {'b'}}), false)
    t.assert_equals(utils.is_string_array({'a', 'b'}), true)
end
