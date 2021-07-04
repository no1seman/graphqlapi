local checks = require('checks')
local errors = require('errors')
local log = require('log')

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

    for space in pairs(vars.space_type) do
        local space_types = table.copy(vars.space_type[space])
        for index, _type in pairs(space_types) do
            if _type.schema == schema_name and _type.name == type_name then
                table.remove(vars.space_type[space], index)
            end
        end
    end

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

types.get_non_leaf_types = function(t, type_list)
    type_list = type_list or {}
    if t.__type == 'NonNull' then
        types.get_non_leaf_types(t.ofType, type_list)
    elseif t.__type == 'List' then
        types.get_non_leaf_types(t.ofType, type_list)
    elseif t.__type == 'Enum' then
        table.insert(type_list, t.name)
    elseif t.__type == 'Object' then
        table.insert(type_list, t.name)
        for _,v in pairs(t.fields) do
            types.get_non_leaf_types(v.kind, type_list)
            types.get_non_leaf_types(v.arguments, type_list)
        end
    elseif t.__type == 'InputObject' then
        table.insert(type_list, t.name)
        for _,v in pairs(t.fields) do
            types.get_non_leaf_types(v.kind, type_list)
            types.get_non_leaf_types(v.arguments, type_list)
        end
    elseif t.__type == 'Interface' then
        table.insert(type_list, t.name)
        for _,v in pairs(t.fields) do
            types.get_non_leaf_types(v.kind, type_list)
            types.get_non_leaf_types(v.arguments, type_list)
        end
    elseif t.__type == 'Union' then
        table.insert(type_list, t.name)
        for _,v in pairs(t.types) do
            types.get_non_leaf_types(v, type_list)
        end
    end
    return type_list
end

types.remove_types_by_space_name = function(space_name)
    checks('string')

    if vars.space_type[space_name] ~= nil then
        for _, _type in pairs(vars.space_type[space_name]) do
            if _type.schema == nil then
                _type.schema = defaults.DEFAULT_SCHEMA_NAME
            else
                _type.schema = _type.schema:lower()
            end

            types(_type.schema)[_type.name] = nil
            vars.schema_invalid[_type.schema] = true
        end
        vars.space_type[space_name] = nil
    end
end

types.remove_all = function(opts)
    checks({
        schema = '?string',
    })

    if opts ~= nil then
        if opts.schema == nil then
            opts.schema = defaults.DEFAULT_SCHEMA_NAME
        else
            opts.schema = opts.schema:lower()
        end

        for type_name in pairs(types(opts.schema)) do
            types.remove(type_name, opts.schema)
        end

        for space in pairs(vars.space_type) do
            local space_types = table.copy(vars.space_type[space])
            for index, _type in pairs(space_types) do
                if _type.schema == opts.schema then
                    table.remove(vars.space_type[space], index)
                end
            end
        end

        vars.schema_invalid[opts.schema] = nil
    else
        for _, schema in pairs(types.schemas()) do
            for type_name in pairs(types(schema)) do
                types.remove(type_name, schema)
            end
        end
        vars.space_type = nil
        vars.schema_invalid = nil
    end
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

    types.add(types.object({
        schema = opts.schema,
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space),
    }), opts.schema)

    vars.space_type[opts.space] = utils.merge_arrays(
        vars.space_type[opts.space] or {},
        {
            {
                name = opts.name,
                schema = opts.schema,
            }
        }
    )
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

    types.add(types.inputObject({
        schema = opts.schema,
        name = opts.name,
        description = opts.description,
        fields = opts.fields and utils.merge_maps(space_fields(opts.space), opts.fields) or space_fields(opts.space),
    }), opts.schema)

    vars.space_type[opts.space] = utils.merge_arrays(
        vars.space_type[opts.space] or {},
        {
            {
                name = opts.name,
                schema = opts.schema,
            }
        }
    )
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
