local t = require('luatest')
local g = t.group('operations')

local test_helper = require('test.helper')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')

g.before_each = function()
    types.remove_all()
    operations.remove_all()
end

g.after_each = function()
    types.remove_all()
    operations.remove_all()
end

g.test_add_remove_query = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'models.entity.entity_get'
    })

    t.assert_equals(type(operations.get_queries()['entity']), 'table')
    t.assert_equals(operations.get_queries()['entity'].description, 'Get entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_queries(), {'entity'})

    operations.remove_query('entity')

    t.assert_equals(operations.get_queries()['entity'], nil)

    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)
end

g.test_add_remove_query_with_prefix = function()
    operations.add_queries_prefix('test', 'Simple prefix test')

    t.assert_items_equals(operations.get_queries()['test'].resolve(), {})

    t.assert_equals(type(operations.get_queries()['test']), 'table')
    t.assert_equals(operations.get_queries()['test'].description, 'Simple prefix test')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.add_query({
        prefix = 'test',
        name = 'entity_1',
        doc = 'Get entity 1',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'models.entity.entity_1_get'
    })

    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.add_query({
        prefix = 'test',
        name = 'entity_2',
        doc = 'Get entity 2',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'models.entity.entity_2_get',
    })

    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_1'].description, 'Get entity 1')
    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_queries(), {'test.entity_1', 'test.entity_2'})

    operations.remove_query('entity_1', 'test')
    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity_2'].description, 'Get entity 2')
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.remove_query_prefix('test')
    t.assert_equals(operations.get_queries()['test'], nil)
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_error_msg_content_equals(
        'No such query prefix test1',
        operations.add_query,
        {
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Get entity 2',
            args = {
                entity_id = types.long
            },
            kind = types.string,
            callback = 'models.entity.entity_2_get',
        }
    )
end

g.test_add_remove_mutation = function()
    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'models.entity.entity_set'
    })
    t.assert_equals(type(operations.get_mutations()['entity']), 'table')
    t.assert_equals(operations.get_mutations()['entity'].description, 'Mutate entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_mutations(), {'entity'})

    operations.remove_mutation('entity')
    t.assert_equals(operations.get_mutations()['entity'], nil)

    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)
end

g.test_add_remove_mutation_with_prefix = function()
    operations.add_mutations_prefix('test', 'Simple prefix test')

    t.assert_equals(type(operations.get_mutations()['test']), 'table')
    t.assert_equals(operations.get_mutations()['test'].description, 'Simple prefix test')
    t.assert_equals(operations.get_mutations()['test'].resolve(), {})
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.add_mutation({
        prefix = 'test',
        name = 'entity_1',
        doc = 'Mutate entity 1',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'models.entity.entity_1_set'
    })

    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_1'].description, 'Mutate entity 1')
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.add_mutation({
        prefix = 'test',
        name = 'entity_2',
        doc = 'Mutate entity 2',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'models.entity.entity_2_set'
    })

    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_1']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_1'].description, 'Mutate entity 1')
    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_2'].description, 'Mutate entity 2')
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_mutations(), {'test.entity_1', 'test.entity_2'})

    operations.remove_mutation('entity_1', 'test')
    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity_2']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity_2'].description, 'Mutate entity 2')
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    operations.remove_mutation_prefix('test')
    t.assert_equals(operations.get_mutations()['test'], nil)
    t.assert_equals(operations.is_invalid(), true)
    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)


    t.assert_error_msg_content_equals(
        'No such mutation prefix test1',
        operations.add_mutation,
        {
            prefix = 'test1',
            name = 'entity_2',
            doc = 'Mutate entity 2',
            args = {
                name = types.long,
            },
            kind = types.string,
            callback = 'models.entity.entity_2_set'
        }
    )
end

g.test_operations_safety = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'models.entity.entity_get'
    })

    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'models.entity.entity_set'
    })

    operations.remove_all()
    t.assert_items_equals(operations.get_queries(), {})
    t.assert_items_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.list_queries(), {})
    t.assert_items_equals(operations.list_mutations(), {})

    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'models.entity.entity_get'
    })

    operations.add_mutation({
        name = 'entity',
        doc = 'Mutate entity',
        args = {
            name = types.long,
        },
        kind = types.string,
        callback = 'models.entity.entity_set'
    })

    operations.stop()
    t.assert_equals(operations.get_queries(), {})
    t.assert_equals(operations.get_mutations(), {})
    t.assert_items_equals(operations.list_queries(), {})
    t.assert_items_equals(operations.list_mutations(), {})
end

g.test_on_resolve_trigger = function()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'test.unit.operations_test.stub1'
    })

    local res = operations.get_queries()['entity'].resolve()
    t.assert_equals(res, "Operations test")

    local on_resolve_trigger1 = function(operation, field_name)
        error(operation ..' '.. field_name, 0)
    end

    operations.on_resolve(on_resolve_trigger1, nil)
    t.assert_error_msg_contains('query entity', operations.get_queries()['entity'].resolve)

    operations.stop()

    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'test.unit.operations_test.stub2'
    })

    local on_resolve_trigger2 = function(_, field_name)
        return field_name
    end

    operations.on_resolve(on_resolve_trigger2, nil)
    t.assert_error_msg_contains('callback error', operations.get_queries()['entity'].resolve)

    operations.on_resolve(nil, on_resolve_trigger2)
    t.assert_error_msg_contains('callback error', operations.get_queries()['entity'].resolve)
    operations.stop()

end

g.test_add_space_query = function()
    -- test add_space_query() without prefix
    local space = test_helper.create_space()
    operations.add_space_query({
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "models.entity.entity_get"
    })
    t.assert_equals(type(operations.get_queries()['entity']), 'table')
    t.assert_equals(operations.get_queries()['entity'].description, 'Get entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_queries(), {'entity'})

    operations.remove_operations_by_space_name('entity')
    t.assert_equals(operations.is_invalid(), true)

    t.assert_equals(operations.get_queries()['entity'], nil)
    space:drop()

    -- test add_space_query() with prefix
    space = test_helper.create_space()
    operations.add_queries_prefix('test', 'Simple prefix test')

    operations.add_space_query({
        prefix = 'test',
        space = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "models.entity.entity_get"
    })

    t.assert_equals(type(operations.get_queries()['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity'].description, 'Get entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_queries(), {'test.entity'})

    operations.remove_operations_by_space_name('entity')
    t.assert_equals(operations.get_queries()['test'].kind.fields['entity'], nil)
    t.assert_equals(operations.is_invalid(), true)

    operations.remove_query_prefix('test')
    t.assert_equals(operations.get_queries()['test'], nil)

    space:drop()

    -- test add_space_query() with unexisting space
    t.assert_error_msg_contains(
        'space \'entity\' doesn\'t exists',
        operations.add_space_query,
        {
            prefix = 'test',
            space = 'entity',
            doc = 'Get entity',
            args = {
                entity_id = types.int.nonNull
            },
            callback = "models.entity.entity_get"
        }
    )
end

g.test_add_space_mutation = function()
    -- test add_space_mutation() without prefix
    local space = test_helper.create_space()
    operations.add_space_mutation({
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "models.entity.entity_set"
    })
    t.assert_equals(type(operations.get_mutations()['entity']), 'table')
    t.assert_equals(operations.get_mutations()['entity'].description, 'Mutate entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_mutations(), {'entity'})

    operations.remove_operations_by_space_name('entity')
    t.assert_equals(operations.get_mutations()['entity'], nil)
    t.assert_equals(operations.is_invalid(), true)

    space:drop()

    -- test add_space_mutation() with prefix
    space = test_helper.create_space()
    operations.add_mutations_prefix('test', 'Simple prefix test')
    operations.add_space_mutation({
        prefix = 'test',
        space = 'entity',
        doc = 'Mutate entity',
        args = {
            entity_id = types.int.nonNull
        },
        callback = "models.entity.entity_set"
    })

    t.assert_equals(type(operations.get_mutations()['test'].kind.fields['entity']), 'table')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity'].description, 'Mutate entity')
    t.assert_equals(operations.is_invalid(), true)

    operations.reset_invalid()
    t.assert_equals(operations.is_invalid(), false)

    t.assert_items_equals(operations.list_mutations(), {'test.entity'})

    operations.remove_operations_by_space_name('entity')
    t.assert_equals(operations.get_mutations()['test'].kind.fields['entity'], nil)
    t.assert_equals(operations.is_invalid(), true)

    operations.remove_mutation_prefix('test')
    t.assert_equals(operations.get_mutations()['test'], nil)

    space:drop()

    -- test add_space_mutation() with unexisting space
    t.assert_error_msg_contains(
        'space \'entity\' doesn\'t exists',
        operations.add_space_mutation,
        {
            prefix = 'test',
            space = 'entity',
            doc = 'Mutate entity',
            args = {
                entity_id = types.int.nonNull
            },
            callback = "models.entity.entity_set"
        }
    )
end

local function stub1()
    return 'Operations test'
end

local function stub2()
    return nil, 'callback error'
end

return {
    stub1 = stub1,
    stub2 = stub2,
}
