local module = require('module')

return {
    spaces = {'model'},
    model = function()
        _G._test_model = (_G._test_model or 0) + 1
        return {}
    end,
    f = module.func
}
