local t = require('luatest')
local g = t.group('utils')

require('test.helper')
local utils = require('graphqlapi.utils')

g.test_value_in = function()
    t.assert_equals(utils.value_in(nil, {}), false)
    t.assert_equals(utils.value_in(1, {2, 3, 4}), false)
    t.assert_equals(utils.value_in('1', {1, 2}), false)
    t.assert_equals(utils.value_in('1', {'2', '1'}), true)
end

g.test_diff_maps = function()
    local res = utils.diff_maps({['a'] = true, ['c'] = true}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
    res = utils.diff_maps({}, {['a'] = true, ['b'] = true}, {'a', 'd'})
    t.assert_items_equals(res, {'a', 'd', 'b'})
end

g.test_diff_arrays = function()
    local res = utils.diff_arrays({}, {})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({}, {'entity1'})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {'entity2'})
    t.assert_items_equals(res, {})
    res = utils.diff_arrays({'entity1'}, {'entity1'})
    t.assert_items_equals(res, {'entity1'})
end

g.test_merge_maps = function()
    local res = utils.merge_maps({}, {})
    t.assert_items_equals(res, {})

    res = utils.merge_maps({a = 'a', b = 'b'}, {})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({}, {a = 'a', b = 'b'})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({a = 'a', b = 'b'}, {})
    t.assert_items_equals(res, {a = 'a', b = 'b'})

    res = utils.merge_maps({a = 'a', b = 'b'}, {c = 'c', d = 'd'})
    t.assert_items_equals(res, {a = 'a', b = 'b', c = 'c', d = 'd'})

    res = utils.merge_maps({a = 'a', b = 'b1', c = 'c2'}, {b = 'b2', c = 'c1', d = 'd'})
    t.assert_items_equals(res, {a = 'a', b = 'b2', c = 'c1', d = 'd'})

    res = utils.merge_maps(
        {},
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},},
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},},
        {['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},}
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
        space2 = {name = "space2", prefix = "spaces", schema = "default"},
    })

    res = utils.merge_maps(
        {
            ['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},
            ['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},
        },
        {
            ['space2'] = {name = 'space2', schema = 'default', prefix = 'spaces'},
            ['space1'] = {name = 'space1', schema = 'default', prefix = 'spaces'},
        }
    )
    t.assert_items_equals(res, {
        space1 = {name = "space1", prefix = "spaces", schema = "default"},
        space2 = {name = "space2", prefix = "spaces", schema = "default"},
    })
end

g.test_merge_arrays = function()
    local res = utils.merge_arrays({}, {})
    t.assert_items_equals(res, {})

    res = utils.merge_arrays({1}, {})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({}, {1})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({1}, {1})
    t.assert_items_equals(res, {1})

    res = utils.merge_arrays({1, 9, 3, 4, 5}, {6, 3, 5, 9, 10})
    t.assert_items_equals(res, {1, 9, 3, 4, 5, 6, 10})
end

g.test_concat_arrays = function()
    local res = utils.concat_arrays()
    t.assert_items_equals(res, {})

    res = utils.concat_arrays(nil, {{arr1 = 'val1'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}})

    res = utils.concat_arrays({}, {})
    t.assert_items_equals(res, {})

    res = utils.concat_arrays({{arr1 = 'val1'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}})

    res = utils.concat_arrays({{arr1 = 'val1'}}, {{arr2 = 'val2'}})
    t.assert_items_equals(res, {{arr1 = 'val1'}, {arr2 = 'val2'}})
end

g.test_is_string_array = function()
    t.assert_equals(utils.is_string_array(nil), false)
    t.assert_equals(utils.is_string_array('a'), false)
    t.assert_equals(utils.is_string_array({1, 'a'}), false)
    t.assert_equals(utils.is_string_array({'a', {'b'}}), false)
    t.assert_equals(utils.is_string_array({'a', 'b'}), true)
end

g.test_dedup_array = function ()
    t.assert_equals(utils.dedup_array(nil), {})
    t.assert_equals(utils.dedup_array({}), {})
    t.assert_equals(utils.dedup_array({'1'}), {'1'})
    t.assert_equals(utils.dedup_array({'1', '2'}), {'1', '2'})
    t.assert_equals(utils.dedup_array({'1', '2', '1'}), {'2', '1'})
    t.assert_equals(utils.dedup_array({'1', '2', '1', '2'}), {'1', '2'})
    t.assert_equals(utils.dedup_array({'1', '2', '1', '2', '1'}), {'2', '1'})
end

g.test_is_map = function()
    t.assert_equals(utils.is_map(nil), false)
    t.assert_equals(utils.is_map({'1'}), false)
    t.assert_equals(utils.is_map({'1', '2', '3'}), false)
    t.assert_equals(utils.is_map({['1'] = 1, ['2'] = 2, 3}), false)
    t.assert_equals(utils.is_map({0, ['1'] = 1, ['2'] = 2}), false)
    t.assert_equals(utils.is_map({['1'] = 1, ['2'] = 2, ['3'] = 3}), true)
    t.assert_equals(utils.is_map({['1'] = {1}, ['2'] = {2}, ['3'] = {3}}), true)
end