#!/usr/bin/env tarantool

require('strict').on()

local log = require('log')
local errors = require('errors')
local cartridge = require('cartridge')

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, {
    roles = {
        'cartridge.roles.vshard-storage',
        'cartridge.roles.vshard-router',
        'cartridge.roles.graphqlapi',
        'test.entrypoint.app.roles.api',
        'test.entrypoint.app.roles.storage',
    },
})
if not ok then
    log.error('%s', err)
    os.exit(1)
end
