local helpers = require('graphqlapi.helpers.spaces')

local function model()
    helpers.init()
end

return {
    model = model,
}
