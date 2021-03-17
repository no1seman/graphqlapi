local cartridge = require('cartridge')
local graphqlapi = require('graphqlapi')
local auth = require('cartridge.auth')

local function init()
    local endpoint = '/admin/graphql'
    local httpd = cartridge.service_get('httpd')
    graphqlapi.init(httpd, auth, endpoint)
end

local function stop()
    graphqlapi.stop()
end

return setmetatable({
    role_name = 'graphqlapi',
    init = init,
    stop = stop,
}, { __index = graphqlapi })
