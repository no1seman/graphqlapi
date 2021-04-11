local t = require('luatest')
local g = t.group('operations')

require('test.helper.unit')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')

g.test_add_remove_query = function()
    operations.remove_all()
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
    operations.remove_all()
    operations.add_query_prefix('test', 'Simple prefix test')

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
        callback = 'models.entity.entity_2_get'
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
end

g.test_add_remove_mutation = function()
    operations.remove_all()
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
    operations.remove_all()
    operations.add_mutation_prefix('test', 'Simple prefix test')

    t.assert_equals(type(operations.get_mutations()['test']), 'table')
    t.assert_equals(operations.get_mutations()['test'].description, 'Simple prefix test')
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
end

g.test_operations_safety = function()
    operations.remove_all()
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
    operations.remove_all()
    operations.add_query({
        name = 'entity',
        doc = 'Get entity',
        args = {
            entity_id = types.long
        },
        kind = types.string,
        callback = 'test.unit.operations_test.stub'
    })

    local res = operations.get_queries()['entity'].resolve()
    t.assert_equals(res, "Operations test")

    local on_resolve_trigger = function(operation, field_name)
        error(operation ..' '.. field_name, 0)
    end

    operations.on_resolve(on_resolve_trigger, nil)
    t.assert_error_msg_contains('query entity', operations.get_queries()['entity'].resolve)

    operations.remove_all()
end

local function stub()
    return 'Operations test'
end

return {
    stub = stub,
}
