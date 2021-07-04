local checks = require('checks')
local errors = require('errors')
local log = require('log')

-- local json = require('json')

-- local json_cfg = {
--     encode_use_tostring = true,
--     encode_deep_as_nil = true,
--     encode_max_depth = 3,
--     encode_invalid_as_nil = true,
-- }

local types = table.copy(require('graphql.types'))

local cluster = require('graphqlapi.cluster')
local defaults = require('graphqlapi.defaults')
local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.types')

vars:new('space_type', {})
vars:new('schema_invalid', {})

local e_graphqlapi = errors.new_class('GraphQL API error', { capture_stack = false })

types.double = types.scalar({
    name = 'Double',
    serialize = tonumber,
    parseValue = tonumber,
    parseLiteral = function(node)
      -- 'float' and 'int' are names of immediate value types
      if node.kind == 'float' or node.kind == 'int' then
        return tonumber(node.value)
      end
    end,
    isValueOfTheType = function(value)
      return type(value) == 'number'
    end,
})

-- function types.map(config)
--     local instance = {
--       __type = 'Scalar',
--       name = config.name,
--       description = 'Map is a dictionary with string keys and values of ' ..
--         'arbitrary but same among all values type',
--       serialize = function(value) return value end,
--       parseValue = function(value) return value end,
--       parseLiteral = function(_)
--         error('Literal parsing is implemented in util.coerceValue; ' ..
--           'we should not go here')
--       end,
--       values = config.values,
--     }

--     instance.nonNull = types.nonNull(instance)

--     return instance
-- end

types.mapper = {
    ['unsigned'] = types.long, -- OK
    ['integer'] = types.int, -- OK
    ['number'] = types.float, -- OK
    ['string'] = types.string, --OK
    ['scalar'] = types.scalar, -- ???
    ['boolean'] = types.boolean, -- OK
    ['varbinary'] = types.bare, -- ???
    ['array'] = types.list, -- OK
    ['map'] = types.bare, -- ???
    ['any'] = types.scalar, -- ???
    ['decimal'] = types.long, -- OK
    ['double'] = types.double, -- OK
    ['uuid'] = types.id, -- OK
}

local function space_fields(space)
    local schema = cluster.get_schema()

    if not schema.spaces[space] then return nil end
    local fields = {}
    for _, field in ipairs(schema.spaces[space].format) do
        if field.comment ~= nil and field.comment ~= '' then
            if field.is_nullable then
                fields[field.name] = {
                    kind = types.mapper[field.type],
                    description = field.comment,
                }
            else
                fields[field.name] = {
                    kind = types.mapper[field.type].nonNull,
                    description = field.comment,
                }
            end
        else
            if field.is_nullable then
                fields[field.name] = types.mapper[field.type]
            else
                fields[field.name] = types.mapper[field.type].nonNull
            end
        end
    end
    return fields
end

types.add = function(_type, schema_name)
    checks('table', '?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    types.get_env(schema_name)[_type.name] = _type

    vars.schema_invalid[schema_name] = true
end

types.is_invalid = function(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    return vars.schema_invalid[schema_name]
end

types.reset_invalid = function(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    vars.schema_invalid[schema_name] = false
end

types.remove = function (type_name, schema_name)
    checks('string', '?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end
    types(schema_name)[type_name] = nil
    vars.schema_invalid[schema_name] = true
    return type_name
end

types.remove_recursive = function (type_name)
    checks('string')
    log.debug('Removing type: %s', type_name)

    local ok, err = types.remove(type_name)
    if not ok then
        return ok, err
    end
    -- TODO: remove callbacks, mutations and other types that is used by removed type

end

types.remove_types_by_space_name = function(space_name)
    local type_list = vars.space_type[space_name]
    if type_list and type(type_list) == 'table' then
        for _, type_name in pairs(type_list) do
            types.remove(type_name)
        end
        vars.space_type[space_name] = nil
    end
end

types.remove_all = function()
    for _, schema in pairs(types.schemas()) do
        for type_name in pairs(types(schema)) do
            types.remove(type_name, schema)
        end
    end
    vars.space_type = nil
    vars.schema_invalid = {}
end

types.add_space_object = function(opts)
    checks({
        schema = '?string',
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    if not cluster.is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local new_type = types.object({
        schema = opts.schema,
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add(new_type, opts.schema)
    vars.space_type[opts.space] = utils.merge_arrays(vars.space_type[opts.space] or {}, {opts.name})
    return types(opts.schema)[opts.name]
end

types.add_space_input_object = function(opts)
    checks({
        schema = '?string',
        name = 'string',
        description = '?string',
        space = 'string',
        fields = '?table',
    })

    if opts.schema == nil then
        opts.schema = defaults.DEFAULT_SCHEMA_NAME
    else
        opts.schema = opts.schema:lower()
    end

    if not cluster.is_space_exists(opts.space) then
        return nil, nil, e_graphqlapi:new(string.format("space '%s' doesn't exists", opts.space))
    end

    local new_type = types.inputObject({
        schema = opts.schema,
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space)
    })
    types.add(new_type, opts.schema)
    vars.space_type[opts.space] = utils.merge_arrays(vars.space_type[opts.space] or {}, {opts.name})
    return types(opts.schema)[opts.name]
end

types.list_types = function(schema_name)
    checks('?string')

    if schema_name == nil then
        schema_name = defaults.DEFAULT_SCHEMA_NAME
    else
        schema_name = schema_name:lower()
    end

    local type_list = {}
    for _type in pairs(types(schema_name)) do
        table.insert(type_list, _type)
    end
    return type_list
end

types.schemas = function()
    local schemas = {}
    for schema_name in pairs(vars.schema_invalid) do
        table.insert(schemas, schema_name)
    end
    return schemas
end

-- types.print = function(type_name, filename)
--     require('cartridge.utils').file_write(filename, require('json').encode(types[type_name], {
--         encode_use_tostring = true,
--         encode_deep_as_nil = true,
--         encode_max_depth = 5,
--         encode_invalid_as_nil = true,
--     }))
-- end

return setmetatable(types, {
    __call = function(_, schema_name)
        if schema_name == nil then
            schema_name = defaults.DEFAULT_SCHEMA_NAME
        else
            schema_name = schema_name:lower()
        end
        return types.get_env(schema_name)
    end
})
