local t = require('luatest')
local g = t.group('helpers')

require('test.helper.unit')
local helpers = require('graphqlapi.helpers')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')

g.before_each = function()
    operations.remove_all()
    types.remove_all()
    helpers.stop()
end

g.after_each = function()
    operations.remove_all()
    types.remove_all()
    helpers.stop()
end

local function assert_types_absent(types_list)
    for _, _type in ipairs(types_list) do
        t.assert_equals(types[_type], nil)
    end
end

local function assert_queries_absent(queries_list)
    for _, _query in ipairs(queries_list) do
        t.assert_equals(operations.get_queries()[_query], nil)
    end
end

local function assert_mutations_absent(mutations_list)
    for _, _mutation in ipairs(mutations_list) do
        t.assert_equals(operations.get_mutations()[_mutation], nil)
    end
end

local function assert_enum_include(enum_name, space_list)
    if not space_list or space_list == {} or not types[enum_name].values or types[enum_name].values == {} then
        return
    end
    for _, search_value in ipairs(space_list) do
        local found = false
        for key in pairs(types[enum_name].values) do
            if search_value == key then
                found = true
            end
        end
        t.assert_equals(found, true, string.format('\'%s\' not found in \'%s\' enum', search_value, enum_name))
    end
end

local function assert_enum_absent(enum_name, space_list)
    if not space_list or space_list == {} or not types[enum_name].values or types[enum_name].values == {} then
        return
    end
    for _, search_value in ipairs(space_list) do
        local found = false
        for key in pairs(types[enum_name].values) do
            if search_value == key then
                found = true
            end
        end
        t.assert_equals(found, false, string.format('\'%s\' not found in \'%s\' enum', search_value, enum_name))
    end
end

local function create_space(space_name)
    return box.schema.space.create(space_name, { if_not_exists = true })
end

g.test_init_stop = function()
    local types_list =
    {
        'SpaceCkConstraint',
        'SpaceCkConstraintInput',
        'SpaceDropNames',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldInput',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexDimension',
        'SpaceIndexInput',
        'SpaceIndexPart',
        'SpaceIndexPartInput',
        'SpaceIndexType',
        'SpaceInfo',
        'SpaceInfoNames',
        'SpaceTruncateNames',
        'SpaceUpdateNames',
    }
    local queries_list = {'space_info'}
    local mutations_list =
    {
        'space_drop',
        'space_truncate',
        'space_update',
        'space_create'
    }

    helpers.init()

    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_queries(), queries_list)
    t.assert_items_equals(operations.list_mutations(), mutations_list)
    t.assert_items_equals(types['SpaceInfoNames'].values, {})
    t.assert_items_equals(types['SpaceDropNames'].values, {})
    t.assert_items_equals(types['SpaceTruncateNames'].values, {})
    t.assert_items_equals(types['SpaceUpdateNames'].values, {})
    helpers.stop()

    assert_types_absent(types_list)
    assert_queries_absent(queries_list)
    assert_mutations_absent(mutations_list)

    local good_space = create_space('good_space')
    helpers.init()
    assert_enum_include('SpaceInfoNames', {'good_space'})
    assert_enum_include('SpaceDropNames', {'good_space'})
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    assert_enum_include('SpaceUpdateNames', {'good_space'})
    helpers.stop()
    good_space:drop()

    helpers.init()
    good_space = create_space('good_space')
    helpers.update_lists()
    assert_enum_include('SpaceInfoNames', {'good_space'})
    assert_enum_include('SpaceDropNames', {'good_space'})
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    assert_enum_include('SpaceUpdateNames', {'good_space'})
    helpers.stop()
    good_space:drop()
end

g.test_space_info = function()
    local types_list = {
        'SpaceCkConstraint',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexDimension',
        'SpaceIndexPart',
        'SpaceIndexType',
        'SpaceInfo',
        'SpaceInfoNames',
    }

    local queries_list = {'space_info'}

    helpers.space_info_init()
    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_queries(), queries_list)
    helpers.space_info_remove()
    assert_types_absent(types_list)
    assert_queries_absent(queries_list)

    helpers.space_info_init({'good_space'}, {'bad_space'})
    t.assert_items_equals(types['SpaceInfoNames'].values, {})
    local bad_space = create_space('bad_space')
    t.assert_items_equals(types['SpaceInfoNames'].values, {})
    local good_space = create_space('good_space')
    helpers.update_lists()
    assert_enum_include('SpaceInfoNames', {'good_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_info_remove()

    good_space = create_space('good_space')
    bad_space = create_space('bad_space')
    helpers.space_info_init({'good_space'}, {'bad_space'})
    assert_enum_include('SpaceInfoNames', {'good_space'})
    assert_enum_absent('SpaceInfoNames', {'bad_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_info_remove()
end

g.test_space_drop = function()
    local types_list = {
        'SpaceCkConstraint',
        'SpaceDropNames',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexDimension',
        'SpaceIndexPart',
        'SpaceIndexType',
        'SpaceInfo',
    }

    local mutations_list = {'space_drop'}

    helpers.space_drop_init()
    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_mutations(), mutations_list)
    helpers.space_drop_remove()
    assert_types_absent(types_list)
    assert_mutations_absent(mutations_list)

    helpers.space_drop_init({'good_space'}, {'bad_space'})
    t.assert_items_equals(types['SpaceDropNames'].values, {})
    local bad_space = create_space('bad_space')
    t.assert_items_equals(types['SpaceDropNames'].values, {})
    local good_space = create_space('good_space')
    helpers.update_lists()
    assert_enum_include('SpaceDropNames', {'good_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_drop_remove()

    good_space = create_space('good_space')
    bad_space = create_space('bad_space')
    helpers.space_drop_init({'good_space'}, {'bad_space'})
    assert_enum_include('SpaceDropNames', {'good_space'})
    assert_enum_absent('SpaceDropNames', {'bad_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_drop_remove()
end

g.test_space_truncate = function()
    local types_list = {
        'SpaceCkConstraint',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexDimension',
        'SpaceIndexPart',
        'SpaceIndexType',
        'SpaceInfo',
        'SpaceTruncateNames',
    }

    local mutations_list = {'space_truncate'}

    helpers.space_truncate_init()
    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_mutations(), mutations_list)
    helpers.space_truncate_remove()
    assert_types_absent(types_list)
    assert_mutations_absent(mutations_list)

    helpers.space_truncate_init({'good_space'}, {'bad_space'})
    t.assert_items_equals(types['SpaceTruncateNames'].values, {})
    local bad_space = create_space('bad_space')
    t.assert_items_equals(types['SpaceTruncateNames'].values, {})
    local good_space = create_space('good_space')
    helpers.update_lists()
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_truncate_remove()

    good_space = create_space('good_space')
    bad_space = create_space('bad_space')
    helpers.space_truncate_init({'good_space'}, {'bad_space'})
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    assert_enum_absent('SpaceTruncateNames', {'bad_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_truncate_remove()
end

g.test_space_update = function()
    local types_list = {
        'SpaceCkConstraint',
        'SpaceCkConstraintInput',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldInput',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexDimension',
        'SpaceIndexInput',
        'SpaceIndexPart',
        'SpaceIndexPartInput',
        'SpaceIndexType',
        'SpaceInfo',
        'SpaceUpdateNames',
    }

    local mutations_list = {'space_update'}

    helpers.space_update_init()
    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_mutations(), mutations_list)
    helpers.space_update_remove()
    assert_types_absent(types_list)
    assert_mutations_absent(mutations_list)

        helpers.space_truncate_init({'good_space'}, {'bad_space'})
    t.assert_items_equals(types['SpaceTruncateNames'].values, {})
    local bad_space = create_space('bad_space')
    t.assert_items_equals(types['SpaceTruncateNames'].values, {})
    local good_space = create_space('good_space')
    helpers.update_lists()
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_truncate_remove()

    good_space = create_space('good_space')
    bad_space = create_space('bad_space')
    helpers.space_truncate_init({'good_space'}, {'bad_space'})
    assert_enum_include('SpaceTruncateNames', {'good_space'})
    assert_enum_absent('SpaceTruncateNames', {'bad_space'})
    good_space:drop()
    bad_space:drop()
    helpers.space_truncate_remove()
end

g.test_space_create = function()
    local types_list = {
        'SpaceCkConstraint',
        'SpaceCkConstraintInput',
        'SpaceEngine',
        'SpaceField',
        'SpaceFieldInput',
        'SpaceFieldType',
        'SpaceIndex',
        'SpaceIndexInput',
        'SpaceIndexPart',
        'SpaceIndexPartInput',
        'SpaceIndexType',
        'SpaceInfo',
    }

    local mutations_list = {'space_create'}

    helpers.space_create_init()
    t.assert_items_include(types.list_types(), types_list)
    t.assert_items_equals(operations.list_mutations(), mutations_list)
    helpers.space_create_remove()
    assert_types_absent(types_list)
    assert_mutations_absent(mutations_list)
end
