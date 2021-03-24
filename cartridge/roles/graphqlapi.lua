local cartridge = require('cartridge')
local graphqlapi = require('graphqlapi')
local auth = require('cartridge.auth')

local function init()
    local httpd = cartridge.service_get('httpd')
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
