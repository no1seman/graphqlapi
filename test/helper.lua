-- This file is required automatically by luatest.
-- Add common configuration here.

local fio = require('fio')
local t = require('luatest')
local cartridge_helpers = require('cartridge.test-helpers')

local helper = table.copy(cartridge_helpers)

helper.root = fio.dirname(debug.sourcedir())
local tmpdir = fio.pathjoin(helper.root, 'tmp')
helper.datadir = fio.pathjoin(tmpdir, 'db_test')
helper.server_command = fio.pathjoin(helper.root, 'entrypoint', 'basic_srv.lua')

t.before_suite(function()
    fio.rmtree(helper.datadir)
    fio.mktree(helper.datadir)
end)

return helper
