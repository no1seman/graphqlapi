local t = require('luatest')
local g = t.group('types')

local test_helper = require('test.helper')
local types = require('graphqlapi.types')
local spaces_helpers = require('graphqlapi.helpers.spaces')
local operations = require('graphqlapi.operations')

-- local json = require('json')

-- local json_cfg = {
--     encode_use_tostring = true,
--     encode_deep_as_nil = true,
--     encode_max_depth = 5,
--     encode_invalid_as_nil = true
-- }

g.before_all(function()
    types.remove_all()
end)

g.after_each(function()
    types.remove_all()
end)

g.test_remove_all = function()
    t.assert_items_equals(types.list_types(), {})
    t.assert_items_equals(types.list_types('Spaces'), {})
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

    types.add(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE'
        }
    }), 'Spaces')

    t.assert_items_equals(types.schemas(), {'spaces', 'default'})

    t.assert_items_equals(types.list_types(), {'SpaceIndexType'})
    t.assert_items_equals(types.list_types('Spaces'), {'SpaceIndexType'})

    types.remove_all()
    t.assert_items_equals(types.list_types(), {})
    t.assert_items_equals(types.list_types('Spaces'), {})

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

    types.add(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE',
        }
    }), 'Spaces')

    t.assert_items_equals(types.schemas(), {'spaces', 'default'})

    t.assert_items_equals(types.list_types(), {'SpaceIndexType'})
    t.assert_items_equals(types.list_types('Spaces'), {'SpaceIndexType'})

    types.remove_all({schema = box.NULL})
    t.assert_items_equals(types.list_types(), {})

    types.remove_all({schema = 'Spaces'})
    t.assert_items_equals(types.list_types('Spaces'), {})

    local space = test_helper.create_space()

    types.add_space_object({
        space = 'entity',
        name = 'entity',
    })

    types.remove_all({schema = 'default'})

    space:drop()
end

g.test_add_remove_space_object = function ()
    local err = select(3, types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = test_helper.create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })

    t.assert_equals(type(types()['entity']), 'table')
    t.assert_equals(types()['entity'].description, 'Entity object')
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

    space = test_helper.create_space()

    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            instance_alias = types.string,
        }
    })

    t.assert_items_include(types.list_types(), {'entity'})

    t.assert_equals(type(types()['entity'].fields.entity), 'table')
    t.assert_equals(type(types()['entity'].fields.instance_alias), 'table')
    t.assert_equals(type(types()['entity'].fields.entity_id), 'table')
    t.assert_equals(types()['entity'].fields.bucket_id, nil)

    types.remove('entity')
    space:drop()
end

g.test_add_remove_space_input_object = function ()
    local err = select(3, types.add_space_input_object({
        name = 'input_entity',
        description = 'entity input object',
        space = 'entity',
    }))
    t.assert_equals(err.err, "space 'entity' doesn't exists")

    local space = test_helper.create_space()

    types.add_space_input_object({
        name = 'input_entity',
        description = 'Entity input object',
        space = 'entity',
    })

    t.assert_equals(type(types()['input_entity']), 'table')
    t.assert_equals(types()['input_entity'].description, 'Entity input object')
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

    space = test_helper.create_space()
    types.add_space_input_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            instance_alias = types.string,
        }
    })

    t.assert_items_include(types.list_types(), {'entity'})

    t.assert_equals(type(types()['entity'].fields.entity), 'table')
    t.assert_equals(type(types()['entity'].fields.instance_alias), 'table')
    t.assert_equals(type(types()['entity'].fields.entity_id), 'table')
    t.assert_equals(types()['entity'].fields.bucket_id, nil)

    types.remove('entity')
    space:drop()
end

g.test_remove_types_by_space_name = function()
    local space = test_helper.create_space()

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

    t.assert_equals(type(types()['input_entity']), 'table')
    t.assert_equals(types.is_invalid(), true)
    types.reset_invalid()
    t.assert_equals(types.is_invalid(), false)

    types.remove_types_by_space_name('entity')
    t.assert_equals(types()['entity'], nil)
    t.assert_equals(types()['input_entity'], nil)
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
            rtree = 'RTREE',
        }
    }))

    t.assert_equals(type(types()['SpaceIndexType']), 'table')

    types.remove('SpaceIndexType')
    t.assert_equals(types()['SpaceIndexType'], nil)

    types.add(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE',
        }
    }))

    t.assert_equals(type(types()['SpaceIndexType']), 'table')

    types.remove('SpaceIndexType')
    t.assert_equals(types()['SpaceIndexType'], nil)
end


g.test_get_non_leaf_types = function()
    local custom_scalar = types.scalar({
        name = 'CustomInt',
        description = "The `CustomInt` scalar type represents non-fractional signed whole numeric values. " ..
                      "Int can represent values from -(2^31) to 2^31 - 1, inclusive.",
        serialize = function(value)
            return value
        end,
        parseLiteral = function(node)
            return node.value
        end,
        isValueOfTheType = function(_)
            return true
        end,
      })

    local dogCommand = types.enum({
        name = 'DogCommand',
        values = {
            SIT = true,
            DOWN = true,
            HEEL = true,
        }
    })
    t.assert_items_equals(types.get_non_leaf_types(dogCommand), {})

    local pet = types.interface({
        name = 'Pet',
        fields = {
            name = types.string.nonNull,
            nickname = custom_scalar,
            command = dogCommand,
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(pet), {'DogCommand', 'CustomInt'})

    local dog = types.object({
        name = 'Dog',
        interfaces = { pet },
        arguments = { dogCommand },
        fields = {
            name = types.string,
            nickname = types.string,
            barkVolume = types.int,
            doesKnowCommand = {
                kind = types.boolean.nonNull,
                arguments = {
                    dogCommand = dogCommand.nonNull,
                }
            },
            isHouseTrained = {
                kind = types.boolean.nonNull,
                arguments = {
                    atOtherHomes = types.boolean,
                }
            },
            complicatedField = {
                kind = types.boolean,
                interfaces = {pet},
                arguments = {
                    complicatedArgument = types.inputObject({
                        name = 'complicated',
                        fields = {
                            x = types.string,
                            y = types.integer,
                            z = types.inputObject({
                                name = 'alsoComplicated',
                                fields = {
                                    x = types.string,
                                    y = types.integer,
                                }
                            })
                        },
                        interfaces = {pet},
                    })
                }
            }
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(dog),
    {
        'Pet',
        'DogCommand',
        'complicated',
        'alsoComplicated',
        'CustomInt',
    })

    local sentient = types.interface({
        name = 'Sentient',
        fields = {
            name = types.string.nonNull,
            dog = dog,
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(sentient),
    {
        'Pet',
        'Dog',
        'DogCommand',
        'complicated',
        'alsoComplicated',
        'CustomInt',
    })

    local alien = types.object({
        name = 'Alien',
        interfaces = sentient,
        fields = {
            name = types.string.nonNull,
            homePlanet = types.string,
        }
    })

    local human = types.object({
        name = 'Human',
        fields = {
            name = types.string.nonNull,
        }
    })

    local cat = types.object({
        name = 'Cat',
        fields = {
            name = types.string.nonNull,
            nickname = types.string,
            meowVolume = types.int,
        }
    })

    local catOrDog = types.union({
        name = 'CatOrDog',
        types = { cat, dog, }
    })

    local dogOrHuman = types.union({
        name = 'DogOrHuman',
        types = { dog, human, }
    })

    local humanOrAlien = types.union({
        name = 'HumanOrAlien',
        types = { human, alien, }
    })

    local query = types.object({
        name = 'Query',
        fields = {
            dog = {
                kind = dog,
                args = {
                    name = {
                        kind = types.string,
                    }
                }
            },
            cat = cat,
            pet = pet,
            sentient = sentient,
            catOrDog = catOrDog,
            humanOrAlien = humanOrAlien,
            dogOrHuman = dogOrHuman,
        }
    })

    t.assert_items_equals(types.get_non_leaf_types(query),{
        'DogOrHuman',
        'Pet',
        'CatOrDog',
        'Sentient',
        'Dog',
        'DogCommand',
        'complicated',
        'alsoComplicated',
        'Cat',
        'HumanOrAlien',
        'Human',
        'Alien',
        'CustomInt',
    })

    spaces_helpers.init()

    t.assert_items_include(types.get_non_leaf_types(types()['SpaceInfo']),
    {
        'SpaceField',
        'SpaceEngine',
        'SpaceIndex',
        'SpaceIndexPart',
        'SpaceFieldType',
        'SpaceIndexDimension',
        'SpaceCkConstraint',
    })

    t.assert_items_equals(types.get_non_leaf_types(types()['SpaceEngine']), {})

    t.assert_items_equals(types.get_non_leaf_types(types()['SpaceIndexInput']), {
        'SpaceIndexPartInput',
        'SpaceFieldInput',
        'SpaceFieldType',
        'SpaceIndexType',
        'SpaceIndexDimension',
    })

    types.add(types.interface({
        name = 'SpaceInfoInterface',
        fields = {
            name = types.string.nonNull,
            nickname = types.int,
            space = types().SpaceInfo
        }
    }))

    t.assert_items_equals(types.get_non_leaf_types(types()['SpaceInfoInterface']),{
        'SpaceInfo',
        'SpaceField',
        'SpaceEngine',
        'SpaceIndex',
        'SpaceIndexPart',
        'SpaceFieldType',
        'SpaceIndexDimension',
        'SpaceCkConstraint',
    })

    local space_queries_types = {
        'SpaceInfo',
        'SpaceField',
        'SpaceEngine',
        'SpaceIndex',
        'SpaceIndexPart',
        'SpaceFieldType',
        'SpaceIndexDimension',
        'SpaceCkConstraint',
        'SpaceInfoNames',
    }

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_queries()),
        space_queries_types
    )

    local space_mutations_types = {
        'SpaceTruncateResult',
        'SpaceTruncateNames',
        'SpaceInfo',
        'SpaceField',
        'SpaceIndex',
        'SpaceIndexPart',
        'SpaceCkConstraint',
        'SpaceEngine',
        'SpaceCkConstraintInput',
        'SpaceIndexInput',
        'SpaceIndexPartInput',
        'SpaceFieldInput',
        'SpaceFieldType',
        'SpaceIndexType',
        'SpaceIndexDimension',
        'SpaceUpdateNames',
        'SpaceDropNames',
    }

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_mutations()),
        space_mutations_types
    )

    spaces_helpers.stop()

    spaces_helpers.init({prefix = 'spaces'})

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_queries()['spaces']),
        space_queries_types
    )

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_queries()['spaces'].kind.fields['space_info']),
        space_queries_types
    )

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_mutations()['spaces']),
        space_mutations_types
    )

    t.assert_items_equals(
        types.get_non_leaf_types(operations.get_mutations()['spaces'].kind.fields['space_truncate']),
        {'SpaceTruncateResult', 'SpaceTruncateNames'}
    )

    spaces_helpers.stop()
end

g.test_remove_recursive = function()
    spaces_helpers.init()

    t.assert_equals(type(types()['SpaceEngine']), 'table')
    t.assert_equals(type(types()['SpaceInfo']), 'table')

    local removed = types.remove_recursive('SpaceEngine')
    t.assert_items_equals(removed, {default = { 'SpaceEngine', 'SpaceInfo'}})
    t.assert_equals(types()['SpaceEngine'], nil)
    t.assert_equals(types()['SpaceInfo'], nil)

    spaces_helpers.stop()
    spaces_helpers.init()

    local defaults = require('graphqlapi.defaults')

    local temp = defaults.REMOVE_RECURSIVE_MAX_DEPTH
    defaults.REMOVE_RECURSIVE_MAX_DEPTH = 1

    t.assert_equals(defaults.REMOVE_RECURSIVE_MAX_DEPTH, 2)

    removed = types.remove_recursive('SpaceEngine')

    defaults.REMOVE_RECURSIVE_MAX_DEPTH = temp

    t.assert_items_equals(removed, {default = { 'SpaceEngine', "SpaceInfo"}})

    t.assert_equals(types()['SpaceEngine'], nil)
    t.assert_equals(types()['SpaceInfo'], nil)

    spaces_helpers.stop()
end
