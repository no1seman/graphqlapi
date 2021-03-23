local helpers = require('graphqlapi.helpers')
local spaceapi = require('graphqlapi.spaceapi')

local function model()
    helpers.space_query_types_init()
    helpers.space_query_init()
end

return {
    spaces = spaceapi.list_spaces(),
    model = model,
}