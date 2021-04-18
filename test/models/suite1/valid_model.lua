local module = require('module')

return {
    spaces = {'model'},
    model = function() return {} end,
    f = module.func
}
