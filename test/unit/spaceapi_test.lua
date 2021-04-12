local t = require('luatest')
local g = t.group('spaceapi')
local ddl = require('ddl')

require('test.helper.unit')
local spaceapi = require('graphqlapi.spaceapi')

local function create_space(space_name)
    return box.schema.space.create(space_name, { if_not_exists = true })
end

g.test_list_spaces = function()
    local schema = ddl.get_schema()
    local spaces = spaceapi.list_spaces(schema)
    t.assert_items_equals(spaces, {})

    local myspace = create_space('myspace')

    schema = ddl.get_schema()
    spaces = spaceapi.list_spaces(schema)
    t.assert_items_equals(spaces, {'myspace'})
    myspace:drop()
end
