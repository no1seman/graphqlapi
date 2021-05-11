local t = require('luatest')

local fio = require('fio')
local shared = require('test.helper')

local helper = {shared = shared}

helper.shared.datadir = fio.pathjoin(helper.shared.root, 'tmp', 'unit_test')

helper.create_space = function()
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }

    local space = box.space['entity']
    if space == nil and not box.cfg.read_only then
        space = box.schema.space.create('entity', { if_not_exists = true })
        space:format(format)
        return space
    end
end

t.before_suite(function()
    box.cfg({work_dir = shared.datadir})
end)

t.after_suite(function()
    fio.rmtree(shared.datadir)
end)

return helper
