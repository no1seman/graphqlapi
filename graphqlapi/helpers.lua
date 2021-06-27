local checks = require('checks')
local cluster = require('graphqlapi.cluster')
local operations = require('graphqlapi.operations')
local types = require('graphqlapi.types')
local utils = require('graphqlapi.utils')

local DEFAULT_PREFIX = 'spaces'

require('graphqlapi.spaceapi')
local vars = require('graphqlapi.vars').new('graphqlapi.helpers')

vars:new('prefix', {
    queries = false,
    mutations = false,
})

vars:new('helpers',{
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

local function operations_prefixes(opts)
    checks({
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}
    opts.prefix = opts.prefix or DEFAULT_PREFIX

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    if vars.helpers.info.enabled then
        if not vars.prefix.queries then
            operations.add_queries_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
                doc = 'Spaces queries',
            })
            vars.prefix.queries = true
            vars.prefix.schema = opts.schema
        end
    else
        if vars.prefix.queries then
            operations.remove_query_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
            })
            vars.prefix.queries = false
        end
    end

    if vars.helpers.drop.enabled or
       vars.helpers.truncate.enabled or
       vars.helpers.update.enabled or
       vars.helpers.create.enabled then
        if not vars.prefix.mutations then
            operations.add_mutations_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
                doc = 'Spaces mutations',
            })
            vars.prefix.mutations = true
            vars.prefix.schema = opts.schema
        end
    else
        if vars.prefix.mutations then
            operations.remove_mutation_prefix({
                prefix = opts.prefix,
                schema = opts.schema,
            })
            vars.prefix.mutations = false
        end
    end
end

local function space_types(schema_name)
    checks('?string')

    if schema_name == nil or schema_name:lower() == 'default' then
        schema_name = '__global__'
    else
        schema_name = schema_name:lower()
    end

    local type_list = {}

    for _, value in pairs(vars.helpers) do
        if value.enabled == true then
            type_list = utils.merge_arrays(type_list, value.types)
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

-- space_info section
local function space_info_query_remove()
    operations.remove_query({
        name = 'space_info',
        schema = vars.helpers.info.schema,
        prefix = vars.helpers.info.prefix,
    })
end

local function space_info_query()
    space_info_query_remove()
    operations.add_query({
        schema = vars.helpers.info.schema,
        prefix = vars.helpers.info.prefix,
        name = 'space_info',
        doc = 'Get space(s) definition',
        args = {
            name = types.list(types(vars.helpers.info.schema).SpaceInfoNames),
        },
        kind = types.list(types(vars.helpers.info.schema).SpaceInfo),
        callback = 'graphqlapi.spaceapi.space_info',
    })
end

local function space_info_list_remove()
    types.remove('SpaceInfoNames', vars.helpers.info.schema)
end

local function space_info_list()
    local existing = cluster.get_existing_spaces()

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
        values = list_spaces,
    }), vars.helpers.info.schema)

    space_info_query()
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

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    vars.helpers.info.schema = opts.schema
    vars.helpers.info.prefix = opts.prefix or DEFAULT_PREFIX
    vars.helpers.info.enabled = true
    space_types(opts.schema)
    operations_prefixes({
        schema = vars.helpers.info.schema,
        prefix = vars.helpers.info.prefix,
    })

    vars.helpers.info.include = opts.include
    vars.helpers.info.exclude = opts.exclude
    space_info_list()
end

local function space_info_remove()
    space_info_query_remove()
    space_info_list_remove()
    vars.helpers.info.enabled = false
    space_types(vars.helpers.info.schema)
    operations_prefixes({
        schema = vars.helpers.info.schema,
        prefix = vars.helpers.info.prefix,
    })
    vars.helpers.info.schema = nil
    vars.helpers.info.prefix = nil
    vars.helpers.info.include = nil
    vars.helpers.info.exclude = nil
end

-- space_drop section
local function space_drop_mutation_remove()
    operations.remove_mutation({
        name = 'space_drop',
        schema = vars.helpers.drop.schema,
        prefix = vars.helpers.drop.prefix,
    })
end

local function space_drop_mutation()
    space_drop_mutation_remove()
    operations.add_mutation({
        schema = vars.helpers.drop.schema,
        prefix = vars.helpers.drop.prefix,
        name = 'space_drop',
        doc = 'Drop space',
        args = {
            name = types(vars.helpers.drop.schema).SpaceDropNames,
        },
        kind = types.boolean,
        callback = 'graphqlapi.spaceapi.space_drop',
    })
end

local function space_drop_list_remove()
    types.remove('SpaceDropNames', vars.helpers.drop.schema)
end

local function space_drop_list()
    local existing = cluster.get_existing_spaces()

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
        values = list_spaces,
    }), vars.helpers.drop.schema)

    space_drop_mutation()
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

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    vars.helpers.drop.schema = opts.schema
    vars.helpers.drop.prefix = opts.prefix or DEFAULT_PREFIX
    vars.helpers.drop.enabled = true
    space_types(opts.schema)
    operations_prefixes({
        schema = vars.helpers.drop.schema,
        prefix = vars.helpers.drop.prefix,
    })

    vars.helpers.drop.include = opts.include
    vars.helpers.drop.exclude = opts.exclude

    space_drop_list()
end

local function space_drop_remove()
    space_drop_mutation_remove()
    space_drop_list_remove()
    vars.helpers.drop.enabled = false
    space_types(vars.helpers.drop.schema)
    operations_prefixes({
        schema = vars.helpers.drop.schema,
        prefix = vars.helpers.drop.prefix,
    })
    vars.helpers.drop.prefix = nil
    vars.helpers.drop.schema = nil
    vars.helpers.drop.include = nil
    vars.helpers.drop.exclude = nil
end

-- space_truncate section
local function space_truncate_mutation_remove()
    operations.remove_mutation({
        name = 'space_truncate',
        schema = vars.helpers.truncate.schema,
        prefix = vars.helpers.truncate.prefix,
    })
end

local function space_truncate_mutation()
    space_truncate_mutation_remove()
    operations.add_mutation({
        schema = vars.helpers.truncate.schema,
        prefix = vars.helpers.truncate.prefix,
        name = 'space_truncate',
        doc = 'Truncate space',
        args = {
            name = types(vars.helpers.truncate.schema).SpaceTruncateNames,
        },
        kind = types(vars.helpers.truncate.schema).SpaceTruncateResult,
        callback = 'graphqlapi.spaceapi.space_truncate',
    })
end

local function space_truncate_list_remove()
    types.remove('SpaceTruncateNames', vars.helpers.truncate.schema)
end

local function space_truncate_list()
    local existing = cluster.get_existing_spaces()

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
        values = list_spaces,
    }), vars.helpers.truncate.schema)

    space_truncate_mutation()
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

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    vars.helpers.truncate.schema = opts.schema
    vars.helpers.truncate.prefix = opts.prefix or DEFAULT_PREFIX
    vars.helpers.truncate.enabled = true
    space_types(opts.schema)
    operations_prefixes({
        schema = vars.helpers.truncate.schema,
        prefix = vars.helpers.truncate.prefix,
    })

    vars.helpers.truncate.include = opts.include
    vars.helpers.truncate.exclude = opts.exclude

    space_truncate_list()
end

local function space_truncate_remove()
    space_truncate_mutation_remove()
    space_truncate_list_remove()
    vars.helpers.truncate.enabled = false
    space_types(vars.helpers.truncate.schema)
    operations_prefixes({
        schema = vars.helpers.truncate.schema,
        prefix = vars.helpers.truncate.prefix,
    })
    vars.helpers.truncate.prefix = nil
    vars.helpers.truncate.schema = nil
    vars.helpers.truncate.include = nil
    vars.helpers.truncate.exclude = nil
end

-- space_update
local function space_update_mutation_remove()
    operations.remove_mutation({
        name = 'space_update',
        schema = vars.helpers.update.schema,
        prefix = vars.helpers.update.prefix,
    })
end

local function space_update_mutation()
    space_update_mutation_remove()
    operations.add_mutation({
        schema = vars.helpers.update.schema,
        prefix = vars.helpers.update.prefix,
        name = 'space_update',
        doc = 'Update existing space',
        args = {
            format = types.list(types(vars.helpers.update.schema).SpaceFieldInput),
            id = types.int,
            name = types(vars.helpers.update.schema).SpaceUpdateNames,
            engine = types(vars.helpers.update.schema).SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types(vars.helpers.update.schema).SpaceIndexInput),
            ck_constraint = types.list(types(vars.helpers.update.schema).SpaceCkConstraintInput),
        },
        kind = types(vars.helpers.update.schema).SpaceInfo,
        callback = 'graphqlapi.spaceapi.space_update',
    })
end

local function space_update_list_remove()
    types.remove('SpaceUpdateNames', vars.helpers.update.schema)
end

local function space_update_list()
    local existing = cluster.get_existing_spaces()

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
        values = list_spaces,
    }), vars.helpers.update.schema)

    space_update_mutation()
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

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    vars.helpers.update.schema = opts.schema
    vars.helpers.update.prefix = opts.prefix or DEFAULT_PREFIX
    vars.helpers.update.enabled = true
    space_types(opts.schema)
    operations_prefixes({
        schema = vars.helpers.update.schema,
        prefix = vars.helpers.update.prefix,
    })

    vars.helpers.update.include = opts.include
    vars.helpers.update.exclude = opts.exclude

    space_update_list()
end

local function space_update_remove()
    space_update_mutation_remove()
    space_update_list_remove()
    vars.helpers.update.enabled = false
    space_types(vars.helpers.update.schema)
    operations_prefixes({
        schema = vars.helpers.update.schema,
        prefix = vars.helpers.update.prefix,
    })
    vars.helpers.update.prefix = nil
    vars.helpers.update.schema = nil
    vars.helpers.update.include = nil
    vars.helpers.update.exclude = nil
end

-- space_create section
local function space_create_init(opts)
    checks({
        schema = '?string',
        prefix = '?string',
    })

    opts = opts or {}

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    vars.helpers.create.schema = opts.schema
    vars.helpers.create.prefix = opts.prefix or DEFAULT_PREFIX
    vars.helpers.create.enabled = true
    space_types(vars.helpers.create.schema)
    operations_prefixes({
        schema = vars.helpers.create.schema,
        prefix = vars.helpers.create.prefix,
    })

    operations.add_mutation({
        schema = vars.helpers.create.schema,
        prefix = vars.helpers.create.prefix,
        name = 'space_create',
        doc = 'Create new space',
        args = {
            format = types.list(types(vars.helpers.create.schema).SpaceFieldInput),
            id = types.int,
            name = types.string,
            engine = types(vars.helpers.create.schema).SpaceEngine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            bsize = types.int,
            user = types.string,
            index = types.list(types(vars.helpers.create.schema).SpaceIndexInput),
            ck_constraint = types.list(types(vars.helpers.create.schema).SpaceCkConstraintInput)
        },
        kind = types(vars.helpers.create.schema).SpaceInfo,
        callback = 'graphqlapi.spaceapi.space_create'
    })
end

local function space_create_remove()
    operations.remove_mutation({
        name = 'space_create',
        schema = vars.helpers.create.schema,
        prefix = vars.helpers.create.prefix,
    })
    vars.helpers.create.enabled = false
    space_types(vars.helpers.create.schema)
    operations_prefixes({
        schema = vars.helpers.create.schema,
        prefix = vars.helpers.create.prefix,
    })
    vars.helpers.create.schema = nil
    vars.helpers.create.prefix = nil
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

    if opts.schema == nil or opts.schema:lower() == 'default' then
        opts.schema = '__global__'
    else
        opts.schema = opts.schema:lower()
    end

    opts.prefix = opts.prefix or DEFAULT_PREFIX

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
            include = opts.info.include,
            exclude = opts.info.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.truncate and opts.truncate.enabled == true) or not opts.truncate then
        opts.truncate = opts.truncate or {}
        space_truncate_init({
            include = opts.info.include,
            exclude = opts.info.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.update and opts.update.enabled == true) or not opts.update then
        opts.update = opts.update or {}
        space_update_init({
            include = opts.info.include,
            exclude = opts.info.exclude,
            schema = opts.schema,
            prefix = opts.prefix,
        })
    end
    if (opts.create and opts.create.enabled == true) or not opts.create then
        opts.create = opts.create or {}
        space_create_init({
            schema = opts.schema,
            prefix = opts.prefix,
        })
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
