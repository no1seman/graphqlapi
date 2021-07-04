local data_helpers = require('graphqlapi.helpers.data')
local schema_helpers = require('graphqlapi.helpers.schema')
local spaces_helpers = require('graphqlapi.helpers.spaces')

local function stop()
    data_helpers.stop()
    schema_helpers.stop()
    spaces_helpers.stop()
end

local function update()
    spaces_helpers.update_lists()
end

return {
    update = update,
    stop = stop,
}