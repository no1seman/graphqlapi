local t = require('luatest')
local g = t.group('types')

require('test.helper.unit')
local types = require('graphqlapi.types')

local function create_space()
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }

    local space = box.space['entity']
    if space == nil and not box.cfg.read_only then
        space = box.schema.space.create('entity', { if_not_exists = true })
        space:format(format)
        return space
    end
end

g.test_remove_all = function()
    types.remove_all()
    t.assert_items_equals(types.list_types(),
        {
            'add_space_input_object',
            'add_space_object',
            'add',
            'bare',
            'boolean',
            'directive',
            'enum',
            'float',
            'get_env',
            'id',
            'include',
            'inputObject',
            'int',
            'interface',
            'is_invalid',
            'list_types',
            'list',
            'long',
            'mapper',
            'nonNull',
            'nullable',
            'object',
            'remove_all',
            'remove_by_space_name',
            'remove_recursive',
            'remove',
            'reset_invalid',
            'resolve',
            'scalar',
            'skip',
            'string',
            'union',
        }
    )
end

g.test_add_remove_space_object = function ()
    local err = select(3, types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    t.assert_equals(type(types['entity']), 'table')
    t.assert_equals(types['entity'].description, 'Entity object')
    t.assert_items_include(types.list_types(), {'entity'})
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)
    t.assert_items_include(types.list_types(), {'entity'})
    types.remove('entity')
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)
    t.assert_equals(types['entity'], nil)
    space:drop()
end

g.test_add_remove_space_input_object = function ()
    local err = select(3, types.add_space_input_object({
        name = 'input_entity',
        description = 'entity input object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = create_space()

    types.add_space_input_object({
        name = 'input_entity',
        description = 'Entity input object',
        space = 'entity',
    })

    t.assert_equals(type(types['input_entity']), 'table')
    t.assert_equals(types['input_entity'].description, 'Entity input object')
    t.assert_items_include(types.list_types(), {'input_entity'})
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)
    t.assert_items_include(types.list_types(), {'input_entity'})
    types.remove('input_entity')
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)
    t.assert_equals(types['input_entity'], nil)
    space:drop()
end

g.test_remove_internal_type = function()
    local err = select(2, types.remove('list'))
    t.assert_equals(err.err, "can't remove internal type")
    err = select(2, types.remove_recursive('list'))
    t.assert_equals(err.err, "can't remove internal type")
end

g.test_remove_by_space_name = function()
    local space = create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })
    t.assert_items_include(types.list_types(), {'entity'})
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)

    types.add_space_input_object({
        name = 'input_entity',
        description = 'Entity input object',
        space = 'entity',
    })

    t.assert_equals(type(types['input_entity']), 'table')
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)

    types.remove_by_space_name(space.name)
    t.assert_equals(types['entity'], nil)
    t.assert_equals(types['input_entity'], nil)
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)
    space:drop()
end

g.test_add_type = function()
    types.add(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE'
        }
    }), 'SpaceIndexType')

    t.assert_equals(type(types['SpaceIndexType']), 'table')

    types.remove('SpaceIndexType')
    t.assert_equals(types['SpaceIndexType'], nil)

    types.add(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE'
        }
    }))

    t.assert_equals(type(types['SpaceIndexType']), 'table')

    types.remove('SpaceIndexType')
    t.assert_equals(types['SpaceIndexType'], nil)
end

g.test_remove_recursive = function()
    types.add(types.enum({
        name = 'SpaceEngine',
        description = 'Space engine',
        values = {
            memtx = 'memtx',
            vinyl = 'vinyl',
            blackhole = 'blackhole',
            sysview = 'sysview',
            service = 'service'
        }
    }))

    t.assert_equals(type(types['SpaceEngine']), 'table')

    types.add(types.object({
        name = 'SpaceInfo',
        description = 'Space info',
        fields = {
            engine = types.SpaceEngine,
        }
    }))

    t.assert_equals(type(types['SpaceInfo']), 'table')

    types.remove_recursive('SpaceEngine')

    t.assert_equals(types['SpaceEngine'], nil)
    t.assert_equals(types['SpaceInfo'], nil)
end
