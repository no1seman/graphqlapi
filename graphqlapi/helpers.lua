local checks = require('checks')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local ddl = require('ddl')
local utils = require('graphqlapi.utils')

require('graphqlapi.spaceapi')
local vars = require('graphqlapi.vars').new('graphqlapi.helpers')

vars:new('helpers', {
    ['info'] = {
        types = {
            'SpaceCkConstraint',
            'SpaceEngine',
            'SpaceField',
            'SpaceFieldType',
            'SpaceIndex',
            'SpaceIndexDimension',
            'SpaceIndexPart',
            'SpaceIndexType',
            'SpaceInfo',
        },
    },
    ['drop'] = {
        types = {
            'SpaceCkConstraint',
            'SpaceEngine',
            'SpaceField',
            'SpaceFieldType',
            'SpaceIndex',
            'SpaceIndexDimension',
            'SpaceIndexPart',
            'SpaceIndexType',
            'SpaceInfo',
        },
    },
    ['truncate'] = {
        types = {
            'SpaceTruncateResult',
        },
    },
    ['count'] = {
        types = {},
    },
    ['update'] = {
        types = {
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
        },
    },
    ['create'] = {
        types = {
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
        },
    },
})

local function space_types()
    local type_list = {}

    for _, value in pairs(vars.helpers) do
        if value.enabled == true then
            type_list = utils.merge_arrays(type_list, value.types)
        end
    end

    if utils.value_in('SpaceFieldType', type_list) then
        if not types.SpaceFieldType then
            types.add(types.enum({
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
        end
    else
        types.remove('SpaceFieldType')
    end

    if utils.value_in('SpaceEngine', type_list) then
        if not types.SpaceEngine then
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
            }), 'SpaceEngine')
        end
    else
        types.remove('SpaceEngine')
    end

    if utils.value_in('SpaceIndexType', type_list) then
        if not types.SpaceIndexType then
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
        end
    else
        types.remove('SpaceIndexType')
    end

    if utils.value_in('SpaceIndexDimension', type_list) then
        if not types.SpaceIndexDimension then
            types.add(types.enum({
                name = 'SpaceIndexDimension',
                description = 'Space index dimension',
                values = {euclid = 'euclid', manhattan = 'manhattan'}
            }), 'SpaceIndexDimension')
        end
    else
        types.remove('SpaceIndexDimension')
    end

    if utils.value_in('SpaceField', type_list) then
        if not types.SpaceField then
            types.add(types.object({
                name = 'SpaceField',
                description = 'Space field',
                fields = {
                    name = types.string,
                    type = types.SpaceFieldType,
                    is_nullable = types.boolean
                }
            }), 'SpaceField')
        end
    else
        types.remove('SpaceField')
    end

    if utils.value_in('SpaceIndexPart', type_list) then
        if not types.SpaceIndexPart then
            types.add(types.object({
                name = 'SpaceIndexPart',
                description = 'Space index part',
                fields = {
                    type = types.SpaceFieldType,
                    fieldno = types.int,
                    is_nullable = types.boolean
                }
            }), 'SpaceIndexPart')
        end
    else
        types.remove('SpaceIndexPart')
    end

    if utils.value_in('SpaceIndex', type_list) then
        if not types.SpaceIndex then
            types.add(types.object({
                name = 'SpaceIndex',
                description = 'Space Index',
                fields = {
                    name = types.string,
                    type = types.SpaceIndexType,
                    id = types.int,
                    unique = types.boolean,
                    hint = types.boolean,
                    if_not_exists = types.boolean,
                    parts = types.list(types.SpaceIndexPart),
                    dimension = types.int,
                    distance = types.SpaceIndexDimension,
                    bloom_fpr = types.float,
                    page_size = types.int,
                    range_size = types.int,
                    run_count_per_level = types.int,
                    run_size_ratio = types.float,
                    bsize = types.long,
                    len = types.long
                }
            }), 'SpaceIndex')
        end
    else
        types.remove('SpaceIndex')
    end

    if utils.value_in('SpaceCkConstraint', type_list) then
        if not types.SpaceCkConstraint then
            types.add(types.object({
                name = 'SpaceCkConstraint',
                description = 'Space check constraint',
                fields = {
                    name = types.string,
                    is_enabled = types.boolean,
                    space_id = types.int,
                    expr = types.string
                }
            }), 'SpaceCkConstraint')
        end
    else
        types.remove('SpaceCkConstraint')
    end

    if utils.value_in('SpaceInfo', type_list) then
        if not types.SpaceInfo then
            types.add(types.object({
                name = 'SpaceInfo',
                description = 'Space info',
                fields = {
                    format = types.list(types.SpaceField),
                    id = types.int,
                    name = types.string,
                    engine = types.SpaceEngine,
                    field_count = types.int,
                    temporary = types.boolean,
                    is_local = types.boolean,
                    enabled = types.boolean,
                    bsize = types.long,
                    full_bsize = types.long,
                    len = types.long,
                    user = types.string,
                    index = types.list(types.SpaceIndex),
                    ck_constraint = types.list(types.SpaceCkConstraint),
                }
            }), 'SpaceInfo')
        end
    else
        types.remove('SpaceInfo')
    end

    if utils.value_in('SpaceFieldInput', type_list) then
        if not types.SpaceFieldInput then
            types.add(types.inputObject({
                name = 'SpaceFieldInput',
                description = 'Space field',
                fields = {
                    name = types.string,
                    type = types.SpaceFieldType,
                    is_nullable = types.boolean
                }
            }), 'SpaceFieldInput')
        end
    else
        types.remove('SpaceFieldInput')
    end

    if utils.value_in('SpaceIndexPartInput', type_list) then
        if not types.SpaceIndexPartInput then
            types.add(types.inputObject({
                name = 'SpaceIndexPartInput',
                description = 'Space index part',
                fields = {
                    type = types.SpaceFieldInput,
                    fieldno = types.int,
                    is_nullable = types.boolean
                }
            }), 'SpaceIndexPartInput')
        end
    else
        types.remove('SpaceIndexPartInput')
    end

    if utils.value_in('SpaceIndexInput', type_list) then
        if not types.SpaceIndexInput then
        types.add(types.inputObject({
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
        end
    else
        types.remove('SpaceIndexInput')
    end

    if utils.value_in('SpaceCkConstraintInput', type_list) then
        if not types.SpaceCkConstraintInput then
        types.add(types.inputObject({
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
    else
        types.remove('SpaceCkConstraintInput')
    end

    if utils.value_in('SpaceTruncateResult', type_list) then
        if not types.SpaceTruncateResult then
            types.add(types.object({
                name = 'SpaceTruncateResult',
                description = 'Space Truncate Result',
                fields = {
                    truncated_len = types.long,
                    truncated_bsize = types.long,
                }
            }), 'SpaceTruncateResult')
        end
    else
        types.remove('SpaceTruncateResult')
    end
end

local function existing_spaces()
    local spaces = {}
    local schema = ddl.get_schema()
    for space in pairs(schema.spaces) do
        spaces[space]=space
    end
    return spaces
end

-- space_info section
local function space_info_query_remove()
    operations.remove_query('space_info')
end

local function space_info_query()
    space_info_query_remove()
    operations.add_query({
        name = 'space_info',
        doc = 'Get space(s) definition',
        args = {
            name = types.list(types.SpaceInfoNames)
        },
        kind = types.list(types.SpaceInfo),
        callback = 'graphqlapi.spaceapi.space_info'
    })
end

local function space_info_list_remove()
    types.remove('SpaceInfoNames')
end

local function space_info_list()
    local existing = existing_spaces()

    local list_spaces = {}
    for _, space in pairs(existing) do
        if (utils.value_in(space, vars.helpers.info.include) or #vars.helpers.info.include == 0) and
            not utils.value_in(space, vars.helpers.info.exclude) then
            list_spaces[space]=space
        end
    end

    space_info_list_remove()

    types.add(types.enum({
        name = 'SpaceInfoNames',
        description = 'Spaces info name list enum',
        values = list_spaces
    }), 'SpaceInfoNames')

    space_info_query()
end

local function space_info_init(include, exclude)
    checks('?table', '?table')
    include = include or {}
    exclude = exclude or {}
    assert(utils.is_string_array(include))
    assert(utils.is_string_array(exclude))

    vars.helpers.info.enabled = true
    space_types()

    vars.helpers.info.include = include
    vars.helpers.info.exclude = exclude
    space_info_list()
end

local function space_info_remove()
    space_info_query_remove()
    space_info_list_remove()
    vars.helpers.info.enabled = false
    space_types()
    vars.helpers.info.include = nil
    vars.helpers.info.exclude = nil
end

-- space_drop section
local function space_drop_mutation_remove()
    operations.remove_mutation('space_drop')
end

local function space_drop_mutation()
    space_drop_mutation_remove()
    operations.add_mutation({
        name = 'space_drop',
        doc = 'Drop space',
        args = {
            name = types.SpaceDropNames,
        },
        kind = types.boolean,
        callback = 'graphqlapi.spaceapi.space_drop'
    })
end

local function space_drop_list_remove()
    types.remove('SpaceDropNames')
end

local function space_drop_list()
    local existing = existing_spaces()

    local list_spaces = {}
    for _, space in pairs(existing) do
        if (utils.value_in(space, vars.helpers.drop.include) or #vars.helpers.drop.include == 0) and
            not utils.value_in(space, vars.helpers.drop.exclude) then
            list_spaces[space]=space
        end
    end

    space_drop_list_remove()

    types.add(types.enum({
        name = 'SpaceDropNames',
        description = 'Spaces drop name list enum',
        values = list_spaces
    }), 'SpaceDropNames')

    space_drop_mutation()
end

local function space_drop_init(include, exclude)
    checks('?table', '?table')
    include = include or {}
    exclude = exclude or {}
    assert(utils.is_string_array(include))
    assert(utils.is_string_array(exclude))

    vars.helpers.drop.enabled = true
    space_types()

    vars.helpers.drop.include = include
    vars.helpers.drop.exclude = exclude

    space_drop_list()
end

local function space_drop_remove()
    space_drop_mutation_remove()
    space_drop_list_remove()
    vars.helpers.drop.enabled = false
    space_types()
    vars.helpers.info.include = nil
    vars.helpers.info.exclude = nil
end

-- space_truncate section
local function space_truncate_mutation_remove()
    operations.remove_mutation('space_truncate')
end

local function space_truncate_mutation()
    space_truncate_mutation_remove()
    operations.add_mutation({
        name = 'space_truncate',
        doc = 'Truncate space',
        args = {
            name = types.SpaceTruncateNames,
        },
        kind = types.SpaceTruncateResult,
        callback = 'graphqlapi.spaceapi.space_truncate'
    })
end

local function space_truncate_list_remove()
    types.remove('SpaceTruncateNames')
end

local function space_truncate_list()
    local existing = existing_spaces()

    local list_spaces = {}
    for _, space in pairs(existing) do
        if (utils.value_in(space, vars.helpers.truncate.include) or #vars.helpers.truncate.include == 0) and
            not utils.value_in(space, vars.helpers.truncate.exclude) then
            list_spaces[space]=space
        end
    end

    space_truncate_list_remove()

    types.add(types.enum({
        name = 'SpaceTruncateNames',
        description = 'Spaces truncate name list enum',
        values = list_spaces
    }), 'SpaceTruncateNames')

    space_truncate_mutation()
end

local function space_truncate_init(include, exclude)
    checks('?table', '?table')
    include = include or {}
    exclude = exclude or {}
    assert(utils.is_string_array(include))
    assert(utils.is_string_array(exclude))

    vars.helpers.truncate.enabled = true
    space_types()

    vars.helpers.truncate.include = include
    vars.helpers.truncate.exclude = exclude

    space_truncate_list()
end

local function space_truncate_remove()
    space_truncate_mutation_remove()
    space_truncate_list_remove()
    vars.helpers.truncate.enabled = false
    space_types()
    vars.helpers.info.include = nil
    vars.helpers.info.exclude = nil
end

-- space_update
local function space_update_mutation_remove()
    operations.remove_mutation('space_update')
end

local function space_update_mutation()
    space_update_mutation_remove()
    operations.add_mutation({
        name = 'space_update',
        doc = 'Update existing space',
        args = {
            format = types.list(types.SpaceFieldInput),
            id = types.int,
            name = types.SpaceUpdateNames,
            engine = types.SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types.SpaceIndexInput),
            ck_constraint = types.list(types.SpaceCkConstraintInput)
        },
        kind = types.SpaceInfo,
        callback = 'graphqlapi.spaceapi.space_update'
    })
end

local function space_update_list_remove()
    types.remove('SpaceUpdateNames')
end

local function space_update_list()
    local existing = existing_spaces()

    local list_spaces = {}
    for _, space in pairs(existing) do
        if (utils.value_in(space, vars.helpers.update.include) or #vars.helpers.update.include == 0) and
            not utils.value_in(space, vars.helpers.update.exclude) then
            list_spaces[space]=space
        end
    end

    space_update_list_remove()

    types.add(types.enum({
        name = 'SpaceUpdateNames',
        description = 'Spaces update name list enum',
        values = list_spaces
    }), 'SpaceUpdateNames')

    space_update_mutation()
end

local function space_update_init(include, exclude)
    checks('?table', '?table')
    include = include or {}
    exclude = exclude or {}
    assert(utils.is_string_array(include))
    assert(utils.is_string_array(exclude))

    vars.helpers.update.enabled = true
    space_types()

    vars.helpers.update.include = include
    vars.helpers.update.exclude = exclude

    space_update_list()
end

local function space_update_remove()
    space_update_mutation_remove()
    space_update_list_remove()
    vars.helpers.update.enabled = false
    space_types()
    vars.helpers.info.include = nil
    vars.helpers.info.exclude = nil
end

-- space_create section
local function space_create_init()
    vars.helpers.create.enabled = true
    space_types()

    operations.add_mutation({
        name = 'space_create',
        doc = 'Create new space',
        args = {
            format = types.list(types.SpaceFieldInput),
            id = types.int,
            name = types.string,
            engine = types.SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types.SpaceIndexInput),
            ck_constraint = types.list(types.SpaceCkConstraintInput)
        },
        kind = types.SpaceInfo,
        callback = 'graphqlapi.spaceapi.space_create'
    })
end

local function space_create_remove()
    operations.remove_mutation('space_create')
    vars.helpers.create.enabled = false
    space_types()
end

local function update_lists()
    if vars.helpers.info and vars.helpers.info.enabled == true then
        space_info_list()
    end
    if vars.helpers.drop and vars.helpers.drop.enabled == true then
        space_drop_list()
    end
    if vars.helpers.truncate and vars.helpers.truncate.enabled == true then
        space_truncate_list()
    end
    if vars.helpers.update and vars.helpers.update.enabled == true then
        space_update_list()
    end
end

local function init(opts)
    if not opts then
        space_info_init()
        space_drop_init()
        space_truncate_init()
        space_update_init()
        space_create_init()
    else
        opts = opts or {}
        if opts.info and opts.info.enabled == true then
            space_info_init(opts.info.include, opts.info.exclude)
        end
        if opts.drop and opts.drop.enabled == true then
            space_drop_init(opts.drop.include, opts.drop.exclude)
        end
        if opts.truncate and opts.truncate.enabled == true then
            space_truncate_init(opts.truncate.include, opts.truncate.exclude)
        end
        if opts.update and opts.update.enabled == true then
            space_update_init(opts.update.include, opts.update.exclude)
        end
        if opts.add and opts.add.enabled == true then
            space_create_init()
        end
    end
end

local function stop()
    if vars.helpers.info.enabled == true then
        space_info_remove()
    end
    if vars.helpers.drop.enabled == true then
        space_drop_remove()
    end
    if vars.helpers.truncate.enabled == true then
        space_truncate_remove()
    end
    if vars.helpers.update.enabled == true then
        space_update_remove()
    end
    if vars.helpers.create.enabled == true then
        space_create_remove()
    end
    vars.helpers = nil
end

return {
    init = init,
    stop = stop,
    update_lists = update_lists,

    -- space_info
    space_info_init = space_info_init,
    space_info_remove = space_info_remove,

    -- space_drop
    space_drop_init = space_drop_init,
    space_drop_remove = space_drop_remove,

    -- space_truncate
    space_truncate_init = space_truncate_init,
    space_truncate_remove = space_truncate_remove,

    -- space_update
    space_update_init = space_update_init,
    space_update_remove = space_update_remove,

    -- space_create
    space_create_init = space_create_init,
    space_create_remove = space_create_remove,
}
