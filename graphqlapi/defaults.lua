local defaults = {
    -- default models dir path
    DEFAULT_MODELS_DIR = 'models',
    -- default http endpoint
    DEFAULT_ENDPOINT = '/admin/graphql',
    -- name of default schema
    DEFAULT_SCHEMA_NAME = 'default',
    -- default net.box connection timeout
    NET_BOX_CONNECTION_TIMEOUT = 1,
    -- default channel capacity for change space messages
    CHANNEL_CAPACITY = 100,
    -- default channel timeout in seconds
    CHANNEL_TIMEOUT = 10,
    -- default name prefix for prefixed queries
    QUERY_PREFIX = 'api_',
    -- default name prefix for prefixed mutations
    MUTATION_PREFIX = 'mutation_api_',
    -- remove_recursive_max_depth
    REMOVE_RECURSIVE_MAX_DEPTH = 128,
}

return setmetatable({}, {
    __index = defaults,
    __newindex = function(_, key, value)
        if key == 'REMOVE_RECURSIVE_MAX_DEPTH' and value < 2 then
            defaults.REMOVE_RECURSIVE_MAX_DEPTH = 2
        else
            defaults[key] = value
        end
    end
})