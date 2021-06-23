local utils = require('cartridge.utils')

local log = require('log')
local json = require('json')

local json_cfg = {
    encode_use_tostring = true,
    encode_deep_as_nil = true,
    encode_max_depth = 10,
    encode_invalid_as_nil = true,
}

local function getTypeName(t, typename)
    if t then
        if t.__type == 'Scalar' then
            log.info('Type: "%s",  name: "%s"', t.__type, t.name)
            return true
        elseif t.__type == 'NonNull' then
            log.info('NonNull')
            return getTypeName(t.ofType, typename)
        elseif t.__type == 'List' then
            log.info('List')
            return getTypeName(t.ofType, typename)
        elseif t.__type == 'Object' then
            log.info('Object name: "%s"', t.name)
            --return getTypeName(t.ofType, typename)
            if not t.fields then
                return getTypeName(t.ofType, typename)
            else
                for _,v in pairs(t.fields) do
                    log.info('Field name: "%s"', v.name)
                    getTypeName(v.kind, typename)
                    getTypeName(v.arguments, typename)
                end
                return true
            end
        end
    else
        --log.info('Type name: %s', t.name)
        -- if t.name == typename then
        return true
        -- end
        --return getTypeName(t.ofType, typename)

    end
    log.info('Found nothing')
    return false
    -- local err = ('Internal error: unknown type:\n%s'):format(require('yaml').encode(t))
    -- error(err)
end

local function print_types(types)
    utils.file_write('./types.json', json.encode(types, json_cfg))
    log.info('Get ALL types:')
    getTypeName(types['cd_offer_cc'])
    -- log.info('Begin reload():')
    -- log.info('Global schema: '..json.encode(types.get_env(), {
    --     encode_use_tostring = true,
    --     encode_deep_as_nil = true,
    --     encode_max_depth = 3,
    --     encode_invalid_as_nil = true,
    -- }))
    -- log.info('Types: ' .. json.encode(types.list_types()))
    -- log.info('Mutations: ' .. json.encode(operations.list_mutations()))
    -- log.info('Queries: ' ..json.encode(operations.list_queries()))
    -- log.info('Models: '..json.encode(models.list_models()))
    -- log.info('Loaded: '..json.encode(models.list_loaded()))
    -- log.info('Modules: '..json.encode(models.list_modules()))
end

return {
    print_types = print_types,
}
