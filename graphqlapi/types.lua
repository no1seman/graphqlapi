local checks = require('checks')
local errors = require('errors')
local ddl = require('ddl')
local log = require('log')

local types = require('graphql.types')

local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.types')

vars:new('type_space', {})
vars:new('invalid', nil)

local e_remove_type = errors.new_class('GraphQL type remove failed', { capture_stack = false })
local e_object_add = errors.new_class('Add GraphQL object failed', { capture_stack = false })
local e_inputObject_add = errors.new_class('Add GraphQL input object failed', { capture_stack = false })

local internal_types = {
    add_inputObject = true,
    add_object = true,
    add_type = true,
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
    long = true,
    nonNull = true,
    nullable = true,
    object = true,
    remove_all = true,
    remove_type = true,
    remove_type_by_space_name = true,
    resolve = true,
    scalar = true,
    set_valid = true,
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

types.is_invalid = function()
    return not vars.invalid
end

types.set_valid = function()
    vars.invalid = false
end

types.add_type = function(type_name, _type)
    checks('string', 'table')
    types[type_name] = _type
end

types.remove_type = function (type_name)
    checks('string')
    log.debug('Removing type: %s', type_name)

    if not internal_types[type_name] then
        -- TODO: remove callbacks, mutations and other types that is used by removed type
        types[type_name] = nil
        vars.type_space[type_name] = nil
        vars.invalid = true
        return type_name
    else
        return nil, e_remove_type:new("Can't remove internal type")
    end
end

types.remove_type_by_space_name = function(space_name)
    for type_name, space in pairs(vars.type_space) do
        if space == space_name then
            types[type_name] = nil
            vars.type_space[type_name] = nil
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

types.add_object = function(opts)
    checks({
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table'
    })

    if not is_space_exists(opts.space) then
        return nil, e_object_add:new(string.format("Space \"%s\"doesn't exists", opts.space))
    end

    local new_type = types.object({
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add_type(opts.name, new_type)
    vars.type_space[opts.name] = opts.space
    return opts.name, new_type
end

types.add_inputObject = function(opts)
    checks({
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table'
    })

    if not is_space_exists(opts.space) then
        return nil, e_inputObject_add:new(string.format("Space \"%s\"doesn't exists", opts.space))
    end

    local new_type = types.inputObject({
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add_type(opts.name, new_type)
    vars.type_space[opts.name] = opts.space
    return opts.name, new_type
end

return types
