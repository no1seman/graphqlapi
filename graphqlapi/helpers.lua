local checks = require('checks')

local graphqlapi = require('graphqlapi')
local spaceapi = require('graphqlapi.spaceapi')
local vars = require('graphqlapi.vars').new('graphqlapi.helpers')
-- space types storage

vars:new('space_query_types', {})
vars:new('space_mutation_types', {})
vars:new('space_callbacks', {})
vars:new('space_mutations', {})

local function space_query_types_init()
    vars.space_query_types.space_field_type = graphqlapi.types.enum({
        name = 'SpaceFieldType',
        description = 'Space field type',
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
    })

    vars.space_query_types.space_engine = graphqlapi.types.enum({
        name = 'SpaceEngine',
        description = 'Space engine',
        values = {
            memtx = 'memtx',
            vinyl = 'vinyl',
            blackhole = 'blackhole',
            sysview = 'sysview',
            service = 'service'
        }
    })

    vars.space_query_types.space_index_type = graphqlapi.types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE'
        }
    })

    vars.space_query_types.space_index_dimention = graphqlapi.types.enum({
            name = 'SpaceIndexDimention',
            description = 'Space index dimention',
            values = {
                euclid = 'euclid',
                manhattan = 'manhattan'
            }
        })

    vars.space_query_types.space_field_fields = {
        name = graphqlapi.types.string,
        type = vars.space_query_types.space_field_type,
        is_nullable = graphqlapi.types.boolean
    }

    vars.space_query_types.space_field = graphqlapi.types.object({
        name = 'SpaceField',
        description = 'Space field',
        fields = vars.space_query_types.space_field_fields
    })

    vars.space_query_types.space_index_part_fields = {
        type = vars.space_query_types.space_field_type,
        fieldno = graphqlapi.types.int,
        is_nullable = graphqlapi.types.boolean
    }

    vars.space_query_types.space_index_part = graphqlapi.types.object({
        name = 'SpaceIndexPart',
        description = 'Space index part',
        fields = vars.space_query_types.space_index_part_fields
    })

    vars.space_query_types.space_index = graphqlapi.types.object({
        name = 'SpaceIndex',
        description = 'Space Index',
        fields = {
            name = graphqlapi.types.string,
            type = vars.space_query_types.space_index_type,
            id = graphqlapi.types.int,
            unique = graphqlapi.types.boolean,
            if_not_exists = graphqlapi.types.boolean,
            parts = graphqlapi.types.list(vars.space_query_types.space_index_part),
            dimension = graphqlapi.types.int,
            distance = vars.space_query_types.space_index_dimention,
            bloom_fpr = graphqlapi.types.float,
            page_size = graphqlapi.types.int,
            range_size = graphqlapi.types.int,
            run_count_per_level = graphqlapi.types.int,
            run_size_ratio = graphqlapi.types.float,
            size = graphqlapi.types.long,
            len = graphqlapi.types.long,
        }
    })

    vars.space_query_types.space_ck_constraint_fields = {
        name = graphqlapi.types.string,
        is_enabled = graphqlapi.types.boolean,
        space_id = graphqlapi.types.int,
        expr = graphqlapi.types.string
    }

    vars.space_query_types.space_ck_constraint = graphqlapi.types.object({
            name = 'SpaceCkConstraint',
            description = 'Space check constraint',
            fields = vars.space_query_types.space_ck_constraint_fields
        })

    vars.space_query_types.space_name = graphqlapi.types.enum({
        name = 'SpaceName',
        description = 'Spaces list',
        values = spaceapi.spaces_list()
    })

    vars.space_query_types.space = graphqlapi.types.object({
        name = 'Space',
        description = 'Space',
        fields = {
            format = graphqlapi.types.list(vars.space_query_types.space_field),
            id = graphqlapi.types.int,
            name = graphqlapi.types.string,
            engine = vars.space_query_types.space_engine,
            field_count = graphqlapi.types.int,
            temporary = graphqlapi.types.boolean,
            is_local = graphqlapi.types.boolean,
            enabled = graphqlapi.types.boolean,
            size = graphqlapi.types.long,
            len = graphqlapi.types.long,
            user = graphqlapi.types.string,
            index = graphqlapi.types.list(vars.space_query_types.space_index),
            ck_constraint = graphqlapi.types.list(vars.space_query_types.space_ck_constraint)
        }
    })
end

local function space_mutation_types_init()
    vars.space_mutation_types.space_field_input = graphqlapi.types.inputObject({
        name = 'SpaceFieldInput',
        description = 'Space field',
        fields = vars.space_query_types.space_field_fields
    })

    vars.space_mutation_types.space_index_part_input = graphqlapi.types.inputObject({
        name = 'SpaceIndexPartInput',
        description = 'Space index part',
        fields = vars.space_query_types.space_index_part_fields
    })

    vars.space_mutation_types.space_index_input = graphqlapi.types.inputObject({
        name = 'SpaceIndexInput',
        description = 'Space Index',
        fields = {
            name = graphqlapi.types.string,
            type = vars.space_query_types.space_index_type,
            id = graphqlapi.types.int,
            unique = graphqlapi.types.boolean,
            if_not_exists = graphqlapi.types.boolean,
            parts = graphqlapi.types.list(vars.space_mutation_types.space_index_part_input),
            dimension = graphqlapi.types.int,
            distance = vars.space_query_types.space_index_dimention,
            bloom_fpr = graphqlapi.types.float,
            page_size = graphqlapi.types.int,
            range_size = graphqlapi.types.int,
            run_count_per_level = graphqlapi.types.int,
            run_size_ratio = graphqlapi.types.float
        }
    })

    vars.space_mutation_types.space_ck_constraint_input = graphqlapi.types.inputObject({
        name = 'SpaceCkConstraintInput',
        description = 'Space check constraint',
        fields = vars.space_query_types.space_ck_constraint_fields
    })

end

local function space_callback_init(prefix)
    checks('?string')
    graphqlapi.add_callback({
        prefix = prefix,
        name = 'space',
        doc = 'Get space(s) definition',
        args = {
            name = graphqlapi.types.list(vars.space_query_types.space_name),
        },
        kind = graphqlapi.types.list(vars.space_query_types.space),
        callback = 'graphqlapi.spaceapi.space_get'
    })
    if prefix then
        vars.space_callbacks[prefix..'.space'] = prefix..'.space'
    else
        vars.space_callbacks['space'] = 'space'
    end
end

local function space_mutation_types_remove()
    for k,v in pairs(vars.space_mutation_types) do
        graphqlapi.types.remove_type(v.name)
        vars.space_mutation_types[k] = nil
    end
end

local function space_query_types_remove()
    for k,v in pairs(vars.space_query_types) do
        graphqlapi.types.remove_type(v.name)
        vars.space_mutation_types[k] = nil
    end
    space_mutation_types_remove()
end

local function space_callbacks_remove()
    for k in pairs(vars.space_callbacks) do
        graphqlapi.remove_callback(k)
    end
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
    --         name = graphqlapi.types.string,
    --         id = graphqlapi.types.int
    --     },
    --     kind = space,
    --     callback = module_name .. '.space_remove'
    -- })

    -- graphqlapi.add_mutation({
    --     name = 'space_add',
    --     doc = 'Add new space',
    --     args = {
    --         format = graphqlapi.types.list(space_field_input),
    --         id = graphqlapi.types.int,
    --         name = graphqlapi.types.string,
    --         engine = space_engine,
    --         field_count = graphqlapi.types.int,
    --         temporary = graphqlapi.types.boolean,
    --         is_local = graphqlapi.types.boolean,
    --         enabled = graphqlapi.types.boolean,
    --         size = graphqlapi.types.int,
    --         user = graphqlapi.types.string,
    --         index = graphqlapi.types.list(space_index_input),
    --         ck_constraint = graphqlapi.types.list(space_ck_constraint_input)
    --     },
    --     kind = space,
    --     callback = module_name .. '.space_add'
    -- })
end

local function stop()
    space_query_types_remove()
    space_callbacks_remove()
end

return {
    init = init,
    stop = stop,
    space_query_types_init = space_query_types_init,
    space_query_types_remove = space_query_types_remove,
    space_mutation_types_init = space_mutation_types_init,
    space_mutation_types_remove = space_mutation_types_remove,
    space_callback_init = space_callback_init,
    space_callbacks_remove = space_callbacks_remove,
}