local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local spaceapi = require('graphqlapi.spaceapi')

local function space_query_types_init()
    types.add_type(types.enum({
        name = 'SpaceFieldType',
        description = 'Space field type enum',
        values = {
            unsigned = 'unsigned',
            string = 'string',
            varbinary = 'varbinary',
            integer = 'integer',
            number = 'number',
            double = 'double',
            boolean = 'boolean',
            decimal = 'decimal',
            map = 'map',
            array = 'array',
            scalar = 'scalar'
        }
    }), 'SpaceFieldType')

    types.add_type(types.enum({
        name = 'SpaceEngine',
        description = 'Space engine',
        values = {
            memtx = 'memtx',
            vinyl = 'vinyl',
            blackhole = 'blackhole',
            sysview = 'sysview',
            service = 'service'
        }
    }), 'SpaceEngine')

    types.add_type(types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE'
        }
    }), 'SpaceIndexType')

    types.add_type(types.enum({
        name = 'SpaceIndexDimension',
        description = 'Space index dimension',
        values = {euclid = 'euclid', manhattan = 'manhattan'}
    }), 'SpaceIndexDimension')

    types.add_type(types.object({
        name = 'SpaceField',
        description = 'Space field',
        fields = {
            name = types.string,
            type = types.SpaceFieldType,
            is_nullable = types.boolean
        }
    }), 'SpaceField')

    types.add_type(types.object({
        name = 'SpaceIndexPart',
        description = 'Space index part',
        fields = {
            type = types.SpaceFieldType,
            fieldno = types.int,
            is_nullable = types.boolean
        }
    }), 'SpaceIndexPart')

    types.add_type(types.object({
        name = 'SpaceIndex',
        description = 'Space Index',
        fields = {
            name = types.string,
            type = types.SpaceIndexType,
            id = types.int,
            unique = types.boolean,
            if_not_exists = types.boolean,
            parts = types.list(types.SpaceIndexPart),
            dimension = types.int,
            distance = types.SpaceIndexDimension,
            bloom_fpr = types.float,
            page_size = types.int,
            range_size = types.int,
            run_count_per_level = types.int,
            run_size_ratio = types.float,
            size = types.long,
            len = types.long
        }
    }), 'SpaceIndex')

    types.add_type(types.object({
        name = 'SpaceCkConstraint',
        description = 'Space check constraint',
        fields = {
            name = types.string,
            is_enabled = types.boolean,
            space_id = types.int,
            expr = types.string
        }
    }), 'SpaceCkConstraint')

    types.add_type(types.enum({
        name = 'SpaceName',
        description = 'Spaces name enum',
        values = spaceapi.list_spaces()
    }), 'SpaceName')

    types.add_type(types.object({
        name = 'Space',
        description = 'Space',
        fields = {
            format = types.list(types.SpaceField),
            id = types.int,
            name = types.string,
            engine = types.SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            size = types.long,
            len = types.long,
            user = types.string,
            index = types.list(types.SpaceIndex),
            ck_constraint = types.list(types.SpaceCkConstraint)
        }
    }), 'Space')
end

local function space_mutation_types_init()
    types.add_type(types.inputObject({
        name = 'SpaceFieldInput',
        description = 'Space field',
        fields = {
            name = types.string,
            type = types.SpaceFieldType,
            is_nullable = types.boolean
        }
    }), 'SpaceFieldInput')

    types.add_type(types.inputObject({
        name = 'SpaceIndexPartInput',
        description = 'Space index part',
        fields = {
            type = types.SpaceFieldInput,
            fieldno = types.int,
            is_nullable = types.boolean
        }
    }), 'SpaceIndexPartInput')

    types.add_type(types.inputObject({
        name = 'SpaceIndexInput',
        description = 'Space Index',
        fields = {
            name = types.string,
            type = types.SpaceIndexType,
            id = types.int,
            unique = types.boolean,
            if_not_exists = types.boolean,
            parts = types.list(types.SpaceIndexPartInput),
            dimension = types.int,
            distance = types.SpaceIndexDimension,
            bloom_fpr = types.float,
            page_size = types.int,
            range_size = types.int,
            run_count_per_level = types.int,
            run_size_ratio = types.float
        }
    }), 'SpaceIndexInput')

    types.add_type(types.inputObject({
        name = 'SpaceCkConstraintInput',
        description = 'Space check constraint',
        fields = {
            name = types.string,
            is_enabled = types.boolean,
            space_id = types.int,
            expr = types.string
        }
    }), 'SpaceCkConstraintInput')

end

local function space_query_init()
    --checks('?string')
    operations.add_query({
        name = 'space',
        doc = 'Get space(s) definition',
        args = {
            name = types.list(types.SpaceName)
        },
        kind = types.list(types.Space),
        callback = 'graphqlapi.spaceapi.space_get'
    })
    -- if prefix then
    --     vars.space_callbacks[prefix..'.space'] = prefix..'.space'
    -- else
    --     vars.space_callbacks['space'] = 'space'
    -- end
    --require('log').info(require('json').encode(types._list()))
end

local function space_mutation_types_remove()
    types.remove_type('SpaceFieldInput')
    types.remove_type('SpaceIndexPartInput')
    types.remove_type('SpaceIndexInput')
    types.remove_type('SpaceCkConstraintInput')
end

local function space_query_types_remove()
    types.remove_type('SpaceFieldType')
    types.remove_type('SpaceEngine')
    types.remove_type('SpaceIndexType')
    types.remove_type('SpaceIndexDimension')
    types.remove_type('SpaceField')
    types.remove_type('SpaceIndexPart')
    types.remove_type('SpaceIndex')
    types.remove_type('SpaceCkConstraint')
    types.remove_type('SpaceName')
    types.remove_type('Space')
end

local function space_query_remove()
    operations.remove_query('space')
end

-- local function space_remove(_, args, _) return spaceapi:space_remove(args) end

-- local function space_add(_, args) return spaceapi:space_add(args) end

local function init()
    -- space_remove - remove space
    -- space_truncate - truncate space data
    -- space_count - count by indexed fields
    -- space_add - add_new space
    -- space_update - update existing space

    -- graphqlapi.add_mutation({
    --     name = 'space_remove',
    --     doc = 'Remove space',
    --     args = {
    --         name = types.string,
    --     },
    --     kind = space,
    --     callback = module_name .. '.space_remove'
    -- })

    -- graphqlapi.add_mutation({
    --     name = 'space_add',
    --     doc = 'Add new space',
    --     args = {
    --         format = types.list(space_field_input),
    --         id = types.int,
    --         name = types.string,
    --         engine = space_engine,
    --         field_count = types.int,
    --         temporary = types.boolean,
    --         is_local = types.boolean,
    --         enabled = types.boolean,
    --         size = types.int,
    --         user = types.string,
    --         index = types.list(space_index_input),
    --         ck_constraint = types.list(space_ck_constraint_input)
    --     },
    --     kind = space,
    --     callback = module_name .. '.space_add'
    -- })
end

local function stop()
    space_query_types_remove()
    space_query_remove()
end

return {
    init = init,
    stop = stop,
    space_query_types_init = space_query_types_init,
    space_query_types_remove = space_query_types_remove,
    space_mutation_types_init = space_mutation_types_init,
    space_mutation_types_remove = space_mutation_types_remove,
    space_query_init = space_query_init,
    space_query_remove = space_query_remove,
}
