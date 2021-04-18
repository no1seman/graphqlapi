local checks = require('checks')
local errors = require('errors')
local ddl = require('ddl')
local log = require('log')

local types = require('graphql.types')

local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.types')

vars:new('type_space', {})
vars:new('schema_invalid', nil)

local e_graphqlapi = errors.new_class('GraphQL API error', { capture_stack = false })

local internal_types = {
    add = true,
    add_space_input_object = true,
    add_space_object = true,
    bare = true,
    boolean = true,
    directive = true,
    enum = true,
    float = true,
    get_env = true,
    id = true,
    include = true,
    inputObject = true,
    int = true,
    interface = true,
    is_invalid = true,
    list = true,
    list_types = true,
    long = true,
    mapper = true,
    nonNull = true,
    nullable = true,
    object = true,
    remove = true,
    remove_all = true,
    remove_by_space_name = true,
    remove_recursive = true,
    reset_invalid = true,
    resolve = true,
    scalar = true,
    skip = true,
    string = true,
    union = true,
}

types.mapper = {
    ['unsigned'] = types.long, -- OK
    ['integer'] = types.int, -- OK
    ['number'] = types.float, -- OK
    ['string'] = types.string, --OK
    ['scalar'] = types.scalar, -- ???
    ['boolean'] = types.boolean, -- OK
    ['varbinary'] = types.bare, -- ???
    ['array'] = types.bare, -- ???
    ['map'] = types.bare, -- ???
    ['any'] = types.scalar, -- ???
    ['decimal'] = types.float, -- ???
    ['double'] = types.float, -- OK
    ['uuid'] = types.id, -- OK
}

local function is_space_exists(space)
    local ddl_schema = ddl.get_schema()
    return ddl_schema.spaces[space] or false
end

local function space_fields(space)
    local ddl_schema = ddl.get_schema()

    if not ddl_schema.spaces[space] then return nil end
    local fields = {}
    for _, field in ipairs(ddl_schema.spaces[space].format) do
        if field.is_nullable then
            fields[field.name] = types.mapper[field.type]
        else
            fields[field.name] = types.mapper[field.type].nonNull
        end
    end
    return fields
end

types.add = function(_type, type_name)
    checks('table', '?string')
    if type_name and type_name ~='' then
        types[type_name] = _type
    else
        types[_type.name] = _type
    end
    vars.schema_invalid = true
end

types.is_invalid = function()
    return vars.schema_invalid
end

types.reset_invalid = function()
    vars.schema_invalid = false
end

types.remove = function (type_name)
    checks('string')

    if not internal_types[type_name] then
        types[type_name] = nil
        vars.schema_invalid = true
        return type_name
    else
        return nil, e_graphqlapi:new("can't remove internal type")
    end
end

types.remove_recursive = function (type_name)
    checks('string')
    log.debug('Removing type: %s', type_name)

    if not internal_types[type_name] then
        -- TODO: remove callbacks, mutations and other types that is used by removed type
        types[type_name] = nil
        vars.type_space[type_name] = nil
        vars.schema_invalid = true
        return type_name
    else
        return nil, e_graphqlapi:new("can't remove internal type")
    end
end

types.remove_by_space_name = function(space_name)
    for type_name, space in pairs(vars.type_space) do
        if space == space_name then
            types.remove(type_name)
            vars.type_space[type_name] = nil
            vars.schema_invalid = true
        end
    end
end

types.remove_all = function()
    for _type in pairs(types) do
        if not internal_types[_type] then
            types[_type] = nil
        end
    end
    vars.type_space = nil
end

types.add_space_object = function(opts)
    checks({
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table',
    })

    if not is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local new_type = types.object({
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add(new_type, opts.name)
    vars.type_space[opts.name] = opts.space
    return opts.name, new_type
end

types.add_space_input_object = function(opts)
    checks({
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table',
    })

    if not is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local new_type = types.inputObject({
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add(new_type, opts.name)
    vars.type_space[opts.name] = opts.space
    return opts.name, new_type
end

types.list_types = function()
    local type_list = {}
    for _type in pairs(types) do
        table.insert(type_list, _type)
    end
    return type_list
end

-- types.print = function(type_name, filename)
--     require('cartridge.utils').file_write(filename, require('json').encode(types[type_name], {
--         encode_use_tostring = true,
--         encode_deep_as_nil = true,
--         encode_max_depth = 5,
--         encode_invalid_as_nil = true,
--     }))
-- end

return types
