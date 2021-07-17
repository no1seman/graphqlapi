local checks = require('checks')
local cluster = require('graphqlapi.cluster')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local utils = require('graphqlapi.utils')

require('graphqlapi.helpers.spaceapi')
local vars = require('graphqlapi.vars').new('graphqlapi.helpers')

vars:new('prefix', {})
vars:new('helpers',{})

local operation_types = {
    ['info'] = {
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
    ['drop'] = {
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
    ['truncate'] = {
        'SpaceTruncateResult',
    },
    ['update'] = {
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
    ['create'] = {
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
}

local function operations_prefixes(opts)
    checks({
        schema = 'string',
        prefix = '?string',
    })

    opts = opts or {}
    if not opts.prefix then return end

    vars.prefix[opts.schema] = vars.prefix[opts.schema] or {}

    if vars.helpers[opts.schema].info and
       vars.helpers[opts.schema].info.enabled then
        if not vars.prefix[opts.schema].queries then
            operations.add_queries_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
                doc = 'Spaces queries',
            })
            vars.prefix[opts.schema].queries = true
            vars.prefix[opts.schema].schema = opts.schema
        end
    else
        if vars.prefix[opts.schema].queries then
            operations.remove_query_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
            })
            vars.prefix[opts.schema].queries = false
        end
    end

    if (vars.helpers[opts.schema].drop and
       vars.helpers[opts.schema].drop.enabled) or
       (vars.helpers[opts.schema].truncate and
       vars.helpers[opts.schema].truncate.enabled) or
       (vars.helpers[opts.schema].update and
       vars.helpers[opts.schema].update.enabled) or
       (vars.helpers[opts.schema].create and
       vars.helpers[opts.schema].create.enabled) then
        if not vars.prefix[opts.schema].mutations then
            operations.add_mutations_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
                doc = 'Spaces mutations',
            })
            vars.prefix[opts.schema].mutations = true
            vars.prefix[opts.schema].schema = opts.schema
        end
    else
        if vars.prefix[opts.schema].mutations then
            operations.remove_mutation_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
            })
            vars.prefix[opts.schema].mutations = false
        end
    end
end

local function space_types(schema_name)
    local type_list = {}

    for operation, value in pairs(vars.helpers[schema_name]) do
        if value.enabled == true then
            type_list = utils.merge_arrays(type_list, operation_types[operation])
        end
    end

    if utils.value_in('SpaceFieldType', type_list) then
        if not types(schema_name).SpaceFieldType then
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
                    scalar = 'scalar',
                }
            }), schema_name)
        end
    else
        types.remove('SpaceFieldType', schema_name)
    end

    if utils.value_in('SpaceEngine', type_list) then
        if not types(schema_name).SpaceEngine then
            types.add(types.enum({
                name = 'SpaceEngine',
                description = 'Space engine',
                values = {
                    memtx = 'memtx',
                    vinyl = 'vinyl',
                    blackhole = 'blackhole',
                    sysview = 'sysview',
                    service = 'service',
                }
            }), schema_name)
        end
    else
        types.remove('SpaceEngine', schema_name)
    end

    if utils.value_in('SpaceIndexType', type_list) then
        if not types(schema_name).SpaceIndexType then
            types.add(types.enum({
                name = 'SpaceIndexType',
                description = 'Space index type',
                values = {
                    tree = 'TREE',
                    hash = 'HASH',
                    bitset = 'BITSET',
                    rtree = 'RTREE',
                }
            }), schema_name)
        end
    else
        types.remove('SpaceIndexType', schema_name)
    end

    if utils.value_in('SpaceIndexDimension', type_list) then
        if not types(schema_name).SpaceIndexDimension then
            types.add(types.enum({
                name = 'SpaceIndexDimension',
                description = 'Space index dimension',
                values = {euclid = 'euclid', manhattan = 'manhattan'},
            }), schema_name)
        end
    else
        types.remove('SpaceIndexDimension', schema_name)
    end

    if utils.value_in('SpaceField', type_list) then
        if not types(schema_name).SpaceField then
            types.add(types.object({
                name = 'SpaceField',
                description = 'Space field',
                fields = {
                    name = types.string,
                    type = types(schema_name).SpaceFieldType,
                    is_nullable = types.boolean,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceField', schema_name)
    end

    if utils.value_in('SpaceIndexPart', type_list) then
        if not types(schema_name).SpaceIndexPart then
            types.add(types.object({
                name = 'SpaceIndexPart',
                description = 'Space index part',
                fields = {
                    type = types(schema_name).SpaceFieldType,
                    fieldno = types.int,
                    is_nullable = types.boolean,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceIndexPart', schema_name)
    end

    if utils.value_in('SpaceIndex', type_list) then
        if not types(schema_name).SpaceIndex then
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
                    parts = types.list(types(schema_name).SpaceIndexPart),
                    dimension = types.int,
                    distance = types(schema_name).SpaceIndexDimension,
                    bloom_fpr = types.float,
                    page_size = types.int,
                    range_size = types.int,
                    run_count_per_level = types.int,
                    run_size_ratio = types.float,
                    bsize = types.long,
                    len = types.long,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceIndex', schema_name)
    end

    if utils.value_in('SpaceCkConstraint', type_list) then
        if not types(schema_name).SpaceCkConstraint then
            types.add(types.object({
                name = 'SpaceCkConstraint',
                description = 'Space check constraint',
                fields = {
                    name = types.string,
                    is_enabled = types.boolean,
                    space_id = types.int,
                    expr = types.string,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceCkConstraint', schema_name)
    end

    if utils.value_in('SpaceInfo', type_list) then
        if not types(schema_name).SpaceInfo then
            types.add(types.object({
                name = 'SpaceInfo',
                description = 'Space info',
                fields = {
                    format = types.list(types(schema_name).SpaceField).nonNull,
                    id = types.int.nonNull,
                    name = types.string,
                    engine = types(schema_name).SpaceEngine,
                    field_count = types.int,
                    temporary = types.boolean,
                    is_local = types.boolean,
                    enabled = types.boolean,
                    bsize = types.long,
                    full_bsize = types.long,
                    len = types.long,
                    user = types.string,
                    index = types.list(types(schema_name).SpaceIndex),
                    ck_constraint = types.list(types(schema_name).SpaceCkConstraint),
                }
            }), schema_name)
        end
    else
        types.remove('SpaceInfo', schema_name)
    end

    if utils.value_in('SpaceFieldInput', type_list) then
        if not types(schema_name).SpaceFieldInput then
            types.add(types.inputObject({
                name = 'SpaceFieldInput',
                description = 'Space field',
                fields = {
                    name = types.string,
                    type = types(schema_name).SpaceFieldType,
                    is_nullable = types.boolean,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceFieldInput', schema_name)
    end

    if utils.value_in('SpaceIndexPartInput', type_list) then
        if not types(schema_name).SpaceIndexPartInput then
            types.add(types.inputObject({
                name = 'SpaceIndexPartInput',
                description = 'Space index part',
                fields = {
                    type = types(schema_name).SpaceFieldInput,
                    fieldno = types.int,
                    is_nullable = types.boolean,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceIndexPartInput', schema_name)
    end

    if utils.value_in('SpaceIndexInput', type_list) then
        if not types(schema_name).SpaceIndexInput then
        types.add(types.inputObject({
            name = 'SpaceIndexInput',
            description = 'Space Index',
            fields = {
                name = types.string,
                type = types(schema_name).SpaceIndexType,
                id = types.int,
                unique = types.boolean,
                if_not_exists = types.boolean,
                parts = types.list(types(schema_name).SpaceIndexPartInput),
                dimension = types.int,
                distance = types(schema_name).SpaceIndexDimension,
                bloom_fpr = types.float,
                page_size = types.int,
                range_size = types.int,
                run_count_per_level = types.int,
                run_size_ratio = types.float,
            }
        }), schema_name)
        end
    else
        types.remove('SpaceIndexInput', schema_name)
    end

    if utils.value_in('SpaceCkConstraintInput', type_list) then
        if not types(schema_name).SpaceCkConstraintInput then
        types.add(types.inputObject({
            name = 'SpaceCkConstraintInput',
            description = 'Space check constraint',
            fields = {
                name = types.string,
                is_enabled = types.boolean,
                space_id = types.int,
                expr = types.string,
            }
        }), schema_name)
        end
    else
        types.remove('SpaceCkConstraintInput', schema_name)
    end

    if utils.value_in('SpaceTruncateResult', type_list) then
        if not types(schema_name).SpaceTruncateResult then
            types.add(types.object({
                name = 'SpaceTruncateResult',
                description = 'Space Truncate Result',
                fields = {
                    truncated_len = types.long,
                    truncated_bsize = types.long,
                    name = types.string,
                }
            }), schema_name)
        end
    else
        types.remove('SpaceTruncateResult', schema_name)
    end
end

local function get_spaces_list(helper, spaces)
    local list_spaces = {}
    for _, space in pairs(spaces) do
        if (utils.value_in(space, helper.include) or
            #helper.include == 0) and
            not utils.value_in(space, helper.exclude) then
            list_spaces[space]=space
        end
    end
    return list_spaces
end

-- space_info section
local function add_space_info_enum(schema, list_spaces)
    types.add(types.enum({
        name = 'SpaceInfoNames',
        description = 'Spaces info name list enum',
        values = list_spaces,
    }), schema)
end

local function remove_space_info_enum(schema)
    types.remove('SpaceInfoNames', schema)
end

local function add_space_info_query(schema, prefix)
    operations.add_query({
        schema = schema,
        prefix = prefix,
        name = 'space_info',
        doc = 'Get space(s) definition',
        args = {
            name = types.list(types(schema).SpaceInfoNames),
        },
        kind = types.list(types(schema).SpaceInfo),
        callback = 'graphqlapi.helpers.spaceapi.space_info',
    })
end

local function remove_space_info_query(schema, prefix)
    operations.remove_query({
        name = 'space_info',
        schema = schema,
        prefix = prefix,
    })
end

local function space_info_list()
    local existing = cluster.get_existing_spaces()
    for schema in pairs(vars.helpers) do
        if vars.helpers[schema].info ~= nil and vars.helpers[schema].info.enabled then
            local list_spaces = get_spaces_list(vars.helpers[schema].info, existing)
            if types(schema).SpaceInfoNames == nil then
                add_space_info_enum(schema, list_spaces)
            else
                remove_space_info_query(schema, vars.helpers[schema].info.prefix)
                remove_space_info_enum(schema)
                add_space_info_enum(schema, list_spaces)
                add_space_info_query(schema, vars.helpers[schema].info.prefix)
            end
        end
    end
end

local function space_info_init(opts)
    checks({
        include = '?table',
        exclude = '?table',
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}

    opts.include = opts.include or {}
    opts.exclude = opts.exclude or {}
    assert(utils.is_string_array(opts.include))
    assert(utils.is_string_array(opts.exclude))

    opts.schema = utils.coerce_schema(opts.schema)

    vars.helpers[opts.schema] = vars.helpers[opts.schema] or {}
    vars.helpers[opts.schema].info = {
        prefix = opts.prefix,
        enabled = true,
        include = opts.include,
        exclude = opts.exclude,
    }

    space_types(opts.schema)
    operations_prefixes({
        schema = opts.schema,
        prefix = opts.prefix,
    })

    space_info_list()
    add_space_info_query(opts.schema, opts.prefix)
end

local function _space_info_remove(schema)
    if vars.helpers[schema].info ~= nil and vars.helpers[schema].info.enabled then
        remove_space_info_query(schema, vars.helpers[schema].info.prefix)
        remove_space_info_enum(schema)

        vars.helpers[schema].info.enabled = false
        space_types(schema)
        operations_prefixes({
            schema = schema,
            prefix = vars.helpers[schema].info.prefix,
        })
        vars.helpers[schema].info = {}
    end
end

local function space_info_remove(opts)
    if opts ~= nil then
        opts = opts or {}
        opts.schema = utils.coerce_schema(opts.schema)
        _space_info_remove(opts.schema)
    else
        for schema in pairs(vars.helpers) do
            _space_info_remove(schema)
        end
    end
end

-- space_drop section
local function add_space_drop_enum(schema, list_spaces)
    types.add(types.enum({
        name = 'SpaceDropNames',
        description = 'Spaces drop name list enum',
        values = list_spaces,
    }), schema)
end

local function remove_space_drop_enum(schema)
    types.remove('SpaceDropNames', schema)
end

local function add_space_drop_mutation(schema, prefix)
    operations.add_mutation({
        schema = schema,
        prefix = prefix,
        name = 'space_drop',
        doc = 'Drop space',
        args = {
            name = types(schema).SpaceDropNames,
        },
        kind = types.boolean,
        callback = 'graphqlapi.helpers.spaceapi.space_drop',
    })
end

local function remove_space_drop_mutation(schema, prefix)
    operations.remove_mutation({
        name = 'space_drop',
        schema = schema,
        prefix = prefix,
    })
end

local function space_drop_list()
    local existing = cluster.get_existing_spaces()
    for schema in pairs(vars.helpers) do
        if vars.helpers[schema].drop ~= nil and vars.helpers[schema].drop.enabled then
            local list_spaces = get_spaces_list(vars.helpers[schema].drop, existing)
            if types(schema).SpaceDropNames == nil then
                add_space_drop_enum(schema, list_spaces)
            else
                remove_space_drop_mutation(schema, vars.helpers[schema].drop.prefix)
                remove_space_drop_enum(schema)
                add_space_drop_enum(schema, list_spaces)
                add_space_drop_mutation(schema, vars.helpers[schema].drop.prefix)
            end
        end
    end
end

local function space_drop_init(opts)
    checks({
        include = '?table',
        exclude = '?table',
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}

    opts.include = opts.include or {}
    opts.exclude = opts.exclude or {}
    assert(utils.is_string_array(opts.include))
    assert(utils.is_string_array(opts.exclude))

    opts.schema = utils.coerce_schema(opts.schema)
    vars.helpers[opts.schema] = vars.helpers[opts.schema] or {}
    vars.helpers[opts.schema].drop = {
        prefix = opts.prefix,
        enabled = true,
        include = opts.include,
        exclude = opts.exclude,
    }

    space_types(opts.schema)
    operations_prefixes({
        schema = opts.schema,
        prefix = opts.prefix,
    })

    space_drop_list()
    add_space_drop_mutation(opts.schema, opts.prefix)
end

local function _space_drop_remove(schema)
    if vars.helpers[schema].drop ~= nil and vars.helpers[schema].drop.enabled then
        remove_space_drop_mutation(schema, vars.helpers[schema].drop.prefix)
        remove_space_drop_enum(schema)

        vars.helpers[schema].drop.enabled = false
        space_types(schema)
        operations_prefixes({
            schema = schema,
            prefix = vars.helpers[schema].drop.prefix,
        })
        vars.helpers[schema].drop = {}
    end
end

local function space_drop_remove(opts)
    if opts ~= nil then
        opts = opts or {}
        opts.schema = utils.coerce_schema(opts.schema)
        _space_drop_remove(opts.schema)
    else
        for schema in pairs(vars.helpers) do
            _space_drop_remove(schema)
        end
    end
end

-- space_truncate section
local function add_space_truncate_enum(schema, list_spaces)
    types.add(types.enum({
        name = 'SpaceTruncateNames',
        description = 'Spaces truncate name list enum',
        values = list_spaces,
    }), schema)
end

local function remove_space_truncate_enum(schema)
    types.remove('SpaceTruncateNames', schema)
end

local function add_space_truncate_mutation(schema, prefix)
    operations.add_mutation({
        schema = schema,
        prefix = prefix,
        name = 'space_truncate',
        doc = 'Truncate space',
        args = {
            name = types(schema).SpaceTruncateNames,
        },
        kind = types(schema).SpaceTruncateResult,
        callback = 'graphqlapi.helpers.spaceapi.space_truncate',
    })
end

local function remove_space_truncate_mutation(schema, prefix)
    operations.remove_mutation({
        name = 'space_truncate',
        schema = schema,
        prefix = prefix,
    })
end

local function space_truncate_list()
    local existing = cluster.get_existing_spaces()
    for schema in pairs(vars.helpers) do
        if vars.helpers[schema].truncate ~= nil and vars.helpers[schema].truncate.enabled then
            local list_spaces = get_spaces_list(vars.helpers[schema].truncate, existing)
            if types(schema).SpaceTruncateNames == nil then
                add_space_truncate_enum(schema, list_spaces)
            else
                remove_space_truncate_mutation(schema, vars.helpers[schema].truncate.prefix)
                remove_space_truncate_enum(schema)
                add_space_truncate_enum(schema, list_spaces)
                add_space_truncate_mutation(schema, vars.helpers[schema].truncate.prefix)
            end
        end
    end
end

local function space_truncate_init(opts)
    checks({
        include = '?table',
        exclude = '?table',
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}

    opts.include = opts.include or {}
    opts.exclude = opts.exclude or {}
    assert(utils.is_string_array(opts.include))
    assert(utils.is_string_array(opts.exclude))

    opts.schema = utils.coerce_schema(opts.schema)
    vars.helpers[opts.schema] = vars.helpers[opts.schema] or {}
    vars.helpers[opts.schema].truncate = {
        prefix = opts.prefix,
        enabled = true,
        include = opts.include,
        exclude = opts.exclude,
    }

    space_types(opts.schema)
    operations_prefixes({
        schema = opts.schema,
        prefix = opts.prefix,
    })

    space_truncate_list()
    add_space_truncate_mutation(opts.schema, opts.prefix)
end

local function _space_truncate_remove(schema)
    if vars.helpers[schema].truncate ~= nil and vars.helpers[schema].truncate.enabled then
        remove_space_truncate_mutation(schema, vars.helpers[schema].truncate.prefix)
        remove_space_truncate_enum(schema)

        vars.helpers[schema].truncate.enabled = false
        space_types(schema)
        operations_prefixes({
            schema = schema,
            prefix = vars.helpers[schema].truncate.prefix,
        })
        vars.helpers[schema].truncate = {}
    end
end

local function space_truncate_remove(opts)
    if opts ~= nil then
        opts = opts or {}
        opts.schema = utils.coerce_schema(opts.schema)
        _space_truncate_remove(opts.schema)
    else
        for schema in pairs(vars.helpers) do
            _space_truncate_remove(schema)
        end
    end
end

-- space_update
local function add_space_update_enum(schema, list_spaces)
    types.add(types.enum({
        name = 'SpaceUpdateNames',
        description = 'Spaces update name list enum',
        values = list_spaces,
    }), schema)
end

local function remove_space_update_enum(schema)
    types.remove('SpaceUpdateNames', schema)
end

local function add_space_update_mutation(schema, prefix)
    operations.add_mutation({
        schema = schema,
        prefix = prefix,
        name = 'space_update',
        doc = 'Update existing space',
        args = {
            format = types.list(types(schema).SpaceFieldInput),
            id = types.int,
            name = types(schema).SpaceUpdateNames,
            engine = types(schema).SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types(schema).SpaceIndexInput),
            ck_constraint = types.list(types(schema).SpaceCkConstraintInput),
        },
        kind = types(schema).SpaceInfo,
        callback = 'graphqlapi.helpers.spaceapi.space_update',
    })
end

local function remove_space_update_mutation(schema, prefix)
    operations.remove_mutation({
        name = 'space_update',
        schema = schema,
        prefix = prefix,
    })
end

local function space_update_list()
    local existing = cluster.get_existing_spaces()
    for schema in pairs(vars.helpers) do
        if vars.helpers[schema].update ~= nil and vars.helpers[schema].update.enabled then
            local list_spaces = get_spaces_list(vars.helpers[schema].update, existing)
            if types(schema).SpaceUpdateNames == nil then
                add_space_update_enum(schema, list_spaces)
            else
                remove_space_update_mutation(schema, vars.helpers[schema].update.prefix)
                remove_space_update_enum(schema)
                add_space_update_enum(schema, list_spaces)
                add_space_update_mutation(schema, vars.helpers[schema].update.prefix)
            end
        end
    end
end

local function space_update_init(opts)
    checks({
        include = '?table',
        exclude = '?table',
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}

    opts.include = opts.include or {}
    opts.exclude = opts.exclude or {}
    assert(utils.is_string_array(opts.include))
    assert(utils.is_string_array(opts.exclude))

    opts.schema = utils.coerce_schema(opts.schema)
    vars.helpers[opts.schema] = vars.helpers[opts.schema] or {}
    vars.helpers[opts.schema].update = {
        prefix = opts.prefix,
        enabled = true,
        include = opts.include,
        exclude = opts.exclude,
    }

    space_types(opts.schema)
    operations_prefixes({
        schema = opts.schema,
        prefix = opts.prefix,
    })

    space_update_list()
    add_space_update_mutation(opts.schema, opts.prefix)
end

local function _space_update_remove(schema)
    if vars.helpers[schema].update ~= nil and vars.helpers[schema].update.enabled then
        remove_space_update_mutation(schema,  vars.helpers[schema].update.prefix)
        remove_space_update_enum(schema)

        vars.helpers[schema].update.enabled = false
        space_types(schema)
        operations_prefixes({
            schema = schema,
            prefix = vars.helpers[schema].update.prefix,
        })
        vars.helpers[schema].update = {}
    end
end

local function space_update_remove(opts)
    if opts ~= nil then
        opts = opts or {}
        opts.schema = utils.coerce_schema(opts.schema)
        _space_update_remove(opts.schema)
    else
        for schema in pairs(vars.helpers) do
            _space_update_remove(schema)
        end
    end
end

-- space_create section
local function add_space_create_mutation(schema, prefix)
    operations.add_mutation({
        schema = schema,
        prefix = prefix,
        name = 'space_create',
        doc = 'Create new space',
        args = {
            format = types.list(types(schema).SpaceFieldInput),
            id = types.int,
            name = types.string,
            engine = types(schema).SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types(schema).SpaceIndexInput),
            ck_constraint = types.list(types(schema).SpaceCkConstraintInput)
        },
        kind = types(schema).SpaceInfo,
        callback = 'graphqlapi.helpers.spaceapi.space_create',
    })
end

local function remove_space_create_mutation(schema, prefix)
    operations.remove_mutation({
        name = 'space_create',
        schema = schema,
        prefix = prefix,
    })
end

local function space_create_init(opts)
    checks({
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}
    opts.schema = utils.coerce_schema(opts.schema)
    vars.helpers[opts.schema] = vars.helpers[opts.schema] or {}
    vars.helpers[opts.schema].create = {
        prefix = opts.prefix,
        enabled = true,
    }
    space_types(opts.schema)
    operations_prefixes({
        schema = opts.schema,
        prefix = opts.prefix,
    })

    add_space_create_mutation(opts.schema, opts.prefix)
end

local function _space_create_remove(schema)
    if vars.helpers[schema].create ~= nil and vars.helpers[schema].create.enabled then
        remove_space_create_mutation(schema, vars.helpers[schema].create.prefix)
        vars.helpers[schema].create.enabled = false
        space_types(schema)
        operations_prefixes({
            schema = schema,
            prefix = vars.helpers[schema].create.prefix,
        })
        vars.helpers[schema].create = nil
    end
end

local function space_create_remove(opts)
    if opts ~= nil then
        opts = opts or {}
        opts.schema = utils.coerce_schema(opts.schema)
        _space_create_remove(opts.schema)
    else
        for schema in pairs(vars.helpers) do
            _space_create_remove(schema)
        end
    end
end

local function update_lists()
    space_info_list()
    space_drop_list()
    space_truncate_list()
    space_update_list()
end

local function init(opts)
    checks({
        info = '?table',
        drop = '?table',
        truncate = '?table',
        update = '?table',
        create = '?table',
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}
    opts.schema = utils.coerce_schema(opts.schema)
    if (opts.info and opts.info.enabled == true) or not opts.info then
        opts.info = opts.info or {}
        space_info_init({
            include = opts.info.include,
            exclude = opts.info.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.drop and opts.drop.enabled == true) or not opts.drop then
        opts.drop = opts.drop or {}
        space_drop_init({
            include = opts.drop.include,
            exclude = opts.drop.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.truncate and opts.truncate.enabled == true) or not opts.truncate then
        opts.truncate = opts.truncate or {}
        space_truncate_init({
            include = opts.truncate.include,
            exclude = opts.truncate.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.update and opts.update.enabled == true) or not opts.update then
        opts.update = opts.update or {}
        space_update_init({
            include = opts.update.include,
            exclude = opts.update.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.create and opts.create.enabled == true) or not opts.create then
        space_create_init({
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
end

local function stop(opts)
    checks({
        schema = '?string',
    })

    if opts ~= nil then
        opts.schema = utils.coerce_schema(opts.schema)
        space_info_remove({ schema = opts.schema, })
        space_drop_remove({ schema = opts.schema, })
        space_truncate_remove({ schema = opts.schema, })
        space_update_remove({ schema = opts.schema, })
        space_create_remove({ schema = opts.schema, })
    else
        space_info_remove()
        space_drop_remove()
        space_truncate_remove()
        space_update_remove()
        space_create_remove()
    end
    vars.helpers = nil
    vars.prefix = nil
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
