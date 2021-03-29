local helpers = require('graphqlapi.helpers')

local function model()
    helpers.init()
end

return {
    model = model,
}