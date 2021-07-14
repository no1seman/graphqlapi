local cartridge = require('cartridge')
local hotreload = require('cartridge.hotreload')
local graphqlapi = require('graphqlapi')
local auth = require('cartridge.auth')

local function init()
    local httpd = cartridge.service_get('httpd')
    hotreload.whitelist_globals({
        '__GRAPHQLAPI_ENDPOINT',
        '__GRAPHQLAPI_MODELS_DIR',
    })
    graphqlapi.init(httpd, auth)
end

local function stop()
    graphqlapi.stop()
end

return setmetatable({
    role_name = 'graphqlapi',
    init = init,
    stop = stop,
    reloadable = true,
}, { __index = graphqlapi })
